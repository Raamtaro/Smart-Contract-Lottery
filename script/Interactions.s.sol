// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating a subscription on chain Id:", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your SubscriptionId is:", subId);
        console.log("Please update the subId in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

        (uint256 subId,) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
        //Create a subscription...
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}


contract FundSubcription is Script {

    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundScriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
    }

    function run() public {

    }
}