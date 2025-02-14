// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {PiggyBankFactory, PiggyBankShares, PiggyBankOneToOne} from "../src/PIG.sol";
import {DeployPig} from "../script/deployPIG.s.sol";

contract InvestInPIG is Script {
    function invest(PiggyBankShares to) public {
       to.invest{value:0.8e15}();
    }

    function run() external returns(PiggyBankShares){
        DeployPig dp = new DeployPig();
        PiggyBankFactory pbf;
        pbf = dp.run();
        PiggyBankShares pbs = PiggyBankOneToOne(pbf.i_token()).shareProvider();
        vm.startBroadcast();        
        invest(pbs);
        vm.stopBroadcast(); 
        return pbs;
    }
}