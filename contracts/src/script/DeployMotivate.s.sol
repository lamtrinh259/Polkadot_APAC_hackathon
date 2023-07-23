// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Motivate} from "../Core/Motivate.sol";
import { MINIMUM_WAGER, LOTTERY_DEPLOYED_CONTRACT_ADDRESS } from "../lib/Constants.sol";

contract DeployMotivate is Script {

    function setUp() public {}

    function run() public {
        vm.broadcast();
        new Motivate();
    }
}
