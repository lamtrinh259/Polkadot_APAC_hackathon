// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

uint40 constant CHALLENGE_DURATION = 21 days;
uint40 constant CHALLENGE_CHECKIN_RATE = 1 days;
uint256 constant MINIMUM_WAGER = 5_000_000; // 5 USDC

address constant MOONBEAM_USDC_ADDR = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;

// Mock temporary treasury EVM address below, will be replaced with real treasury address after deployed
address constant TREASURY_ADDR = 0x7B79079271A010E28b73d1F88c84C6720E2EF903;

// mock temporary prize pool address
address constant PRIZE_POOL_ADDR = 0xeD90B79f66830699E8D411Ebc5F99017B65b56B1;
