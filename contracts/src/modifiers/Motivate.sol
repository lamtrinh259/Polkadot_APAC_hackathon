// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { MINIMUM_WAGER } from "../lib/Constants.sol";
import { Errors } from "../lib/Errors.sol";

abstract contract Modifiers {
    modifier amountMustExceedMinWager(uint256 amount) {
        if (amount < MINIMUM_WAGER) {
            revert Errors.InsufficientWager();
        }
        _;
    }

    modifier dateMustExceedNow(uint256 startDate) {
        if (startDate < block.timestamp) {
            revert Errors.ChallengeExpired();
        }
        _;
    }

    modifier challengeMustHaveStarted(uint256 startDate) {
        if (startDate > block.timestamp) {
            revert Errors.ChallengeNotStarted();
        }
        _;
    }
}
