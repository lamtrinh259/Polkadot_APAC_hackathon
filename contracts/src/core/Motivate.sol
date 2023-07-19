// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MINIMUM_WAGER, MOONBEAM_USDC_ADDR, TREASURY_ADDR } from "../lib/Constants.sol";
import { ChallengeIdentifiers, UserChallenge, ChallengeInfo, Record } from "../lib/Types.sol";
import { Errors } from "../lib/Errors.sol";
import { Modifiers } from "../modifiers/Motivate.sol";

contract Motivate is Modifiers {
    uint256 monthEnd;
    address[] public eligibleParticipants;
  mapping(address => mapping(uint256 => UserChallenge)) public userChallenges;
  mapping(address => uint256) public userBalances;
  mapping(uint256 => ChallengeInfo) public challengesByID;
  mapping(address => mapping(uint256 => Record)) private activityRecords;

    function start(
        ChallengeIdentifiers calldata cids, 
        uint256 amount
    ) 
        external 
        dateMustExceedNow(cids)
        amountMustExceedMinWager(amount) 
    {
        uint256 challengeID = generateChanllengeIdentifier(cids);
        if (userChallenges[msg.sender][challengeID].challengeAccepted) {
            revert Errors.DuplicateChallenger();
        }

        UserChallenge memory userChallenge;
        userChallenge.challengeAccepted = true;
        userChallenge.paymentPerDay = amount / 21;

        userChallenges[msg.sender][challengeID] = userChallenge;
        userBalances[msg.sender] += amount;

        bool success = IERC20(MOONBEAM_USDC_ADDR).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer Failed!");
    }

    function recordChallenge(
        ChallengeIdentifiers calldata cids
    ) 
        external 
        challengeMustHaveStarted(cids)
        dateMustExceedNow(cids) 
    {
        uint256 challengeID = generateChanllengeIdentifier(cids);
        ChallengeInfo storage challenge = challengesByID[challengeID];
        uint256 balanceToPoolPrize = (challenge.balance * (1 ether / 2)) / 1 ether;
        uint256 paymentPerDay = userChallenges[msg.sender][challengeID].paymentPerDay;

        uint8 day = _whichDay(cids.startDate);
        bool recordSet = setRecord(msg.sender, challengeID, day);

        if (recordSet) {
            challenge.balance += paymentPerDay;
            // Update record for the current day
            activityRecords[msg.sender][challengeID].challengeDays[day] = true;
        } else {
            revert Errors.AlreadyRecorded();
        }

        if (day == 20) {
            if (allBoolsTrue(msg.sender, challengeID)) {
                challenge.winners.push(msg.sender);
                /// push into an array of eligible winners
                eligibleParticipants.push(msg.sender);
            }
        }

        challengesByID[challengeID] = challenge;
        bool success = IERC20(MOONBEAM_USDC_ADDR).transferFrom(address(this), msg.sender, balanceToPoolPrize);
    }

    // function sweep(ChallengeId calldata challenge) external {
    //     if ((challenge.startDate + 21 days) > block.timestamp) {
    //         revert ChallengeOngoing();
    //     }

    //     for (uint i=0; i < counter; i++) {
    //         currentValue = addressToValue[countToAddress[i]];
    //     } 

    //     uint256 challengeId = getCID(challenge);

    //     uint256 challengeBalance = challengeBalances[challengeId];
    //     uint256 balanceToTreasury = (challengeBalance * 0.95 ether) / 1 ether;
    //     SafeTransferLib.safeTransfer(MOONBEAM_USDC_ADDR, TREASURY_ADDR, balanceToTreasury);
    // }

    function setMonthEnd(uint256 stamp) external {
        monthEnd = stamp;
    }

    function generateChanllengeIdentifier(ChallengeIdentifiers calldata challenge) internal view returns(uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    challenge.activityId, 
                    challenge.startDate
                    )
                )
            );
    }

    function _whichDay(uint40 _startTimestamp) internal returns (uint8) {
        uint256 day = (block.timestamp % _startTimestamp) / 1 days;
        return uint8(day);
    }

    function setRecord(address _user, uint256 _challengeId, uint8 _n) internal returns (bool) {
        require(_n < 21, "Index out of bounds"); // ensure n is within 0 to 20

        Record storage userRecord = activityRecords[_user][_challengeId];
        if (userRecord.challengeDays[_n] == false) {
            userRecord.challengeDays[_n] = true;
            return true;
        } else {
            return false;
        }
    }

    /**
   * @notice function to check if all bools are true
   * @dev May need to change the implementation of this function as it's not compiling
   */
  function allBoolsTrue(address _user, uint256 _challengeId) internal view returns (bool) {
    Record storage record = activityRecords[_user][_challengeId];

    // if all 21 bools are true, then record.bitMask should be 0x1FFFFF (2^21 - 1)
    return true;
  }

  function getUserCount() internal view {
    
  }
}
