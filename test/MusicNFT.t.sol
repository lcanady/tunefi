// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MusicNFT.sol";
import "../src/TuneToken.sol";
import "../src/RoyaltyDistributor.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MusicNFTTest is Test, ERC1155Holder {
    MusicNFT public nft;
    TuneToken public token;
    RoyaltyDistributor public royaltyDistributor;

    address public constant ADMIN = address(1);
    address public constant ARTIST = address(2);
    address public constant FAN = address(3);
    string public constant TRACK_URI = "ipfs://QmTrackHash";
    uint256 public constant INITIAL_SUPPLY = 100;
    uint256 public constant PRICE = 100 * 1e18; // 100 tokens

    function setUp() public {
        vm.startPrank(ADMIN);

        // Deploy contracts
        token = new TuneToken();
        royaltyDistributor = new RoyaltyDistributor(address(token));
        nft = new MusicNFT("ipfs://baseuri/", address(token), address(royaltyDistributor));

        // Setup initial state
        token.transfer(FAN, 1_000_000 * 1e18);

        // Setup roles
        nft.grantRole(nft.MINTER_ROLE(), ADMIN);
        royaltyDistributor.grantRole(royaltyDistributor.DISTRIBUTOR_ROLE(), address(nft));

        // Set a low distribution threshold for testing
        royaltyDistributor.setDistributionThreshold(1);

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(nft.hasRole(nft.DEFAULT_ADMIN_ROLE(), ADMIN), true);
        assertEq(nft.hasRole(nft.MINTER_ROLE(), ADMIN), true);
        assertEq(nft.hasRole(nft.URI_SETTER_ROLE(), ADMIN), true);
    }

    function test_SupportsInterface() public view {
        assertTrue(nft.supportsInterface(type(IERC1155).interfaceId));
    }

    function test_CreateTrack() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](2);
        artists[0] = ADMIN;
        artists[1] = ARTIST;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 4000; // 40%
        shares[1] = 6000; // 60%

        uint256 tokenId = nft.createTrackWithCollaborators("ipfs://track1", artists, shares, INITIAL_SUPPLY, PRICE);

        (
            string memory uri,
            uint256 price,
            bool isActive,
            address[] memory collaborators,
            uint256[] memory royaltyShares,
            uint256 version,
            uint256 albumId
        ) = nft.getTrack(tokenId);

        assertEq(uri, "ipfs://track1");
        assertEq(price, PRICE);
        assertTrue(isActive);
        assertEq(collaborators.length, 2);
        assertEq(collaborators[0], ADMIN);
        assertEq(collaborators[1], ARTIST);
        assertEq(royaltyShares[0], 4000);
        assertEq(royaltyShares[1], 6000);
        assertEq(version, 1);
        assertEq(albumId, 0);
        vm.stopPrank();
    }

    function test_PurchaseTrack() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](1);
        artists[0] = ADMIN;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000; // 100% in basis points

        uint256 tokenId = nft.createTrackWithCollaborators(TRACK_URI, artists, shares, INITIAL_SUPPLY, PRICE);

        // Verify NFT was minted to ADMIN
        assertEq(nft.balanceOf(ADMIN, tokenId), INITIAL_SUPPLY);

        // Verify contract supports ERC1155Receiver
        assertTrue(nft.supportsInterface(type(IERC1155Receiver).interfaceId));

        // Transfer one NFT to the contract for sale
        nft.setApprovalForAll(address(nft), true);
        nft.safeTransferFrom(ADMIN, address(nft), tokenId, 1, "");

        // Verify transfer
        assertEq(nft.balanceOf(address(nft), tokenId), 1);
        assertEq(nft.balanceOf(ADMIN, tokenId), INITIAL_SUPPLY - 1);

        // Transfer some tokens to the contract for royalty payments
        token.transfer(address(nft), PRICE);
        vm.stopPrank();

        vm.startPrank(FAN);
        // Ensure FAN has enough tokens
        assertGe(token.balanceOf(FAN), PRICE, "FAN should have enough tokens");
        uint256 initialFanBalance = token.balanceOf(FAN);
        uint256 initialContractBalance = token.balanceOf(address(nft));

        token.approve(address(nft), PRICE);
        nft.purchaseTrack(tokenId);

        // Calculate expected balances
        uint256 expectedContractBalance = initialContractBalance + PRICE;

        // Verify token transfers
        assertEq(token.balanceOf(FAN), initialFanBalance - PRICE, "FAN balance not decreased correctly");
        assertEq(token.balanceOf(address(nft)), expectedContractBalance, "Contract balance not increased correctly");
        assertEq(nft.balanceOf(FAN, tokenId), 1, "NFT not transferred to FAN");
        assertEq(nft.balanceOf(address(nft), tokenId), 0, "NFT not removed from contract");
        vm.stopPrank();
    }

    function test_UpdateTrackUri() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        uint256 tokenId = nft.createTrackWithCollaborators(TRACK_URI, artists, shares, INITIAL_SUPPLY, PRICE);

        string memory newUri = "ipfs://newtrack";
        nft.updateTrackUri(tokenId, newUri);

        (string memory uri,,,,,,) = nft.getTrack(tokenId);
        assertEq(uri, newUri);
        vm.stopPrank();
    }

    function test_GetVersionHistory() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](1);
        artists[0] = ADMIN; // Set ADMIN as the creator
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        uint256 tokenId = nft.createTrackWithCollaborators(TRACK_URI, artists, shares, INITIAL_SUPPLY, PRICE);

        string memory newUri = "ipfs://newversion";
        string memory changelog = "Updated track";
        nft.updateTrackVersion(tokenId, newUri, changelog);

        MusicNFT.VersionInfo[] memory history = nft.getVersionHistory(tokenId);
        assertEq(history.length, 2);
        assertEq(history[0].uri, TRACK_URI);
        assertEq(history[0].changelog, "Initial version");
        assertEq(history[1].uri, newUri);
        assertEq(history[1].changelog, changelog);
        vm.stopPrank();
    }

    function testFail_UpdateTrackVersionNotCreator() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        uint256 tokenId = nft.createTrackWithCollaborators(TRACK_URI, artists, shares, INITIAL_SUPPLY, PRICE);
        vm.stopPrank();

        vm.startPrank(FAN);
        nft.updateTrackVersion(tokenId, "ipfs://newversion", "Updated track");
        vm.stopPrank();
    }

    function test_MetadataValidation() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        vm.expectRevert("URI cannot be empty");
        nft.createTrackWithCollaborators("", artists, shares, INITIAL_SUPPLY, PRICE);
        vm.stopPrank();
    }

    function test_MetadataUpdate() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        uint256 tokenId = nft.createTrackWithCollaborators(TRACK_URI, artists, shares, INITIAL_SUPPLY, PRICE);

        string memory newUri = "ipfs://QmNewTrackHash";
        nft.updateTrackUri(tokenId, newUri);

        (string memory uri,,,,,,) = nft.getTrack(tokenId);
        assertEq(uri, newUri);
        vm.stopPrank();
    }

    function test_PurchaseTrackWithRoyalty() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](2);
        artists[0] = ARTIST;
        artists[1] = address(0x123);
        uint256[] memory shares = new uint256[](2);
        shares[0] = 6000; // 60%
        shares[1] = 4000; // 40%

        uint256 tokenId = nft.createTrackWithCollaborators(TRACK_URI, artists, shares, INITIAL_SUPPLY, PRICE);

        // Verify NFT was minted to ADMIN
        assertEq(nft.balanceOf(ADMIN, tokenId), INITIAL_SUPPLY);

        // Register payees in RoyaltyDistributor with shares in 0-100 range
        uint256[] memory royaltyShares = new uint256[](2);
        royaltyShares[0] = 60; // 60%
        royaltyShares[1] = 40; // 40%
        royaltyDistributor.registerPayees(tokenId, artists, royaltyShares);

        // Verify contract supports ERC1155Receiver
        assertTrue(nft.supportsInterface(type(IERC1155Receiver).interfaceId));

        // Transfer one NFT to the contract for sale
        nft.setApprovalForAll(address(nft), true);
        nft.safeTransferFrom(ADMIN, address(nft), tokenId, 1, "");

        // Verify transfer
        assertEq(nft.balanceOf(address(nft), tokenId), 1);
        assertEq(nft.balanceOf(ADMIN, tokenId), INITIAL_SUPPLY - 1);

        // Transfer tokens to contracts for payments
        token.transfer(address(nft), PRICE);
        token.transfer(address(royaltyDistributor), PRICE);
        vm.stopPrank();

        vm.startPrank(FAN);
        // Ensure FAN has enough tokens
        assertGe(token.balanceOf(FAN), PRICE, "FAN should have enough tokens");
        uint256 initialFanBalance = token.balanceOf(FAN);
        uint256 initialContractBalance = token.balanceOf(address(nft));
        uint256 initialArtistBalance = token.balanceOf(ARTIST);

        token.approve(address(nft), PRICE);
        nft.purchaseTrack(tokenId);

        // Calculate expected balances
        uint256 royaltyAmount = (PRICE * 250) / 10_000; // 2.5% royalty
        uint256 artistShare = (royaltyAmount * 60) / 100; // 60% of royalty
        uint256 expectedContractBalance = initialContractBalance + PRICE;

        // Verify token transfers
        assertEq(token.balanceOf(FAN), initialFanBalance - PRICE, "FAN balance not decreased correctly");
        assertEq(token.balanceOf(address(nft)), expectedContractBalance, "Contract balance not increased correctly");
        assertEq(
            token.balanceOf(ARTIST) - initialArtistBalance, artistShare, "Artist royalty not transferred correctly"
        );
        assertEq(nft.balanceOf(FAN, tokenId), 1, "NFT not transferred to FAN");
        assertEq(nft.balanceOf(address(nft), tokenId), 0, "NFT not removed from contract");
        vm.stopPrank();
    }

    function testFail_PurchaseTrackInsufficientPayment() public {
        vm.startPrank(ADMIN);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        uint256 tokenId = nft.createTrackWithCollaborators(TRACK_URI, artists, shares, INITIAL_SUPPLY, PRICE);
        vm.stopPrank();

        vm.startPrank(FAN);
        token.approve(address(nft), PRICE - 1);
        nft.purchaseTrack(tokenId);
        vm.stopPrank();
    }
}
