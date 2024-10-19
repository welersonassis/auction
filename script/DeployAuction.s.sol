// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Auction} from "../src/Auction.sol";

contract DeployAuction is Script {
    function run() public returns (Auction) {
        uint256 MINIMUM_VALUE = 10e18;
        uint256 INTERVAL = 3600;

        vm.startBroadcast();
        Auction auction = new Auction(MINIMUM_VALUE, INTERVAL);
        vm.stopBroadcast();

        return auction;
    }
}
