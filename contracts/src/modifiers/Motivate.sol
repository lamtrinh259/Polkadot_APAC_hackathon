// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { MINIMUM_WAGER } from "../lib/Constants.sol";
// import { Errors } from "../lib/Errors.sol";

abstract contract Modifiers {
    /// @notice error thrown if challenge has not started
    error ChallengeNotStarted();

    /// @notice error thrown when the challenge has expired
    error ChallengeExpired();

    /// @notice error thrown when insufficient wager is proposed
    error InsufficientWager();

    modifier amountMustExceedMinWager(uint256 amount) {
        if (amount < MINIMUM_WAGER) {
            revert InsufficientWager();
        } else {
            _;
        }
    }

    modifier dateMustExceedNow(uint256 startDate) {
        if (startDate < block.timestamp) {
            revert ChallengeExpired();
        }
        _;
    }

    modifier challengeMustHaveStarted(uint256 startDate) {
        if (startDate > block.timestamp) {
            revert ChallengeNotStarted();
        }
        _;
    }

    modifier onlyChallengeInitiator(address user) {
        require(
            msg.sender == user,
            "Unauthorized: Only challenge initiator or owner can call this function"
        );
        _;
    }
}
