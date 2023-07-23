// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HabitumToken is ERC20 {
    constructor(
        string memory name__,
        string memory symbol__
    ) ERC20(name__, symbol__) {
        _mint(msg.sender, 100000000 ether / 100);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}