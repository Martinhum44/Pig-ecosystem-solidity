// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract ERC20 is IERC20{
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    
    string i_name;
    string i_symb; 
    uint public totalsupply;

    constructor(string memory _name, string memory _symbol){
        i_name = _name;
        i_symb = _symbol;
    }

    function name() external view returns(string memory){
        return i_name;
    }

    function symbol() external view returns(string memory){
        return i_symb;
    }


    function decimals() public pure virtual returns(uint8){
        return 18;
    }

    function totalSupply() external view returns(uint){
        return totalsupply;
    }

    function transfer(address recipient, uint amount) external virtual returns(bool){
        balances[recipient] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender,recipient,amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool){
        allowances[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool){
        require(allowance(sender, msg.sender) >= amount, "allowance less than amount");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender,recipient,amount);
        return true;
    }

    function balanceOf(address account) public view returns(uint){
        return balances[account];
    }
}

contract PiggyBankShares is ERC20{
    uint8 public sharesToSell = 80; 
    uint8 constant TOTAL_SHARES = 100;
    address payable owner;
    address[] public shareHolders;
    uint count;

    struct Transfers {
        address from;
        address to;
        uint value;
        bool approved;
        uint votes;
    }

    mapping(uint => Transfers) public transfers;
    mapping(address => mapping(uint => bool)) voted;

    constructor(address to) ERC20("Piggy Bank Shares", "PBS"){
        balances[to] = 20;
        owner = payable(to);
    }

    function decimals() public pure override returns(uint8){
        return 1;
    }

    function invest() external payable {
        require(sharesToSell > 0, "No more shares can be bought.");
        require(msg.value >= 0.01e15, "You can't even buy 1 share!");
        require(msg.value <= 0.01e15*uint(sharesToSell), "You can't buy that amount of shares. (They ran out)");
        balances[msg.sender] += uint8(msg.value/0.01e15);
        shareHolders.push(msg.sender);
        sharesToSell -= uint8(msg.value/0.01e15);
    } 

    function recolectShareSales() external {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function returnShareHolders() external view returns(address[] memory){
        return shareHolders;
    }

    function transfer(address recipient, uint amount) external override returns(bool){
        transfers[count] = Transfers(msg.sender, recipient, amount, false, 0);
        count++;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
        transfers[count] = Transfers(sender, recipient, amount, false, 0);
        count++;
        return true;
    }
 
    function voteForTransfer(uint transaction) external {
        Transfers storage trans = transfers[transaction];
        require(!voted[msg.sender][transaction], "already voted");
        require(!trans.approved, "transaction already sent");
        trans.votes += balanceOf(msg.sender);
        voted[msg.sender][transaction] = true;
        if(trans.votes >= 70){
            balances[trans.from] -= trans.value;
            balances[trans.to] += trans.value;
            trans.approved = true;
        }
    }
}

contract PiggyBankOneToOne is ERC20{
    PiggyBankShares public immutable shareProvider;
    uint public feesCollected;
    address public immutable owner;

    constructor(address _owner) ERC20("PiggyBankOneToOne", "PIGGY1T1") { 
        shareProvider = new PiggyBankShares(_owner);
        owner = _owner;
    }

    function wrap() external payable {
        require(shareProvider.sharesToSell() == 0, "Investors must have finished investing.");
        uint fee = (msg.value/100);
        balances[msg.sender] += msg.value - fee;
        feesCollected += fee;
    }

    function unwrap(uint amount) external {
        uint fee = (amount/100);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount - fee);
        feesCollected += fee;
    }

    function distributeRewards() external {
        require(shareProvider.balanceOf(msg.sender) > 0);
        address[] memory holders = shareProvider.returnShareHolders();
        uint len = holders.length;
        for(uint i = 0; i < len; i++){
            payable(holders[i]).transfer((feesCollected/100)*shareProvider.balanceOf(holders[i]));
        }
        feesCollected = 0;
    } 
}

library USDConversions {
    function ETHToUSD(uint amountInWei, AggregatorV3Interface priceFeed) external view returns(int resultInCents){
        (,int toReturn,,,) = (priceFeed.latestRoundData());
        int tr = (toReturn*int(amountInWei))/10**18;
        resultInCents = tr/10**6;
    }
}

contract PiggyBankFactory {
    mapping(address => address[]) public piggyBanks;
    PiggyBankOneToOne public immutable token;
    address immutable public priceFeed;

    constructor(address _priceFeed) {
        token = new PiggyBankOneToOne(msg.sender);
        priceFeed = _priceFeed;
    }

    function createPiggyBank(uint goalInUSDCents, address destinationWhenGoalMet) external returns(PiggyBank){
        PiggyBank np = new PiggyBank(priceFeed, token, goalInUSDCents, destinationWhenGoalMet);
        piggyBanks[msg.sender].push(address(np));
        return np;
    }
}

contract PiggyBank {
    using USDConversions for uint;

    uint public immutable goal;
    address public immutable recipient;
    bool reached;
    PiggyBankOneToOne public immutable oneToOneToken;
    AggregatorV3Interface public immutable priceFeed;

    modifier NotGreaterThanGoal{
        require(!reached, "goal already reached");
        _;
    }

    constructor(address _priceFeed, PiggyBankOneToOne _ERC20Token, uint goalInUSDCents, address destinationWhenGoalMet){
        oneToOneToken = _ERC20Token;
        recipient = destinationWhenGoalMet;
        goal = goalInUSDCents;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getBalanceInUsd() public view returns(int){
        return oneToOneToken.balanceOf(address(this)).ETHToUSD(priceFeed);
    }

    function donate(uint amount) public NotGreaterThanGoal {
        oneToOneToken.transferFrom(msg.sender, address(this), amount);
        if(getBalanceInUsd() > int(goal)){
            oneToOneToken.transfer(recipient, oneToOneToken.balanceOf(address(this)));
            reached = true;
        }
    }

    receive() external payable NotGreaterThanGoal {
        oneToOneToken.wrap{value:msg.value}();
        if(getBalanceInUsd() > int(goal)){
            oneToOneToken.transfer(recipient, oneToOneToken.balanceOf(address(this)));
            reached = true;
        }
    }
}