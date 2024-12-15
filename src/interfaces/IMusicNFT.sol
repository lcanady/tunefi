// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMusicNFT {
    function exists(uint256 tokenId) external view returns (bool);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}
