// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PiggyBankFactory, PiggyBankOneToOne, PiggyBankShares, AggregatorV3Interface, PiggyBank} from "../src/PIG.sol";
import {DeployPig} from "../script/deployPIG.s.sol";
import {console} from "forge-std/console.sol";