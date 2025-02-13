// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mox/MockV3Aggregator.sol";

contract HelperConfig is Script{
    uint8 constant DECIMALS = 8;
    int constant INITIAL_PRICE = 2000e8;
    NetworkConfig public activeNetwork;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if(block.chainid == 11155111){
            activeNetwork = getSepoliaEthConfig();
        } else if(block.chainid == 1){
            activeNetwork = getMainnetEthConfig();
        } else {
            activeNetwork = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetwork.priceFeed != address(0)){
            return activeNetwork;
        }

        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        return NetworkConfig(address(mock));
    }

    function getMainnetEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }
}
