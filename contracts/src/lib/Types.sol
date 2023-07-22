// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct UserChallenge {
    bool challengeAccepted; // did the user accept this challenge?
    uint256 amountPaid;
    uint256 challengeID;
    uint256 startDate;
    uint256 paymentPerDay; // 1/21 of the user's wager
}

struct ChallengeInfo {
    uint256 balance;
    uint256 amountEarned;
    address[] winners;
}

struct Record {
    bool[21] challengeDays;
}
