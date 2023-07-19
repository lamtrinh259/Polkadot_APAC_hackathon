// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { ChallengeIdentifiers } from "../lib/Types.sol";
import { MINIMUM_WAGER } from "../lib/Constants.sol";
import { Errors } from "../lib/Errors.sol";

abstract contract Modifiers {
    modifier amountMustExceedMinWager(uint256 amount) {
        if (amount < MINIMUM_WAGER) {
            revert Errors.InsufficientWager();
        }
        _;
    }

    modifier dateMustExceedNow(ChallengeIdentifiers calldata cids) {
        if (cids.startDate < block.timestamp) {
            revert Errors.ChallengeExpired();
        }
        _;
    }

    modifier challengeMustHaveStarted(ChallengeIdentifiers calldata cids) {
        if (cids.startDate > block.timestamp) {
            revert Errors.ChallengeNotStarted();
        }
        _;
    }
}