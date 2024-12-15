// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";

/// @title TuneToken
/// @notice Governance and utility token for the Tunefi ecosystem
/// @dev Implements ERC20 with voting and vesting capabilities
contract TuneToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    // Vesting schedule for a beneficiary
    struct VestingSchedule {
        uint256 totalAmount;      // Total amount of tokens to vest
        uint256 startTime;        // Start time of the vesting period
        uint256 duration;         // Duration of the vesting period in seconds
        uint256 releasedAmount;   // Amount of tokens already released
        bool revocable;           // Whether the vesting can be revoked by owner
        bool revoked;             // Whether the vesting has been revoked
    }

    // Mapping from beneficiary to their vesting schedule
    mapping(address => VestingSchedule) public vestingSchedules;

    // Events
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
    event VestingScheduleRevoked(address indexed beneficiary);
    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(uint256 initialSupply) 
        ERC20("TuneToken", "TUNE") 
        ERC20Permit("TuneToken")
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Creates a vesting schedule for a beneficiary
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
    ) external onlyOwner {
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

    function _vestedAmount(address beneficiary) internal view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        
        if (schedule.totalAmount == 0) {
            return 0;
        }

        if (block.timestamp < schedule.startTime) {
            return 0;
        }

        uint256 timePoint = schedule.revoked ? 
            block.timestamp < schedule.startTime + schedule.duration ? block.timestamp : schedule.startTime + schedule.duration : 
            block.timestamp;
        
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

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
