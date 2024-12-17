// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MusicNFT.sol";
import "../src/TuneToken.sol";
import "../src/RoyaltyDistributor.sol";
import "../src/FanEngagement.sol";
import "../src/Marketplace.sol";
import "../src/StakingContract.sol";

contract DeployScript is Script {
    MusicNFT public musicNFT;
    TuneToken public tuneToken;
    RoyaltyDistributor public royaltyDistributor;
    FanEngagement public fanEngagement;
    Marketplace public marketplace;
    StakingContract public staking;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy TuneToken first
        tuneToken = new TuneToken();
        console.log("TuneToken deployed at:", address(tuneToken));

        // Deploy RoyaltyDistributor
        royaltyDistributor = new RoyaltyDistributor(address(tuneToken));
        console.log("RoyaltyDistributor deployed at:", address(royaltyDistributor));

        // Deploy MusicNFT
        musicNFT = new MusicNFT("ipfs://", address(tuneToken), address(royaltyDistributor));
        console.log("MusicNFT deployed at:", address(musicNFT));

        // Deploy FanEngagement
        fanEngagement = new FanEngagement(address(tuneToken), address(musicNFT));
        console.log("FanEngagement deployed at:", address(fanEngagement));

        // Deploy Marketplace
        marketplace = new Marketplace(address(tuneToken), address(musicNFT));
        console.log("Marketplace deployed at:", address(marketplace));

        // Deploy StakingContract
        staking = new StakingContract(
            address(tuneToken),
            100 * 10 ** 18, // Minimum stake amount
            1000, // 10% annual reward rate
            500 // 5% slash rate
        );
        console.log("StakingContract deployed at:", address(staking));

        // Setup roles and permissions
        royaltyDistributor.grantRole(royaltyDistributor.DISTRIBUTOR_ROLE(), address(musicNFT));
        musicNFT.grantRole(musicNFT.MINTER_ROLE(), msg.sender);

        // Transfer initial tokens to contracts
        uint256 initialBalance = 1_000_000 * 10 ** 18;
        tuneToken.transfer(address(fanEngagement), initialBalance);
        tuneToken.transfer(address(staking), initialBalance);

        vm.stopBroadcast();
    }
}
