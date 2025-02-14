// SPDX-License-Identifier: MITs

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PiggyBankFactory, PiggyBankOneToOne, PiggyBankShares, AggregatorV3Interface, PiggyBank} from "../src/PIG.sol";
import {DeployPig} from "../script/deployPIG.s.sol";
import {console} from "forge-std/console.sol";
import {InvestInPIG} from "../script/Interactions.s.sol";

contract PigTestIntegration is Test {
    PiggyBankFactory piggyBankFactory;
    PiggyBankOneToOne token;
    PiggyBankShares shareProvider;
    PiggyBank piggyBank;

    function setUp() external {
        DeployPig dp = new DeployPig();
        piggyBankFactory = dp.run();
        token = piggyBankFactory.i_token();
        shareProvider = token.shareProvider();
    }

    function testInvestmentInteractions() external {
        InvestInPIG ip = new InvestInPIG();
        PiggyBankShares idk = ip.run();
        uint pbalance = idk.i_owner().balance;
        vm.prank(idk.i_owner());
        idk.recolectShareSales();
        uint diff = idk.i_owner().balance-pbalance;
        assertEq(diff, 0.8e15);
    }
}