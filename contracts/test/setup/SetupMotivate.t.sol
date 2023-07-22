// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import { console } from "forge-std/console.sol";
import { Helpers } from "../utils/Helpers.sol";
import { Motivate } from "../../src/core/Motivate.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract SetupMotivate is Test {
    using Address for address;

    address payable[] internal users;
    Motivate internal motivate;
    Helpers internal helpers;

    address internal admin;

    function setUp() public virtual {
        helpers = new Helpers();
        users = helpers.createUsers(5);

        admin = users[0];
        vm.label(admin, "Admin");

        motivate = new Motivate();
        // console.log("SetupMotivate Run", motivate.monthEnd);
    }
}
