// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test } from "forge-std/Test.sol";

contract Helpers is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address payable) {
        // bytes32 to address conversion
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    function createUsers(uint256 noOfUsers) public returns (address payable[] memory) {
        address payable[] memory users = new address payable[](noOfUsers);
        for (uint256 i = 0; i < noOfUsers; i++) {
            address payable user = this.getNextUserAddress();
            vm.deal(user, 100 ether);
            users[i] = user;
        }

        return users;
    }

    function createNamedUser(string memory userName) public returns (address payable) {
        address payable user = this.getNextUserAddress();
        vm.deal(user, 100 ether);
        vm.label(user, userName);

        return user;
    }
}
