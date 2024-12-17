// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRoyaltyDistributor {
    function distributeRoyalties(uint256 tokenId, uint256 amount) external;
    function registerPayees(uint256 tokenId, address[] memory payees, uint256[] memory shares) external;
    function setStreamingRate(uint256 tokenId, uint256 ratePerMinute) external;
    function recordStreamingMinutes(uint256 tokenId, uint256 streamedMinutes) external;
    function getStreamingStats(uint256 tokenId)
        external
        view
        returns (uint256 rate, uint256 streamedMinutes, uint256 accumulated);
}
