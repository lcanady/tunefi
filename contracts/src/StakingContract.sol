// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title StakingContract
 * @dev A staking contract for TuneFi tokens with delegation and slashing capabilities
 */
contract StakingContract is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");

    // State variables
    IERC20 public immutable stakingToken;
    uint256 public immutable minStakeAmount;
    uint256 public immutable rewardRate; // Annual reward rate in percentage (e.g., 10 for 10%)
    uint256 public immutable slashRate; // Slash rate in percentage (e.g., 50 for 50%)

    uint256 public totalStaked;
    bool public emergencyState;

    // Staking info
    struct StakeInfo {
        uint256 amount;
        uint256 lastRewardUpdate;
        uint256 rewardDebt;
        address delegatedTo;
    }

    // Mappings
    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public delegatedPower;
    mapping(address => bool) public slashers;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event Slashed(address indexed user, uint256 amount);
    event DelegationUpdated(address indexed from, address indexed to);
    event SlasherUpdated(address indexed slasher, bool status);
    event EmergencyStateUpdated(bool state);

    // Constants
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant UNSTAKE_DELAY = 7 days;

    /**
     * @dev Constructor
     * @param _stakingToken Address of the token used for staking
     * @param _minStakeAmount Minimum amount required to stake
     * @param _rewardRate Annual reward rate in percentage
     * @param _slashRate Slash rate in percentage
     */
    constructor(address _stakingToken, uint256 _minStakeAmount, uint256 _rewardRate, uint256 _slashRate) {
        require(_stakingToken != address(0), "Invalid token address");
        require(_minStakeAmount > 0, "Invalid min stake amount");
        require(_rewardRate > 0 && _rewardRate <= 100, "Invalid reward rate");
        require(_slashRate > 0 && _slashRate <= 100, "Invalid slash rate");

        stakingToken = IERC20(_stakingToken);
        minStakeAmount = _minStakeAmount;
        rewardRate = _rewardRate;
        slashRate = _slashRate;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(SLASHER_ROLE, msg.sender);
    }

    /**
     * @dev Stake tokens
     * @param amount Amount to stake
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount >= minStakeAmount, "Below minimum stake amount");
        require(!emergencyState, "Emergency: staking disabled");

        // Update rewards
        _updateRewards(msg.sender);

        // Transfer tokens
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Update state
        stakes[msg.sender].amount += amount;
        totalStaked += amount;

        // Update delegation if exists
        address delegatee = stakes[msg.sender].delegatedTo;
        if (delegatee != address(0)) {
            delegatedPower[delegatee] += amount;
        }

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Unstake tokens
     * @param amount Amount to unstake
     */
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount >= amount, "Insufficient stake");
        require(!emergencyState, "Emergency: use emergencyWithdraw");

        // Check unstake delay
        require(block.timestamp >= stakeInfo.lastRewardUpdate + UNSTAKE_DELAY, "Unstake delay not met");

        // Update rewards
        _updateRewards(msg.sender);

        // Update state
        stakeInfo.amount -= amount;
        totalStaked -= amount;

        // Update delegation if exists
        address delegatee = stakeInfo.delegatedTo;
        if (delegatee != address(0)) {
            delegatedPower[delegatee] -= amount;
        }

        // Transfer tokens
        stakingToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Emergency withdraw without rewards
     */
    function emergencyWithdraw() external nonReentrant {
        require(emergencyState, "Not in emergency state");

        StakeInfo storage stakeInfo = stakes[msg.sender];
        uint256 amount = stakeInfo.amount;
        require(amount > 0, "No stake to withdraw");

        // Reset stake info
        stakeInfo.amount = 0;
        stakeInfo.rewardDebt = 0;
        totalStaked -= amount;

        // Update delegation if exists
        address delegatee = stakeInfo.delegatedTo;
        if (delegatee != address(0)) {
            delegatedPower[delegatee] -= amount;
        }

        // Transfer tokens
        stakingToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Slash a staker's tokens
     * @param staker Address of the staker to slash
     */
    function slash(address staker) external nonReentrant onlyRole(SLASHER_ROLE) {
        StakeInfo storage stakeInfo = stakes[staker];
        require(stakeInfo.amount > 0, "No stake to slash");

        uint256 slashAmount = (stakeInfo.amount * slashRate) / 100;
        stakeInfo.amount -= slashAmount;
        totalStaked -= slashAmount;

        // Update delegation if exists
        address delegatee = stakeInfo.delegatedTo;
        if (delegatee != address(0)) {
            delegatedPower[delegatee] -= slashAmount;
        }

        emit Slashed(staker, slashAmount);
    }

    /**
     * @dev Claim pending rewards
     */
    function claimRewards() external nonReentrant whenNotPaused {
        require(!emergencyState, "Emergency: rewards disabled");

        uint256 rewards = _updateRewards(msg.sender);
        require(rewards > 0, "No rewards to claim");

        // Reset reward debt
        stakes[msg.sender].rewardDebt = 0;

        // Transfer rewards
        stakingToken.safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Delegate staking power
     * @param delegatee Address to delegate to
     */
    function delegate(address delegatee) external nonReentrant whenNotPaused {
        require(delegatee != address(0), "Invalid delegatee");
        require(delegatee != msg.sender, "Cannot delegate to self");

        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount > 0, "No stake to delegate");

        // Remove power from old delegatee
        address oldDelegatee = stakeInfo.delegatedTo;
        if (oldDelegatee != address(0)) {
            delegatedPower[oldDelegatee] -= stakeInfo.amount;
        }

        // Add power to new delegatee
        stakeInfo.delegatedTo = delegatee;
        delegatedPower[delegatee] += stakeInfo.amount;

        emit DelegationUpdated(msg.sender, delegatee);
    }

    /**
     * @dev Remove delegation
     */
    function undelegate() external nonReentrant {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        address oldDelegatee = stakeInfo.delegatedTo;
        require(oldDelegatee != address(0), "Not delegated");

        // Remove power from delegatee
        delegatedPower[oldDelegatee] -= stakeInfo.amount;
        stakeInfo.delegatedTo = address(0);

        emit DelegationUpdated(msg.sender, address(0));
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Set emergency state
     * @param state True to enable, false to disable
     */
    function setEmergencyState(bool state) external onlyRole(ADMIN_ROLE) {
        emergencyState = state;
        emit EmergencyStateUpdated(state);
    }

    /**
     * @dev Add or remove a slasher
     * @param slasher Address of the slasher
     * @param status True to add, false to remove
     */
    function updateSlasher(address slasher, bool status) external onlyRole(ADMIN_ROLE) {
        require(slasher != address(0), "Invalid slasher address");
        if (status) {
            _grantRole(SLASHER_ROLE, slasher);
        } else {
            _revokeRole(SLASHER_ROLE, slasher);
        }
        emit SlasherUpdated(slasher, status);
    }

    /**
     * @dev Get pending rewards for a staker
     * @param staker Address of the staker
     * @return Pending reward amount
     */
    function pendingRewards(address staker) public view returns (uint256) {
        StakeInfo storage stakeInfo = stakes[staker];
        if (stakeInfo.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - stakeInfo.lastRewardUpdate;
        uint256 rewards = (stakeInfo.amount * rewardRate * timeElapsed) / (SECONDS_PER_YEAR * 100);
        return rewards + stakeInfo.rewardDebt;
    }

    /**
     * @dev Get staked amount for a staker
     * @param staker Address of the staker
     * @return Staked amount
     */
    function stakedAmount(address staker) external view returns (uint256) {
        return stakes[staker].amount;
    }

    /**
     * @dev Get delegated address for a staker
     * @param staker Address of the staker
     * @return Delegated address
     */
    function delegatedTo(address staker) external view returns (address) {
        return stakes[staker].delegatedTo;
    }

    /**
     * @dev Update rewards for a staker
     * @param staker Address of the staker
     * @return Pending reward amount
     */
    function _updateRewards(address staker) private returns (uint256) {
        uint256 rewards = pendingRewards(staker);
        stakes[staker].lastRewardUpdate = block.timestamp;
        stakes[staker].rewardDebt = rewards;
        return rewards;
    }
}
