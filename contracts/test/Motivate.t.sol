// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import { Test } from "forge-std/Test.sol";

import { console } from "forge-std/console.sol";
import { SetupMotivate } from "./setup/SetupMotivate.t.sol";

contract Motivate is SetupMotivate {
    function setUp() public virtual override  {
        SetupMotivate.setUp();
        console.log("Test contract is setup: Motivate");
    }

    function testInitialize() public {
        // console.log("Initialize tests here, {}", motivate);
        assertEq(Motivate(motivate.monthEnd), uint256(1), "ok");
    }

    // function testFoo(uint256 x) public {
    //     vm.assume(x < type(uint128).max);
    //     assertEq(x + x, x * 2);
    // }
}
