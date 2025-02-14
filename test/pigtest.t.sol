// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PiggyBankFactory, PiggyBankOneToOne, PiggyBankShares, AggregatorV3Interface, PiggyBank} from "../src/PIG.sol";
import {DeployPig} from "../script/deployPIG.s.sol";
import {console} from "forge-std/console.sol";

contract PiggyTest is Test{
    PiggyBankFactory piggyBankFactory;
    PiggyBankOneToOne token;
    PiggyBankShares shareProvider;
    PiggyBank piggyBank;

    address inv1 = makeAddr("inv1");
    address inv2 = makeAddr("inv2");
    address reciever = makeAddr("reciever");
    address customer = makeAddr("customer");
    DeployPig dp;
    uint constant INVESTOR_BALANCE = 0.4e15;
    uint constant CUSTOMER_BALANCE = 10 ether;

    function setUp() external {
        dp = new DeployPig();
        piggyBankFactory = dp.run();
        token = piggyBankFactory.i_token();
        shareProvider = token.shareProvider();
        vm.deal(inv1, INVESTOR_BALANCE);
        vm.deal(inv2, INVESTOR_BALANCE);
        vm.deal(customer, CUSTOMER_BALANCE);
        piggyBank = piggyBankFactory.createPiggyBank(2000, reciever);
    }

    function testOwnerIsMsgSender() external view {
        assertEq(PiggyBankOneToOne(piggyBankFactory.i_token()).owner(), msg.sender);
    }

    function testPriceFeedFunctionIsAccurate() external view {
        assertEq(AggregatorV3Interface(piggyBankFactory.i_priceFeed()).version(), 4);
    }

    function testRevertWhenNotFinishedInvesting() external {
        vm.expectRevert();
        token.wrap();
        vm.expectRevert();
        token.unwrap(0);
    }

    function testRevertWhenBuyMoreSharesThanLimit() external {
        vm.expectRevert();
        shareProvider.invest{value:0.81e15}();
    }

    function testSuccessWhenBuyLessOrEqualSharesThanLimit() external {
        shareProvider.invest{value:0.8e15}();
        assertEq(true, true);
    }

    function testSendSharesWhenApproved() external {
        shareProvider.invest{value:0.7e15}();
        shareProvider.transfer(address(1), 70);
        shareProvider.voteForTransfer(0);
        assertEq(shareProvider.balanceOf(address(1)), 70);
    }

    function testFeesDistributedCorrectly() external {
        vm.prank(inv1);
        shareProvider.invest{value:INVESTOR_BALANCE}();
        vm.prank(inv2);
        shareProvider.invest{value:INVESTOR_BALANCE}();
        vm.prank(customer);
        token.wrap{value: CUSTOMER_BALANCE}();
        vm.prank(inv1);
        token.distributeRewards();
        assertEq(inv2.balance, 0.04 ether);
    }

    function testBalanceOfRecieverHighAfterGoalReached() external {
        shareProvider.invest{value: 0.8e15}();
        (bool success,) = address(piggyBank).call{value: 1 ether}("");
        require(success);
        require(token.balanceOf(reciever) > 0.9 ether);
        assertEq(true, true);
    }

    function testTokenBalanceOfTokenContractMinusFeeEqualToTotalSupply() external {
        shareProvider.invest{value: 0.8e15}();
        for(uint i = 0; i < 10; i++){
            address addr = makeAddr(string(abi.encodePacked("wrapper", i)));
            vm.deal(addr, 1 ether);
            vm.prank(addr);
            token.wrap{value: 1 ether}();
        }
        assertEq(address(token).balance, token.totalSupply()+token.s_feesCollected());
    }
}