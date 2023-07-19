// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct ChallengeIdentifiers {
    uint32 activityId;
    uint40 startDate;
}

struct UserChallenge {
    bool challengeAccepted; // did the user accept this challenge?
    uint256 paymentPerDay; // 1/21 of the user's wager
}

struct ChallengeInfo {
    uint40 userCount;
    uint256 balance;
    address[] winners;
}

struct Record {
    bool[21] challengeDays;
}