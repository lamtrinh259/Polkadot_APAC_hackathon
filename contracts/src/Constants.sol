// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

uint40 constant CHALLENGE_DURATION = 21 days;
uint40 constant CHALLENGE_CHECKIN_RATE = 1 days;
uint256 constant MINIMUM_WAGER = 5_000_000;

address constant MOONBEAM_USDC_ADDR = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;

// Mock temporary treasury EVM address below, will be replaced with real treasury address after deployed
address constant TREASURY_ADDR = 0xBa40994Ef006b66a7252621554791DbE957b69b4;
