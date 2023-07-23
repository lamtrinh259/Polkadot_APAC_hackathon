// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Modifiers } from "../modifiers/Motivate.sol";
import { Lottery } from "../lib/Lottery.sol";

contract Motivate is Modifiers, Ownable {
    /// @notice error thrown when there is a duplicate challenge.
    /// @dev duplictae challenge is a challenge with the same ID from a single User
    error Motivate_DuplicateChallenger();

    /// @notice error thrown when there is an already recorded challenge for the day (timestamp)
    error Motivate_AlreadyRecorded();

    /// @notice error for when admin tries to set record that user already set
    error Motivate_UserAlreadyRecordedChallenge();

    error Motivate_NotEnoughDepositAmount();

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
        // address[] winners; // redundant type here, since winners would be separate from the challenge
    }

    struct Record {
        bool[21] challengeDays; // already set all values default to false
    }

    uint40 private constant CHALLENGE_DURATION = 21 days;
    uint40 private constant CHALLENGE_CHECKIN_RATE = 1 days;
    uint256 constant MINIMUM_WAGER = 5_000_000; // 5 USDC
    // Need to deploy a mock USDC token on Moonbase Alpha testnet where people can freely obtain USDC
    address private constant MOONBASE_ALPHA_USDC_ADDR = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b; // needs to be changed
    address private constant MOONBEAM_USDC_ADDR = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b; // This is USDC address on Moonbeam mainnet
    // Mock temporary treasury EVM address below, will be replaced with real treasury address after deployed
    address private constant TREASURY_ADDR = 0x7B79079271A010E28b73d1F88c84C6720E2EF903;
    // mock temporary prize pool address, can just use address(this) so it'll be the contract address
    address private constant PRIZE_POOL_ADDR = 0xeD90B79f66830699E8D411Ebc5F99017B65b56B1;
    address public constant DIA_ORACLE_ADDRESS = 0x48d351aB7f8646239BbadE95c3Cc6de3eF4A6cec; // on Moonbase Alpha testnet
    address public constant LOTTERY_DEPLOYED_CONTRACT_ADDRESS = 0x096407a84Cc500023B344902Cd0db43742603f34;  // on Moonbase Alpha testnet

    uint256 private activityID; // counter for activity ID
    uint256 private s_minimumDeposit; // minimum deposit amount for the challenge
    uint256 public monthEnd; // hold the UNIX timestamp for the end of the month
    address payable[] private s_eligibleParticipants;
    address payable[] private s_winners;
    mapping(address => mapping(uint256 => UserChallenge)) public userChallenges;
    mapping(address => uint256) public userBalances;
    mapping(uint256 => ChallengeInfo) public challengesByID;
    mapping(address => mapping(uint256 => Record)) private activityRecords;

    event StartedChallenge(address indexed user, uint256 indexed challengeID, uint256 amount);
    event PickedWinners(address indexed s_winners);

    Lottery public lotteryContract;

    constructor() Ownable(msg.sender) {
        s_minimumDeposit = MINIMUM_WAGER; // set the minimum deposit amount
        activityID = 1;  // activity ID = 1 when first initiated
        lotteryContract = Lottery(LOTTERY_DEPLOYED_CONTRACT_ADDRESS);
    }

    function startChallenge(
        uint256 startDate,
        uint256 amount // This is the user's pledge amount
    )
        external payable
        dateMustExceedNow(startDate)
    {
        if (msg.value < s_minimumDeposit) {
            revert Motivate_NotEnoughDepositAmount();
        }
        uint256 currentId = activityID;
        uint256 challengeID = generateChallengeIdentifier(startDate, currentId, amount);
        if (userChallenges[msg.sender][challengeID].challengeAccepted) {
            revert Motivate_DuplicateChallenger();
        }

        /// @notice create the user's challenge
        UserChallenge memory userChallenge = UserChallenge({
            challengeAccepted: true,
            paymentPerDay: amount / 21,
            challengeID: challengeID,
            startDate: startDate,
            amountPaid: amount,
            currentStreak: 0, // number of successful checked-in days
            amountOwed: 0 // amount that will be refunded to user at the end of the challenge
        });

        userChallenges[msg.sender][challengeID] = userChallenge;
        userBalances[msg.sender] += amount;

        emit StartedChallenge(msg.sender, challengeID, amount);

        bool successfulDepositToContract = IERC20(MOONBASE_ALPHA_USDC_ADDR).transferFrom(msg.sender, address(this), amount);
        require(successfulDepositToContract, "Transfer to contract failed!");
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
            revert Motivate_AlreadyRecorded();
        }

        if (day == 20) {
            // call withdrawAtEndOfChallenge function for the user and challengeID
            withdrawAtEndOfChallenge(msg.sender, challengeID); // Pass the user address as a parameter
        }

        // These lines below may be redundant
        challenge.amountEarned += balanceToPoolPrize;
        challengesByID[challengeID] = challenge;
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

    /// @dev this function may not be necessary since the default value in the boolean is already false
    function adminRecordFailedDay(address user, uint256 challengeID, uint8 _n) external onlyOwner {
        UserChallenge memory challenge = userChallenges[user][challengeID];
        Record storage userRecord = activityRecords[user][challengeID];

        if (userRecord.challengeDays[_n] == true) revert Motivate_UserAlreadyRecordedChallenge();
        userRecord.challengeDays[_n] = false; // Set the day as failed (not checked-in)
        uint256 amountPerDay = challenge.paymentPerDay;
        uint256 amountForTreasury = amountPerDay * 50 / 100;
        uint256 amountForPrizePool = amountPerDay * 50 / 100;

        IERC20(MOONBASE_ALPHA_USDC_ADDR).transfer(TREASURY_ADDR, amountForTreasury);
        IERC20(MOONBASE_ALPHA_USDC_ADDR).transfer(address(this), amountForPrizePool);
    }

    function withdrawAtEndOfChallenge(address user, uint256 challengeID) public onlyOwner {
        UserChallenge storage userChallenge = userChallenges[user][challengeID];
        require(userChallenge.challengeAccepted, "Challenge not found");
        require(
            msg.sender == user,
            "Unauthorized: Only challenge initiator or owner can call this function"
        );

        if (userChallenge.currentStreak == 21) {
            // If challenge is completed, transfer the full amount paid back to the user
            IERC20(MOONBASE_ALPHA_USDC_ADDR).transfer(user, userChallenge.amountPaid);
            // push into an array of eligible participants
            s_eligibleParticipants.push(payable(user));
        } else if (userChallenge.currentStreak >= 14 && userChallenge.currentStreak < 21) {
            // push into an array of eligible participants
            s_eligibleParticipants.push(payable(user));
            // Calculate the amount owed based on the completed days and paymentPerDay
            uint256 daysCompleted = userChallenge.currentStreak;
            uint256 amountOwed = daysCompleted * userChallenge.paymentPerDay;

            // Transfer the amount owed to the user
            IERC20(MOONBASE_ALPHA_USDC_ADDR).transfer(user, amountOwed);
        } else {
            // Calculate the amount owed based on the completed days and paymentPerDay
            uint256 daysCompleted = userChallenge.currentStreak;
            uint256 amountOwed = daysCompleted * userChallenge.paymentPerDay;

            // Transfer the amount owed to the user
            IERC20(MOONBASE_ALPHA_USDC_ADDR).transfer(user, amountOwed);
        }

        // Reset the UserChallenge struct, might not be necessary
        delete userChallenges[user][challengeID];
    }

    function pickWinners() external onlyOwner {
        // Ensure that the lotteryContract has been deployed
        require(address(lotteryContract) != address(0), "Lottery contract not deployed");

        // Call the drawWinners function in the Lottery contract to pick winners
        lotteryContract.drawWinners(s_eligibleParticipants);

        // Get the list of winners from the Lottery contract
        s_winners = lotteryContract.getWinners();
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

    /// @notice This function returns the current day index of the challenge, a value between 0 and 20 (inclusive)
    function _whichDay(uint256 _startTimestamp) internal view returns (uint8) {
        uint256 elapsedTime = block.timestamp - _startTimestamp;
        uint256 numberOfDays = elapsedTime / 1 days;
        return uint8(numberOfDays % 21);
    }

    /** Getter function */
    function getMinimumDeposit() public view returns (uint256) {
        return s_minimumDeposit;
    }

    function getEligibileParticipants() external view returns (address payable[] memory) {
      return s_eligibleParticipants;
    }
    function getWinners() external view returns (address payable[] memory) {
      return s_winners;
    }
}
