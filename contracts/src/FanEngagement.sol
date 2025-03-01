// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMusicNFT.sol";

/**
 * @title FanEngagement
 * @dev Contract for managing fan engagement features and rewards
 */
contract FanEngagement is Ownable, ReentrancyGuard {
    // State variables
    IERC20 public rewardToken;
    IMusicNFT public musicNFT;

    // Constants
    uint256 public constant LIKE_POINTS = 1;
    uint256 public constant SHARE_POINTS = 2;
    uint256 public constant STREAM_POINTS = 1;
    uint256 public constant PURCHASE_POINTS = 5;
    uint256 public constant POINTS_TO_REWARDS_RATE = 100; // 100 points = 1 token

    // Structs
    struct UserStats {
        uint256 totalPoints;
        uint256 totalInteractions;
        uint256 lastInteractionTime;
        bool hasAchievedFirstLike;
        bool hasAchievedFirstPurchase;
        bool hasAchievedTenInteractions;
    }

    // Mappings
    mapping(address => UserStats) public userStats;
    mapping(uint256 => mapping(address => bool)) public hasLiked;
    mapping(uint256 => mapping(address => bool)) public hasShared;

    // Events
    event PointsEarned(address indexed user, uint256 points, string action);
    event AchievementUnlocked(address indexed user, string achievement);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(address _rewardToken, address _musicNFT) Ownable(msg.sender) {
        rewardToken = IERC20(_rewardToken);
        musicNFT = IMusicNFT(_musicNFT);
    }

    /**
     * @dev Record a like interaction
     * @param tokenId The ID of the track being liked
     */
    function recordLike(uint256 tokenId) external nonReentrant {
        require(!hasLiked[tokenId][msg.sender], "Already liked this track");
        require(musicNFT.exists(tokenId), "Track does not exist");

        hasLiked[tokenId][msg.sender] = true;
        _addPoints(msg.sender, LIKE_POINTS);
        _updateUserStats(msg.sender);

        if (!userStats[msg.sender].hasAchievedFirstLike) {
            userStats[msg.sender].hasAchievedFirstLike = true;
            emit AchievementUnlocked(msg.sender, "First Like");
        }

        emit PointsEarned(msg.sender, LIKE_POINTS, "like");
    }

    /**
     * @dev Record a share interaction
     * @param tokenId The ID of the track being shared
     */
    function recordShare(uint256 tokenId) external nonReentrant {
        require(!hasShared[tokenId][msg.sender], "Already shared this track");
        require(musicNFT.exists(tokenId), "Track does not exist");

        hasShared[tokenId][msg.sender] = true;
        _addPoints(msg.sender, SHARE_POINTS);
        _updateUserStats(msg.sender);

        emit PointsEarned(msg.sender, SHARE_POINTS, "share");
    }

    /**
     * @dev Record a stream interaction
     * @param tokenId The ID of the track being streamed
     */
    function recordStream(uint256 tokenId) external nonReentrant {
        require(musicNFT.exists(tokenId), "Track does not exist");

        _addPoints(msg.sender, STREAM_POINTS);
        _updateUserStats(msg.sender);

        emit PointsEarned(msg.sender, STREAM_POINTS, "stream");
    }

    /**
     * @dev Record a purchase interaction
     * @param tokenId The ID of the track being purchased
     */
    function recordPurchase(uint256 tokenId) external nonReentrant {
        require(musicNFT.exists(tokenId), "Track does not exist");
        require(musicNFT.balanceOf(msg.sender, tokenId) > 0, "Must own the track");

        _addPoints(msg.sender, PURCHASE_POINTS);
        _updateUserStats(msg.sender);

        if (!userStats[msg.sender].hasAchievedFirstPurchase) {
            userStats[msg.sender].hasAchievedFirstPurchase = true;
            emit AchievementUnlocked(msg.sender, "First Purchase");
        }

        emit PointsEarned(msg.sender, PURCHASE_POINTS, "purchase");
    }

    /**
     * @dev Claim rewards based on accumulated points
     */
    function claimRewards() external nonReentrant {
        UserStats storage stats = userStats[msg.sender];
        require(stats.totalPoints > 0, "No points to claim");

        uint256 rewardAmount = (stats.totalPoints * 1e18) / POINTS_TO_REWARDS_RATE;
        require(rewardAmount > 0, "Reward amount too small");
        require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Insufficient reward balance");

        stats.totalPoints = 0;
        rewardToken.transfer(msg.sender, rewardAmount);

        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    /**
     * @dev Get user statistics
     * @param user Address of the user
     */
    function getUserStats(address user)
        external
        view
        returns (
            uint256 totalPoints,
            uint256 totalInteractions,
            uint256 lastInteractionTime,
            bool hasAchievedFirstLike,
            bool hasAchievedFirstPurchase,
            bool hasAchievedTenInteractions
        )
    {
        UserStats memory stats = userStats[user];
        return (
            stats.totalPoints,
            stats.totalInteractions,
            stats.lastInteractionTime,
            stats.hasAchievedFirstLike,
            stats.hasAchievedFirstPurchase,
            stats.hasAchievedTenInteractions
        );
    }

    // Internal functions
    function _addPoints(address user, uint256 points) internal {
        userStats[user].totalPoints += points;
    }

    function _updateUserStats(address user) internal {
        UserStats storage stats = userStats[user];
        stats.totalInteractions++;
        stats.lastInteractionTime = block.timestamp;

        if (stats.totalInteractions == 10 && !stats.hasAchievedTenInteractions) {
            stats.hasAchievedTenInteractions = true;
            emit AchievementUnlocked(user, "Ten Interactions");
        }
    }
}
