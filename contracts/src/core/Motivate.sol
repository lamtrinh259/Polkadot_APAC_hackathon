// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MINIMUM_WAGER, MOONBEAM_USDC_ADDR, TREASURY_ADDR, PRIZE_POOL_ADDR } from "../lib/Constants.sol";
import { UserChallenge, ChallengeInfo, Record } from "../lib/Types.sol";
import { Errors } from "../lib/Errors.sol";
import { Modifiers } from "../modifiers/Motivate.sol";

contract Motivate is Modifiers, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public activityID;

    uint256 public monthEnd;
    address[] public eligibleParticipants;
  mapping(address => mapping(uint256 => UserChallenge)) public userChallenges;
  mapping(address => uint256) public userBalances;
  mapping(uint256 => ChallengeInfo) public challengesByID;
  mapping(address => mapping(uint256 => Record)) private activityRecords;

    constructor () {
        activityID.increment();
    }

    function start(
        uint256 startDate, 
        uint256 amount
    ) 
        external 
        dateMustExceedNow(startDate)
        amountMustExceedMinWager(amount) 
    {
        uint256 currentId = activityID.current();
        uint256 challengeID = generateChallengeIdentifier(startDate, currentId, amount);
        if (userChallenges[msg.sender][challengeID].challengeAccepted) {
            revert Errors.DuplicateChallenger();
        }

        /// @notice create the user's challenge
        UserChallenge memory userChallenge = UserChallenge({
            challengeAccepted: true,
            paymentPerDay: amount / 21,
            challengeID: challengeID,
            startDate: startDate,
            amountPaid: amount
        });

        userChallenges[msg.sender][challengeID] = userChallenge;
        userBalances[msg.sender] += amount;

        bool success = IERC20(MOONBEAM_USDC_ADDR).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer Failed!");
        activityID.increment();
    }

    function recordChallenge(
        uint256 challengeID
    ) 
        external 
    {
        UserChallenge memory userChallenge = userChallenges[msg.sender][challengeID];
        ChallengeInfo storage challenge = challengesByID[challengeID];
        if (userChallenge.startDate > block.timestamp) revert Errors.ChallengeNotStarted();
        uint256 balanceToPoolPrize = (challenge.balance * (1 ether / 2)) / 1 ether;
        uint256 paymentPerDay = userChallenge.paymentPerDay;

        uint8 day = _whichDay(userChallenge.startDate);
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

        challenge.amountEarned += balanceToPoolPrize;
        challengesByID[challengeID] = challenge;
        // keep track of the streak and how much they've earned
        /// This should update the challenge info for user and id
        // bool success = IERC20(MOONBEAM_USDC_ADDR).transferFrom(address(this), msg.sender, balanceToPoolPrize);
    }

    // function sweep(uint256 challengeId) external {
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

    /// Withdraw    

    function adminRecordFailedChallenge(address user, uint256 challengeID) external onlyOwner {
        UserChallenge memory challenge = userChallenges[user][challengeID];
        Record memory userRecord = activityRecords[user][challengeID];
        uint256 today = _whichDay(challenge.startDate);

        if (userRecord.challengeDays[today] == true) revert Errors.UserAlreadyRecordedChallenge();        
        /// Split paymentPerDay into 2. Half to treasury and half to prizePool
        IERC20(MOONBEAM_USDC_ADDR).transfer(TREASURY_ADDR, challenge.paymentPerDay * 50 / 100);
        IERC20(MOONBEAM_USDC_ADDR).transfer(PRIZE_POOL_ADDR, challenge.paymentPerDay * 50 / 100);
    }

    function setMonthEnd(uint256 stamp) external {
        require(stamp > block.timestamp, "Month end cannot be set to today.");
        monthEnd = stamp;
    }

    function generateChallengeIdentifier(uint256 startDate, uint256 activityId, uint256 amount) internal pure returns(uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                        activityId, 
                        startDate,
                        amount
                    )
                )
            );
    }

    function _whichDay(uint256 _startTimestamp) internal view returns (uint8) {
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
    bool hasFailedDay = false;

    // if all 21 bools are true, then record.bitMask should be 0x1FFFFF (2^21 - 1)
    for (uint256 i = 0; i < record.challengeDays.length; i++) {
        if (record.challengeDays[i] == false) {
            hasFailedDay = true;
        }
    }
    return hasFailedDay;
  }

  function getUserCount() internal view {
    
  }
}
