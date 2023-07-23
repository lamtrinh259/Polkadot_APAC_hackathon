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
        uint8 currentStreak; // current checked-in streak of the user
        uint256 amountOwed; // amount owed to the user after every checked-in day
    }

    struct ChallengeInfo {
        uint256 balance;
        uint256 amountEarned;
    }
    // address[] winners; // redundant type here, since winners would be separate from the challenge

    struct Record {
        bool[21] challengeDays; // already set all values default to false
    }

    uint40 private constant CHALLENGE_DURATION = 21 days;
    uint40 private constant CHALLENGE_CHECKIN_RATE = 1 days;
    uint256 constant MINIMUM_WAGER = 5_000_000; // 5 USDC
    // This is USDC address on Moonbase Alpha testnet
    address private constant MOONBASE_ALPHA_USDC_ADDR = 0x7303B11fbDA9200B6b365Ad0791D4ddee661b18e;
    address private constant MOONBEAM_USDC_ADDR = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b; // This is USDC address on
        // Moonbeam mainnet
    // Treasury address (temporary), until a permanent one is set up like Safe
    address private constant TREASURY_ADDR = 0xeD90B79f66830699E8D411Ebc5F99017B65b56B1;
    // Prize pool address, can just use address(this) so it'll be the contract address
    address private immutable PRIZE_POOL_ADDR = address(this);
    address public constant DIA_ORACLE_ADDRESS = 0x48d351aB7f8646239BbadE95c3Cc6de3eF4A6cec; // on Moonbase Alpha
        // testnet
    address public constant LOTTERY_DEPLOYED_CONTRACT_ADDRESS = 0x096407a84Cc500023B344902Cd0db43742603f34; // on
        // Moonbase Alpha testnet

    uint256 private activityID; // counter for activity ID
    uint256 private s_minimumDeposit; // minimum deposit amount for the challenge
    uint256[] public monthEnds = [1_690_815_599, 1_693_493_999, 1_696_085_999, 1_698_764_399]; // hold the UNIX
        // timestamp for the end of the following 4 months
    address payable[] private s_eligibleParticipants;
    address payable[] private s_winners;
    mapping(address => mapping(uint256 => UserChallenge)) public userChallenges;
    mapping(address => uint256) public userBalances;
    mapping(uint256 => ChallengeInfo) public challengesByID;
    mapping(address => mapping(uint256 => Record)) private activityRecords;

    event StartedChallenge(address indexed user, uint256 indexed challengeID, uint256 amount);
    event PickedWinners(address payable[] s_winners, uint256[] prizes, uint256 timestamp);

    Lottery public lotteryContract;

    constructor() Ownable(msg.sender) {
        s_minimumDeposit = MINIMUM_WAGER; // set the minimum deposit amount in USDC
        activityID = 1; // activity ID = 1 when first initiated
        lotteryContract = Lottery(LOTTERY_DEPLOYED_CONTRACT_ADDRESS);
    }

    function startChallenge(
        uint256 startDate, // Needs to be passed in as UNIX timestamp from front-end
        uint256 amount // This is the user's pledge amount in USDC
    )
        external
        payable
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

        bool successfulDepositToContract =
            IERC20(MOONBASE_ALPHA_USDC_ADDR).transferFrom(msg.sender, address(this), amount);
        require(successfulDepositToContract, "Transfer to contract failed!");
        activityID += 1; // increase the activity ID after a challenge is created
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

        // These lines below might be redundant
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
        require(msg.sender == user, "Unauthorized: Only challenge initiator or owner can call this function");

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

    function pickWinners(address payable[] calldata s_eligibleParticipants) external onlyOwner {
        // Ensure that the lotteryContract has been deployed
        require(address(lotteryContract) != address(0), "Lottery contract not deployed");

        // Call the drawWinners function in the Lottery contract to pick winners
        lotteryContract.drawWinners(s_eligibleParticipants);

        // Get the list of winners from the Lottery contract
        s_winners = lotteryContract.getWinners();

        // Calculate prize amounts for each winner
        uint256[] memory prizes = calculatePrizeAmounts();

        // Distribute prizes to winners
        for (uint256 i = 0; i < s_winners.length; i++) {
            // Ensure the prize amount is not zero before transferring
            // require(prizes[i] > 0, "Prize amount cannot be zero");
            IERC20(MOONBASE_ALPHA_USDC_ADDR).transfer(s_winners[i], prizes[i]);
        }

        emit PickedWinners(s_winners, prizes, block.timestamp);
    }

    function setMonthEnd(uint256 stamp) external onlyOwner {
        require(stamp > block.timestamp, "Month end must be greater than current timestamp");
        monthEnds.push(stamp); // This will push the new timestamp to the end of the array
    }

    function calculatePrizeAmounts() internal view returns (uint256[] memory) {
        uint256 prizePoolBalance = IERC20(MOONBASE_ALPHA_USDC_ADDR).balanceOf(PRIZE_POOL_ADDR);

        // Calculate the prize amounts based on the distribution percentages
        uint256 firstPlacePrize = (prizePoolBalance * 5) / 100; // 5% of the prize pool
        uint256 secondPlacePrize = (prizePoolBalance * 3) / 100; // 3% of the prize pool
        uint256 thirdPlacePrize = (prizePoolBalance * 2) / 100; // 2% of the prize pool

        uint256[] memory prizes = new uint256[](3);
        prizes[0] = firstPlacePrize;
        prizes[1] = secondPlacePrize;
        prizes[2] = thirdPlacePrize;

        return prizes;
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

    function _whichMonth(uint256 _startTimestamp) internal view returns (uint8) {
        uint256 elapsedTime = block.timestamp - _startTimestamp;
        uint256 numberOfMonths = elapsedTime / 30 days;
        uint256 currentMonth = monthEnds.length; // Get the number of months recorded in monthEnds array
        for (uint256 i = 0; i < monthEnds.length; i++) {
            if (block.timestamp <= monthEnds[i]) {
                currentMonth = i + 1; // The current month is the i-th month in the array
                break;
            }
        }
        return uint8((numberOfMonths + currentMonth) % 4);
    }

    /**
     * Getter function
     */
    function getMinimumDeposit() public view returns (uint256) {
        return s_minimumDeposit;
    }

    function getEligibileParticipants() external view returns (address payable[] memory) {
        return s_eligibleParticipants;
    }

    function getWinners() external view returns (address payable[] memory) {
        return s_winners;
    }

    function getPrizes() external view returns (uint256[] memory) {
        return calculatePrizeAmounts();
    }

    function getPrizePoolBalance() external view returns (uint256) {
        return IERC20(MOONBASE_ALPHA_USDC_ADDR).balanceOf(PRIZE_POOL_ADDR);
    }
}
