// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

library Errors {
    /// @notice error thrown if challenge has not started
    error ChallengeNotStarted();

    /// @notice error thrown when the challenge has expired
    error ChallengeExpired();

    /// @notice error thrown when insufficient wager is proposed
    error InsufficientWager();

    /// @notice error thrown when there is a duplicate challenge.
    /// @dev duplictae challenge is a challenge with the same ID from a single User
    error DuplicateChallenger();

    /// @notice error thrown when there is an already recorded challenge for the day (timestamp)
    error AlreadyRecorded();
}