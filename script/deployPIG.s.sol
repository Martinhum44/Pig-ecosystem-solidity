// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {PiggyBankFactory} from "../src/PIG.sol";
import {HelperConfig} from "./helperConfig.s.sol";

contract DeployPig is Script {
    function run() external returns(PiggyBankFactory){
        HelperConfig hc = new HelperConfig();
        (address priceFeed) = hc.activeNetwork();
        vm.startBroadcast();
        PiggyBankFactory pigContract = new PiggyBankFactory(priceFeed);
        vm.stopBroadcast();
        return pigContract;
    } 
}