// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";

/// @title TuneToken
/// @notice Governance and utility token for the Tunefi ecosystem with advanced tokenomics
/// @dev Implements ERC20 with voting, vesting, staking, and inflation mechanics
/// @custom:security-contact security@tunefi.io
contract TuneToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    // Constants
    /// @notice Maximum total supply cap of 2 billion tokens
    uint256 public constant MAX_SUPPLY = 2_000_000_000 * 10 ** 18;
    
    /// @notice Annual inflation rate of 2% in basis points (200/10000)
    uint256 public constant INFLATION_RATE = 200;
    
    /// @notice Maximum allowed inflation rate of 5% in basis points (500/10000)
    uint256 public constant MAX_INFLATION_RATE = 500;
    
    /// @notice Platform fee burn rate of 1% in basis points (100/10000)
    uint256 public constant BURN_RATE = 100;
    
    /// @notice Duration of each reward epoch (7 days)
    uint256 public constant EPOCH_DURATION = 7 days;
    
    /// @notice Minimum amount required for staking (1000 tokens)
    uint256 public constant MIN_STAKE_AMOUNT = 1000 * 10 ** 18;

    // Distribution pools
    /// @notice Pool for community rewards and incentives
    uint256 public communityRewardsPool;
    
    /// @notice Pool for ecosystem development funding
    uint256 public ecosystemDevelopmentPool;
    
    /// @notice Pool for liquidity mining rewards
    uint256 public liquidityMiningPool;
    
    /// @notice Pool for governance incentives
    uint256 public governancePool;

    /// @notice Staking information for an address
    /// @dev Tracks staked amount, start time, and last reward claim time
    struct Stake {
        uint256 amount;        // Amount of tokens staked
        uint256 startTime;     // Timestamp when stake was created
        uint256 lastRewardTime; // Last time rewards were calculated
    }

    /// @notice Service tier information
    /// @dev Defines token holding requirements and discount rates
    struct ServiceTier {
        uint256 minTokens;    // Minimum tokens required for tier
        uint256 discountRate; // Discount rate in basis points
    }

    /// @notice Vesting schedule for token distribution
    /// @dev Controls token release over time with optional revocation
    struct VestingSchedule {
        uint256 totalAmount;    // Total tokens to be vested
        uint256 startTime;      // Start of vesting period
        uint256 duration;       // Length of vesting period
        uint256 releasedAmount; // Tokens already released
        bool revocable;         // Whether schedule can be revoked
        bool revoked;           // Whether schedule has been revoked
    }

    // State variables
    /// @notice Timestamp of last inflation mint
    uint256 public lastInflationTime;
    
    /// @notice Total amount of tokens burned
    uint256 public totalBurned;
    
    /// @notice Current epoch number
    uint256 public currentEpoch;
    
    /// @notice Accumulated rewards per staked token
    uint256 public rewardPerToken;
    
    /// @notice Mapping of address to staking information
    mapping(address => Stake) public stakes;
    
    /// @notice Mapping of tier level to service tier information
    mapping(uint256 => ServiceTier) public serviceTiers;
    
    /// @notice Mapping of address to vesting schedule
    mapping(address => VestingSchedule) public vestingSchedules;
    
    /// @notice Mapping of address to paid rewards per token
    mapping(address => uint256) public userRewardPerTokenPaid;
    
    /// @notice Mapping of address to pending rewards
    mapping(address => uint256) public rewards;

    // Events
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
    event VestingScheduleRevoked(address indexed beneficiary);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event TokensBurned(address indexed from, uint256 amount);
    event PoolFunded(string indexed poolName, uint256 amount);
    event ServiceTierUpdated(uint256 indexed tier, uint256 minTokens, uint256 discountRate);
    event EpochAdvanced(uint256 indexed epoch, uint256 rewardPerToken);

    /// @notice Initializes the token with initial supply and service tiers
    /// @dev Sets up initial token distribution and tier structure
    constructor() ERC20("TuneToken", "TUNE") ERC20Permit("TuneToken") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals()); // Initial supply of 1B tokens
        lastInflationTime = block.timestamp;
        
        // Initialize service tiers with token requirements and discount rates
        serviceTiers[1] = ServiceTier(10_000 * 10 ** 18, 500);  // Tier 1: 10k tokens, 5% discount
        serviceTiers[2] = ServiceTier(50_000 * 10 ** 18, 1000); // Tier 2: 50k tokens, 10% discount
        serviceTiers[3] = ServiceTier(100_000 * 10 ** 18, 2000); // Tier 3: 100k tokens, 20% discount
    }

    /// @notice Mints new tokens according to inflation schedule
    /// @dev Can only be called once per year and respects max supply cap
    function mintInflation() external {
        require(block.timestamp >= lastInflationTime + 365 days, "Too early for inflation");
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");

        // Calculate inflation amount with supply cap check
        uint256 inflationAmount = (totalSupply() * INFLATION_RATE) / 10000;
        uint256 remainingSupply = MAX_SUPPLY - totalSupply();
        inflationAmount = inflationAmount > remainingSupply ? remainingSupply : inflationAmount;

        _mint(address(this), inflationAmount);
        lastInflationTime = block.timestamp;

        // Distribute inflation to various pools
        communityRewardsPool += inflationAmount * 40 / 100;    // 40% to community
        ecosystemDevelopmentPool += inflationAmount * 30 / 100; // 30% to ecosystem
        liquidityMiningPool += inflationAmount * 20 / 100;      // 20% to liquidity
        governancePool += inflationAmount * 10 / 100;           // 10% to governance
    }

    /// @notice Burns tokens from the caller's balance
    /// @dev Updates total burned counter and emits event
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        totalBurned += amount;
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Stakes tokens for rewards
    /// @dev Requires minimum stake amount and updates rewards
    /// @param amount Amount of tokens to stake
    function stake(uint256 amount) external {
        require(amount >= MIN_STAKE_AMOUNT, "Below minimum stake amount");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Update rewards before modifying stake
        if (stakes[msg.sender].amount > 0) {
            _updateReward(msg.sender);
        }

        _transfer(msg.sender, address(this), amount);
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].lastRewardTime = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    /// @notice Unstakes tokens
    /// @dev Updates rewards before unstaking
    /// @param amount Amount of tokens to unstake
    function unstake(uint256 amount) external {
        require(stakes[msg.sender].amount >= amount, "Insufficient stake");
        
        _updateReward(msg.sender);
        stakes[msg.sender].amount -= amount;
        _transfer(address(this), msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /// @notice Claims accumulated staking rewards
    /// @dev Updates rewards and transfers earned tokens
    function claimRewards() external {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _transfer(address(this), msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice Advances the epoch and updates reward rate
    /// @dev Distributes rewards from liquidity mining pool
    function advanceEpoch() external {
        require(block.timestamp >= currentEpoch + EPOCH_DURATION, "Too early for epoch advance");
        
        uint256 totalStaked = balanceOf(address(this));
        if (totalStaked > 0) {
            // Calculate and distribute epoch rewards
            uint256 reward = (liquidityMiningPool * EPOCH_DURATION) / (365 days);
            rewardPerToken += (reward * 1e18) / totalStaked;
            liquidityMiningPool -= reward;
        }

        currentEpoch = block.timestamp;
        emit EpochAdvanced(currentEpoch, rewardPerToken);
    }

    /// @notice Gets the service tier discount for an address
    /// @dev Returns highest eligible discount rate
    /// @param user Address to check
    /// @return Discount rate in basis points
    function getServiceTierDiscount(address user) external view returns (uint256) {
        uint256 balance = balanceOf(user);
        uint256 maxDiscount = 0;

        // Check all tiers and return highest eligible discount
        for (uint256 i = 1; i <= 3; i++) {
            if (balance >= serviceTiers[i].minTokens && serviceTiers[i].discountRate > maxDiscount) {
                maxDiscount = serviceTiers[i].discountRate;
            }
        }

        return maxDiscount;
    }

    /// @notice Creates a vesting schedule for a beneficiary
    /// @dev Requires beneficiary address, amount, start time, duration, and revocability
    /// @param beneficiary Address of the beneficiary
    /// @param amount Total amount of tokens to vest
    /// @param startTime Start time of the vesting period
    /// @param duration Duration of the vesting period in seconds
    /// @param revocable Whether the vesting can be revoked by owner
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 duration,
        bool revocable
    )
        external
        onlyOwner
    {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(amount > 0, "Amount must be > 0");
        require(duration > 0, "Duration must be > 0");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Schedule exists");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            startTime: startTime,
            duration: duration,
            releasedAmount: 0,
            revocable: revocable,
            revoked: false
        });

        _transfer(msg.sender, address(this), amount);

        emit VestingScheduleCreated(beneficiary, amount, startTime, duration);
    }

    /// @notice Revokes the vesting schedule for a beneficiary
    /// @dev Requires beneficiary address and checks revocability and revoked status
    /// @param beneficiary Address of the beneficiary
    function revokeVesting(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No schedule");
        require(schedule.revocable, "Not revocable");
        require(!schedule.revoked, "Already revoked");

        uint256 currentVested = _vestedAmount(beneficiary);
        uint256 refundAmount = schedule.totalAmount - currentVested;

        schedule.revoked = true;
        if (refundAmount > 0) {
            _transfer(address(this), owner(), refundAmount);
        }

        emit VestingScheduleRevoked(beneficiary);
    }

    /// @notice Releases vested tokens for the caller
    function releaseVestedTokens() external {
        _releaseVestedTokens(msg.sender);
    }

    /// @notice Releases vested tokens for a beneficiary
    /// @param beneficiary Address of the beneficiary
    function releaseVestedTokensFor(address beneficiary) external {
        _releaseVestedTokens(beneficiary);
    }

    /// @notice Returns the amount of tokens that have vested for a beneficiary
    /// @param beneficiary Address of the beneficiary
    /// @return The amount of vested tokens
    function vestedAmount(address beneficiary) external view returns (uint256) {
        return _vestedAmount(beneficiary);
    }

    /// @notice Returns the amount of tokens that are still locked for a beneficiary
    /// @param beneficiary Address of the beneficiary
    /// @return The amount of locked tokens
    function lockedAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.revoked) {
            return 0;
        }
        return schedule.totalAmount - _vestedAmount(beneficiary);
    }

    // Internal functions

    /// @notice Updates reward calculation for an account
    /// @dev Calculates earned rewards based on stake and time
    /// @param account Address to update rewards for
    function _updateReward(address account) internal {
        uint256 earnedRewards = (
            (stakes[account].amount * (rewardPerToken - userRewardPerTokenPaid[account])) / 1e18
        );
        rewards[account] += earnedRewards;
        userRewardPerTokenPaid[account] = rewardPerToken;
    }

    function _vestedAmount(address beneficiary) internal view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        if (schedule.totalAmount == 0) {
            return 0;
        }

        if (block.timestamp < schedule.startTime) {
            return 0;
        }

        uint256 timePoint = schedule.revoked
            ? block.timestamp < schedule.startTime + schedule.duration
                ? block.timestamp
                : schedule.startTime + schedule.duration
            : block.timestamp;

        uint256 elapsedTime = timePoint - schedule.startTime;

        if (elapsedTime >= schedule.duration) {
            return schedule.totalAmount;
        }

        return (schedule.totalAmount * elapsedTime) / schedule.duration;
    }

    function _releaseVestedTokens(address beneficiary) internal {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No schedule");

        uint256 currentVested = _vestedAmount(beneficiary);
        uint256 releasableAmount = currentVested - schedule.releasedAmount;
        require(releasableAmount > 0, "No tokens to release");

        schedule.releasedAmount += releasableAmount;
        _transfer(address(this), beneficiary, releasableAmount);

        emit TokensReleased(beneficiary, releasableAmount);
    }

    // The following functions are overrides required by Solidity

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
