// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 2000 * 1e8; // 2000 USD

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            // Sepolia
            activeNetworkConfig = getSepoliaPriceFeed();
        } else if (block.chainid == 31337) {
            // Anvil
            activeNetworkConfig = getOrCreateAnvilPriceFeed();
        } else if (block.chainid == 1) {
            // Mainnet
            activeNetworkConfig = getMainnetPriceFeed();
        } else {
            revert("Unsupported network");
        }
    }

    function getSepoliaPriceFeed()
        internal
        pure
        returns (NetworkConfig memory)
    {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilPriceFeed()
        internal
        returns (NetworkConfig memory)
    {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        // Deploy a mock price feed
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockV3Aggregator)
        });
        return anvilConfig;
    }

    function getMainnetPriceFeed()
        internal
        pure
        returns (NetworkConfig memory)
    {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }
}
