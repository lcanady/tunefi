// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Marketplace.sol";
import "../src/MusicNFT.sol";
import "../src/TuneToken.sol";
import "../src/RoyaltyDistributor.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MarketplaceTest is Test, ERC1155Holder {
    Marketplace public marketplace;
    MusicNFT public nft;
    TuneToken public token;
    RoyaltyDistributor public royaltyDistributor;

    address public constant ADMIN = address(1);
    address public constant SELLER = address(2);
    address public constant BUYER = address(3);
    uint256 public TOKEN_ID;
    uint256 public TOKEN_ID_2;
    uint256 public constant PRICE = 100 * 1e18;
    uint256 public constant PLATFORM_FEE = 250; // 2.5%

    function setUp() public {
        vm.startPrank(ADMIN);

        // Deploy contracts
        token = new TuneToken();
        royaltyDistributor = new RoyaltyDistributor(address(token));
        nft = new MusicNFT("ipfs://baseuri/", address(token), address(royaltyDistributor));
        marketplace = new Marketplace(address(nft), address(token));

        // Setup initial state
        token.transfer(BUYER, 1_000_000 * 1e18);
        token.transfer(SELLER, 1_000_000 * 1e18);
        token.transfer(address(marketplace), 1_000_000 * 1e18); // For handling royalties

        // Setup roles
        nft.grantRole(nft.DEFAULT_ADMIN_ROLE(), ADMIN);
        nft.grantRole(nft.MINTER_ROLE(), SELLER);
        nft.grantRole(nft.URI_SETTER_ROLE(), SELLER);
        royaltyDistributor.grantRole(royaltyDistributor.DISTRIBUTOR_ROLE(), address(nft));
        royaltyDistributor.grantRole(royaltyDistributor.ADMIN_ROLE(), SELLER);

        vm.stopPrank();

        // Create tracks as SELLER
        vm.startPrank(SELLER);

        address[] memory artists = new address[](1);
        artists[0] = SELLER;
        uint256[] memory nftShares = new uint256[](1);
        nftShares[0] = 10_000; // 100% in basis points for MusicNFT

        // Create first track
        uint256 tokenId1 = nft.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            nftShares,
            1, // Only mint 1 token for marketplace testing
            PRICE
        );

        // Create second track for batch operations
        uint256 tokenId2 = nft.createTrackWithCollaborators(
            "ipfs://metadata2",
            artists,
            nftShares,
            1, // Only mint 1 token for marketplace testing
            PRICE * 2
        );

        // Register payees for royalties
        uint256[] memory royaltyShares = new uint256[](1);
        royaltyShares[0] = 100; // 100% in percentage for RoyaltyDistributor
        royaltyDistributor.registerPayees(tokenId1, artists, royaltyShares);
        royaltyDistributor.registerPayees(tokenId2, artists, royaltyShares);

        // Approve marketplace to handle NFTs
        nft.setApprovalForAll(address(marketplace), true);

        // Verify NFT ownership
        assertEq(nft.balanceOf(SELLER, tokenId1), 1, "SELLER should own first NFT");
        assertEq(nft.balanceOf(SELLER, tokenId2), 1, "SELLER should own second NFT");

        // Store token IDs for tests
        TOKEN_ID = tokenId1;
        TOKEN_ID_2 = tokenId2;

        vm.stopPrank();

        // Approve marketplace to handle tokens
        vm.prank(BUYER);
        token.approve(address(marketplace), type(uint256).max);
    }

    function test_ListToken() public {
        vm.startPrank(SELLER);
        marketplace.listToken(TOKEN_ID, PRICE);

        Marketplace.Listing memory listing = marketplace.getListing(TOKEN_ID);
        assertEq(listing.price, PRICE);
        assertEq(listing.seller, SELLER);
        assertTrue(listing.active);
        vm.stopPrank();
    }

    function testFail_ListTokenNotOwner() public {
        vm.prank(BUYER);
        marketplace.listToken(TOKEN_ID, PRICE);
    }

    function test_DelistToken() public {
        vm.startPrank(SELLER);
        marketplace.listToken(TOKEN_ID, PRICE);
        marketplace.delistToken(TOKEN_ID);

        Marketplace.Listing memory listing = marketplace.getListing(TOKEN_ID);
        assertFalse(listing.active);
        vm.stopPrank();
    }

    function testFail_DelistTokenNotSeller() public {
        vm.startPrank(SELLER);
        marketplace.listToken(TOKEN_ID, PRICE);
        vm.stopPrank();

        vm.prank(BUYER);
        marketplace.delistToken(TOKEN_ID);
    }

    function test_BuyToken() public {
        vm.startPrank(SELLER);
        marketplace.listToken(TOKEN_ID, PRICE);
        vm.stopPrank();

        uint256 platformFee = (PRICE * PLATFORM_FEE) / 10_000;
        uint256 royaltyAmount = (PRICE * 250) / 10_000; // 2.5% royalty
        uint256 sellerAmount = PRICE - platformFee - royaltyAmount;

        vm.prank(BUYER);
        marketplace.buyToken(TOKEN_ID);

        // Check NFT transfer
        assertEq(nft.balanceOf(BUYER, TOKEN_ID), 1, "NFT not transferred to buyer");
        assertEq(nft.balanceOf(address(marketplace), TOKEN_ID), 0, "NFT still in marketplace");

        // Check revenue distribution
        assertEq(marketplace.pendingRevenue(SELLER), sellerAmount + royaltyAmount, "Incorrect total seller revenue"); // SELLER gets both seller revenue and royalties
        assertEq(marketplace.pendingRevenue(ADMIN), platformFee, "Incorrect platform fee");

        // Check listing state
        assertFalse(marketplace.getListing(TOKEN_ID).active, "Listing should be inactive");
    }

    function testFail_BuyTokenNotListed() public {
        vm.prank(BUYER);
        marketplace.buyToken(TOKEN_ID);
    }

    function test_BatchList() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = TOKEN_ID;
        tokenIds[1] = TOKEN_ID_2;
        uint256[] memory prices = new uint256[](2);
        prices[0] = PRICE;
        prices[1] = PRICE * 2;

        // Verify initial ownership
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(nft.balanceOf(SELLER, tokenIds[i]), 1, "SELLER should own NFT initially");
        }

        vm.startPrank(SELLER);
        marketplace.batchList(tokenIds, prices);

        // Verify listings and transfers
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Marketplace.Listing memory listing = marketplace.getListing(tokenIds[i]);
            assertEq(listing.price, prices[i], "Incorrect listing price");
            assertEq(listing.seller, SELLER, "Incorrect seller");
            assertTrue(listing.active, "Listing should be active");
            assertEq(nft.balanceOf(address(marketplace), tokenIds[i]), 1, "NFT not transferred to marketplace");
            assertEq(nft.balanceOf(SELLER, tokenIds[i]), 0, "NFT still owned by SELLER");
        }
        vm.stopPrank();
    }

    function test_BatchDelist() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = TOKEN_ID;
        tokenIds[1] = TOKEN_ID_2;
        uint256[] memory prices = new uint256[](2);
        prices[0] = PRICE;
        prices[1] = PRICE * 2;

        vm.startPrank(SELLER);

        // First list the tokens
        marketplace.batchList(tokenIds, prices);

        // Verify initial state
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertTrue(marketplace.getListing(tokenIds[i]).active, "Listing should be active initially");
            assertEq(nft.balanceOf(address(marketplace), tokenIds[i]), 1, "NFT should be in marketplace");
            assertEq(nft.balanceOf(SELLER, tokenIds[i]), 0, "NFT should not be with SELLER");
        }

        // Now delist them
        marketplace.batchDelist(tokenIds);

        // Verify final state
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertFalse(marketplace.getListing(tokenIds[i]).active, "Listing should be inactive");
            assertEq(nft.balanceOf(SELLER, tokenIds[i]), 1, "NFT not returned to seller");
            assertEq(nft.balanceOf(address(marketplace), tokenIds[i]), 0, "NFT still in marketplace");
        }
        vm.stopPrank();
    }

    function test_ClaimRevenue() public {
        // First list and sell a token
        vm.startPrank(SELLER);
        marketplace.listToken(TOKEN_ID, PRICE);
        vm.stopPrank();

        vm.prank(BUYER);
        marketplace.buyToken(TOKEN_ID);

        uint256 platformFee = (PRICE * PLATFORM_FEE) / 10_000;
        uint256 royaltyAmount = (PRICE * 250) / 10_000; // 2.5% royalty
        uint256 sellerAmount = PRICE - platformFee - royaltyAmount;

        // Verify initial pending revenue
        assertEq(marketplace.pendingRevenue(ADMIN), platformFee, "Incorrect platform fee");
        assertEq(marketplace.pendingRevenue(SELLER), sellerAmount + royaltyAmount, "Incorrect total seller revenue"); // SELLER gets both seller revenue and royalties

        // Claim revenue as ADMIN
        uint256 initialAdminBalance = token.balanceOf(ADMIN);
        vm.prank(ADMIN);
        marketplace.claimRevenue();
        assertEq(token.balanceOf(ADMIN), initialAdminBalance + platformFee, "Admin didn't receive platform fee");
        assertEq(marketplace.pendingRevenue(ADMIN), 0, "Admin pending revenue not cleared");

        // Claim revenue as SELLER
        uint256 initialSellerBalance = token.balanceOf(SELLER);
        vm.prank(SELLER);
        marketplace.claimRevenue();
        assertEq(
            token.balanceOf(SELLER),
            initialSellerBalance + sellerAmount + royaltyAmount,
            "Seller didn't receive revenue and royalties"
        );
        assertEq(marketplace.pendingRevenue(SELLER), 0, "Seller pending revenue not cleared");
    }

    function test_UpdatePlatformFee() public {
        uint256 newFee = 500; // 5%

        vm.prank(ADMIN);
        marketplace.updatePlatformFee(newFee);

        assertEq(marketplace.platformFee(), newFee);
    }

    function testFail_UpdatePlatformFeeUnauthorized() public {
        uint256 newFee = 500;

        vm.prank(SELLER);
        marketplace.updatePlatformFee(newFee);
    }

    function test_PauseUnpause() public {
        vm.startPrank(ADMIN);
        marketplace.pause();
        assertTrue(marketplace.paused());

        marketplace.unpause();
        assertFalse(marketplace.paused());
        vm.stopPrank();
    }

    function testFail_PauseUnauthorized() public {
        vm.prank(SELLER);
        marketplace.pause();
    }
}
