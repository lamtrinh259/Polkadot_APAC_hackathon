// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

uint40 constant CHALLENGE_DURATION = 21 days;
uint40 constant CHALLENGE_CHECKIN_RATE = 1 days;
uint256 constant MINIMUM_WAGER = 5_000_000;

address constant MOONBEAM_USDC_ADDR = 0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b;

// Mock temporary treasury EVM address below, will be replaced with real treasury address after deployed
address constant TREASURY_ADDR = 0xBa40994Ef006b66a7252621554791DbE957b69b4;

// mock temporary prize pool address
address constant PRIZE_POOL_ADDR = 0xBa40994Ef006b66a7252621554791DbE957b69b4;

struct UserChallenge {
    bool challengeAccepted; // did the user accept this challenge?
    uint256 amountPaid;
    uint256 challengeID;
    uint256 startDate;
    uint256 paymentPerDay; // 1/21 of the user's wager
}

struct ChallengeInfo {
    uint256     balance;
    uint256 amountEarned;
    address[] winners;
}

struct Record {
    bool[21] challengeDays;
}

library Errors {
    /// @notice error thrown if challenge has not started
    error ChallengeNotStarted();

    /// @notice error thrown when the challenge has expired
    error ChallengeExpired();

    /// @notice error thrown when insufficient wager is proposed
    error InsufficientWager();

    /// @notice error thrown when there is a duplicate challenge.
    /// @dev duplictae challenge is a challenge with the same ID from a single User
    error DuplicateChallenger();

    /// @notice error thrown when there is an already recorded challenge for the day (timestamp)
    error AlreadyRecorded();

    /// @notice error for when admin tries to set record that user already set
    error UserAlreadyRecordedChallenge();
}

abstract contract Modifiers {
    modifier amountMustExceedMinWager(uint256 amount) {
        if (amount < MINIMUM_WAGER) {
            revert Errors.InsufficientWager();
        }
        _;
    }

    modifier dateMustExceedNow(uint256 startDate) {
        if (startDate < block.timestamp) {
            revert Errors.ChallengeExpired();
        }
        _;
    }

    modifier challengeMustHaveStarted(uint256 startDate) {
        if (startDate > block.timestamp) {
            revert Errors.ChallengeNotStarted();
        }
        _;
    }
}

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
