// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// import { MINIMUM_WAGER, MOONBEAM_USDC_ADDR, TREASURY_ADDR, PRIZE_POOL_ADDR } from "../lib/Constants.sol";
// import { UserChallenge, ChallengeInfo, Record } from "../lib/Types.sol";
// import { Errors } from "../lib/Errors.sol";
import { Modifiers } from "../modifiers/Motivate.sol";

contract Motivate is Modifiers, Ownable {
    /// @notice error thrown when there is a duplicate challenge.
    /// @dev duplictae challenge is a challenge with the same ID from a single User
    error DuplicateChallenger();

    /// @notice error thrown when there is an already recorded challenge for the day (timestamp)
    error AlreadyRecorded();

    /// @notice error for when admin tries to set record that user already set
    error UserAlreadyRecordedChallenge();

    struct UserChallenge {
        bool challengeAccepted; // did the user accept this challenge?
        uint256 amountPaid;
        uint256 challengeID;
        uint256 startDate;
        uint256 paymentPerDay; // 1/21 of the user's wager
        uint8 currentStreak;   // current checked-in streak of the user
        uint256 amountOwed;    // amount owed to the user after every checked-in day
    }

    struct ChallengeInfo {
        uint256 balance;
        uint256 amountEarned;
        address[] winners;
    }

    struct Record {
        bool[21] challengeDays;
    }

    uint40 private constant CHALLENGE_DURATION = 21 days;
    uint40 private constant CHALLENGE_CHECKIN_RATE = 1 days;
    uint256 private constant MINIMUM_WAGER = 5_000_000; // 5 USDC
    // Might need to deploy a mock USDC token
    address private constant MOONBEAM_USDC_ADDR = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b; // This is USDC address on Moonbeam mainnet
    // Mock temporary treasury EVM address below, will be replaced with real treasury address after deployed
    address private constant TREASURY_ADDR = 0x7B79079271A010E28b73d1F88c84C6720E2EF903;
    // mock temporary prize pool address
    address private constant PRIZE_POOL_ADDR = 0xeD90B79f66830699E8D411Ebc5F99017B65b56B1;
    address public constant DIA_ORACLE_ADDRESS = 0x48d351aB7f8646239BbadE95c3Cc6de3eF4A6cec; // on Moonbase Alpha testnet

    uint256 private activityID; // counter for activity ID
    uint256 public monthEnd; // hold the UNIX timestamp for the end of the month
    address payable[] private eligibleParticipants;
    address payable[] private winners;
    mapping(address => mapping(uint256 => UserChallenge)) public userChallenges;
    mapping(address => uint256) public userBalances;
    mapping(uint256 => ChallengeInfo) public challengesByID;
    mapping(address => mapping(uint256 => Record)) private activityRecords;

    event StartedChallenge(address indexed user, uint256 indexed challengeID, uint256 amount);

    constructor() Ownable(msg.sender) {
        activityID = 1;  // activity ID = 1 when first initiated
    }

    function startChallenge(
        uint256 startDate,
        uint256 amount
    )
        external
        dateMustExceedNow(startDate)
        amountMustExceedMinWager(amount)
    {
        uint256 currentId = activityID;
        uint256 challengeID = generateChallengeIdentifier(startDate, currentId, amount);
        if (userChallenges[msg.sender][challengeID].challengeAccepted) {
            revert DuplicateChallenger();
        }

        /// @notice create the user's challenge
        UserChallenge memory userChallenge = UserChallenge({
            challengeAccepted: true,
            paymentPerDay: amount / 21,
            challengeID: challengeID,
            startDate: startDate,
            amountPaid: amount,
            currentStreak: 0,
            amountOwed: 0
        });

        userChallenges[msg.sender][challengeID] = userChallenge;
        userBalances[msg.sender] += amount;

        emit StartedChallenge(msg.sender, challengeID, amount);

        bool success = IERC20(MOONBEAM_USDC_ADDR).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer Failed!");
        activityID+=1; // increase the activity ID after a challenge is created
    }

    function recordChallenge(uint256 challengeID) external {
        UserChallenge memory userChallenge = userChallenges[msg.sender][challengeID];
        ChallengeInfo storage challenge = challengesByID[challengeID];
        if (userChallenge.startDate > block.timestamp) revert ChallengeNotStarted();
        uint256 balanceToPoolPrize = (challenge.balance * (1 ether / 2)) / 1 ether;
        uint256 paymentPerDay = userChallenge.paymentPerDay;

        uint8 day = _whichDay(userChallenge.startDate);
        bool recordSet = setRecord(msg.sender, challengeID, day);

        if (recordSet) {
            challenge.balance += paymentPerDay;
            userChallenge.currentStreak++;
            userChallenge.amountOwed += paymentPerDay;
            // Update record for the current day to be true
            activityRecords[msg.sender][challengeID].challengeDays[day] = true;
        } else {
            revert AlreadyRecorded();
        }

        if (day == 20 && userChallenge.currentStreak == 14) {
            if (allBoolsTrue(msg.sender, challengeID)) {
                /// push into an array of eligible participants
                eligibleParticipants.push(payable(msg.sender));
            }
        }

        challenge.amountEarned += balanceToPoolPrize;
        challengesByID[challengeID] = challenge;
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

    function withdrawAtEndOfChallenge(address user, uint256 challengeID) public {

    }

    function adminRecordFailedChallenge(address user, uint256 challengeID) external onlyOwner {
        UserChallenge memory challenge = userChallenges[user][challengeID];
        Record memory userRecord = activityRecords[user][challengeID];
        uint256 today = _whichDay(challenge.startDate);

        if (userRecord.challengeDays[today] == true) revert UserAlreadyRecordedChallenge();
        /// Split paymentPerDay into 2. Half to treasury and half to prizePool
        IERC20(MOONBEAM_USDC_ADDR).transfer(TREASURY_ADDR, challenge.paymentPerDay * 50 / 100);
        IERC20(MOONBEAM_USDC_ADDR).transfer(PRIZE_POOL_ADDR, challenge.paymentPerDay * 50 / 100);
    }

    function setMonthEnd(uint256 stamp) external onlyOwner {
        require(stamp > block.timestamp, "Month end must be greater than current timestamp");
        monthEnd = stamp;
    }

    function generateChallengeIdentifier(
        uint256 startDate,
        uint256 activityId,
        uint256 amount
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(activityId, startDate, amount)));
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

    function getUserCount() internal view { }
}
