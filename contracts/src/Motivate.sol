// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { MINIMUM_WAGER, MOONBEAM_USDC_ADDR, TREASURY_ADDR } from "./Constants.sol";

contract Motivate {
  error ChallengeNotStarted();
  error ChallengeExpired();
  error InsufficientWager();
  error DuplicateChallenger();
  error ChallengeOngoing();
  error AlreadyRecorded();

  struct ChallengeId {
    uint32 activityId;
    uint40 startDate;
    uint40 duration;
  }

  // Not sure whether this struct for record is really necessary since it's just a uint256
  struct Record {
    uint256 bitMask;
  }

  struct Challenge {
    uint40 userCount;
    address[] winners;
  }

  struct UserChallenge {
    bool challengeAccepted; // did the user accept this challenge?
    uint256 paymentPerDay; // 1/21 of the user's wager
  }

  mapping(address user => mapping(uint256 challengeId => UserChallenge userChallengeInfo)) public userChallenges;
  mapping(address user => mapping(uint256 challengeId => Record activityRecord)) public activityRecords;
  mapping(address user => mapping(uint256 challengeId => uint256 userBalance)) public userBalances;
  mapping(uint256 challengeId => uint256 balance) public challengeBalances;
  mapping(uint256 challengeId => Challenge challengeInfos) public challengeInfos;

  function getCID(ChallengeId calldata challenge) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(challenge.activityId, challenge.startDate, challenge.duration)));
  }

  function _whichDay(uint40 _startTimestamp) internal returns (uint8) {
    uint256 day = (block.timestamp % _startTimestamp) / 1 days;
    return uint8(day);
  }

  /// @dev Start activity
  function start(ChallengeId calldata challengeData, uint256 amount) external {
    uint256 challengeId = getCID(challengeData);
    if (challengeData.startDate + challengeData.duration < block.timestamp) {
      revert ChallengeExpired();
    }

    if (amount < MINIMUM_WAGER) {
      revert InsufficientWager();
    }

    if (userChallenges[msg.sender][challengeId].challengeAccepted) {
      revert DuplicateChallenger();
    }

    UserChallenge memory userChallenge;
    userChallenge.challengeAccepted = true;
    userChallenge.paymentPerDay = amount / 21;

    userChallenges[msg.sender][challengeId] = userChallenge; // 1 sstore for 2 variables

    // challengeBalances[msg.sender] += amount; // Need to fix this
    userBalances[msg.sender][challengeId] += amount;

    SafeTransferLib.safeTransfer(MOONBEAM_USDC_ADDR, address(this), amount);
  }

  /**
   * @notice function to set the nth bool to true if it's not already true
   * @dev May need to change the implementation of this function as it's not compiling
   */
  function setRecord(address _user, uint256 _challengeId, uint8 _n) internal returns (bool) {
    require(_n < 21, "Index out of bounds"); // ensure n is within 0 to 20

    // Record storage record = activityRecords[_user][_challengeId];

    // only set the bit if it is not already set
    // if ((_record.bitMask & (uint256(1) << _n)) == 0) {
    //   _record.bitMask |= uint256(1) << _n;
    //   return true;
    // } else {
    //   return false;
    // }
    return true;
  }

  /**
   * @notice function to check if all bools are true
   * @dev May need to change the implementation of this function as it's not compiling
   */
  function allBoolsTrue(address _user, uint256 _challengeId) internal view returns (bool) {
    // Record storage record = activityRecords[_user][_challengeId];

    // if all 21 bools are true, then record.bitMask should be 0x1FFFFF (2^21 - 1)
    // return record.bitMask == 0x1FFFFF;
    return true;
  }

  function record(ChallengeId calldata challenge) external {
    uint256 challengeId = getCID(challenge);
    uint256 challengeBalance = challengeBalances[challengeId];
    uint256 balanceToPoolPrize = (challengeBalance * 0.5 ether) / 1 ether;

    if (challenge.startDate > block.timestamp) {
      revert ChallengeNotStarted();
    }
    if (challenge.startDate + challenge.duration < block.timestamp) {
      revert ChallengeExpired();
    }

    uint8 day = _whichDay(challenge.startDate);

    bool recordSet = setRecord(msg.sender, challengeId, day);
    if (recordSet) {
      challengeBalances[challengeId] += userChallenges[msg.sender][challengeId].paymentPerDay;
    } else {
      revert AlreadyRecorded();
    }

    // On the last day of the challenge, check if the user finished all 21 days
    if (day == 20) {
      if (allBoolsTrue(msg.sender, challengeId)) {
        challengeInfos[challengeId].winners.push(msg.sender);
      }
    }

    SafeTransferLib.safeTransferFrom(MOONBEAM_USDC_ADDR, address(this), msg.sender, balanceToPoolPrize);
  }

  function sweep(ChallengeId calldata challenge) external {
    if (challenge.startDate + challenge.duration > block.timestamp) {
      revert ChallengeOngoing();
    }

    uint256 challengeId = getCID(challenge);

    uint256 challengeBalance = challengeBalances[challengeId];
    uint256 balanceToTreasury = (challengeBalance * 0.95 ether) / 1 ether;
    SafeTransferLib.safeTransfer(MOONBEAM_USDC_ADDR, TREASURY_ADDR, balanceToTreasury);
  }

  function claim(ChallengeId calldata challenge) external {}
}

contract MockVrf {
  function requestRandomness(bytes32 _keyHash, uint256 _fee) external returns (bytes32 requestId) {}

  function fulfillRandomness(bytes32 requestId, uint256 randomness) external {}
}
