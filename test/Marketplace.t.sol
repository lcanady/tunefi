// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Marketplace.sol";
import "../src/MusicNFT.sol";
import "../src/TuneToken.sol";

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    MusicNFT public nft;
    TuneToken public token;
    
    address public admin;
    address public seller;
    address public buyer;
    address public artist;
    
    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18; // 1M tokens
    uint256 constant LISTING_PRICE = 100 * 10**18; // 100 tokens
    uint256 constant MIN_STAKE = 100 * 10**18; // 100 tokens
    uint256 constant PLATFORM_FEE = 250; // 2.5%
    uint256 constant ROYALTY_RATE = 1000; // 10%
    uint256 constant NFT_PRICE = 1 ether;
    uint256 constant INITIAL_NFT_SUPPLY = 1;
    uint256 constant ALBUM_PRICE = 2 ether;
    uint256 constant ALBUM_DISCOUNT = 1000; // 10% discount
    
    uint256 public tokenId;
    
    function setUp() public {
        admin = address(this);
        seller = address(0x1);
        buyer = address(0x2);
        artist = address(0x3);
        
        // Deploy contracts
        token = new TuneToken(INITIAL_SUPPLY * 2); // Double supply to cover both users
        nft = new MusicNFT();
        marketplace = new Marketplace(
            address(nft),
            address(token),
            PLATFORM_FEE
        );
        
        // Transfer tokens to users
        token.transfer(seller, INITIAL_SUPPLY);
        token.transfer(buyer, INITIAL_SUPPLY);
        
        // Create track with royalty
        address[] memory artists = new address[](2);
        artists[0] = seller; // First artist must be the creator
        artists[1] = artist;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 5000; // 50% share to seller
        shares[1] = 5000; // 50% share to artist
        
        // Mint NFT to seller
        vm.startPrank(seller);
        tokenId = nft.createTrackWithCollaborators(
            "ipfs://test",
            artists,
            shares,
            INITIAL_NFT_SUPPLY,
            NFT_PRICE
        );
        
        // Create album
        uint256[] memory trackIds = new uint256[](1);
        trackIds[0] = tokenId;
        nft.createAlbum("ipfs://album", trackIds, ALBUM_PRICE, ALBUM_DISCOUNT);
        
        // Approve marketplace
        nft.setApprovalForAll(address(marketplace), true);
        token.approve(address(marketplace), type(uint256).max);
        vm.stopPrank();
        
        // Approve marketplace for buyer
        vm.startPrank(buyer);
        token.approve(address(marketplace), type(uint256).max);
        vm.stopPrank();
    }
    
    function test_InitialState() public view {
        assertEq(address(marketplace.nftContract()), address(nft));
        assertEq(address(marketplace.paymentToken()), address(token));
        assertEq(marketplace.platformFee(), PLATFORM_FEE);
    }
    
    function test_ListToken() public {
        uint256 initialSellerBalance = nft.balanceOf(seller, tokenId);
        
        vm.prank(seller);
        marketplace.listToken(tokenId, LISTING_PRICE);
        
        Marketplace.Listing memory listing = marketplace.getListing(tokenId);
        assertTrue(listing.active);
        assertEq(listing.seller, seller);
        assertEq(listing.price, LISTING_PRICE);
        assertEq(nft.balanceOf(address(marketplace), tokenId), 1);
        assertEq(nft.balanceOf(seller, tokenId), initialSellerBalance - 1);
    }
    
    function test_DelistToken() public {
        uint256 initialSellerBalance = nft.balanceOf(seller, tokenId);
        
        vm.startPrank(seller);
        marketplace.listToken(tokenId, LISTING_PRICE);
        marketplace.delistToken(tokenId);
        vm.stopPrank();
        
        Marketplace.Listing memory listing = marketplace.getListing(tokenId);
        assertFalse(listing.active);
        assertEq(nft.balanceOf(seller, tokenId), initialSellerBalance);
        assertEq(nft.balanceOf(address(marketplace), tokenId), 0);
    }
    
    function test_BuyToken() public {
        // List token
        vm.prank(seller);
        marketplace.listToken(tokenId, LISTING_PRICE);
        
        uint256 initialTokenSellerBalance = token.balanceOf(seller);
        uint256 initialTokenBuyerBalance = token.balanceOf(buyer);
        
        // Buy token
        vm.prank(buyer);
        marketplace.buyToken(tokenId);
        
        // Calculate expected amounts
        uint256 platformAmount = (LISTING_PRICE * PLATFORM_FEE) / 10000;
        (uint256 royaltyAmount, address royaltyRecipient) = marketplace.calculateRoyalty(tokenId, LISTING_PRICE);
        uint256 sellerAmount = LISTING_PRICE - platformAmount - royaltyAmount;
        
        // Check balances
        assertEq(token.balanceOf(seller), initialTokenSellerBalance);
        assertEq(token.balanceOf(buyer), initialTokenBuyerBalance - LISTING_PRICE);
        assertEq(marketplace.pendingRevenue(seller), sellerAmount);
        assertEq(marketplace.pendingRevenue(royaltyRecipient), royaltyAmount);
        assertEq(marketplace.pendingRevenue(admin), platformAmount);
        assertEq(nft.balanceOf(buyer, tokenId), 1);
        assertEq(nft.balanceOf(address(marketplace), tokenId), 0);
    }
    
    function test_MakeAndAcceptOffer() public {
        uint256 initialSellerBalance = nft.balanceOf(seller, tokenId);
        uint256 offerPrice = LISTING_PRICE * 2;
        uint256 duration = 7 days;
        
        // Make offer
        vm.prank(buyer);
        marketplace.makeOffer(tokenId, offerPrice, duration);
        
        Marketplace.Offer[] memory offers = marketplace.getOffers(tokenId);
        assertEq(offers.length, 1);
        assertEq(offers[0].buyer, buyer);
        assertEq(offers[0].price, offerPrice);
        
        // Accept offer
        vm.prank(seller);
        marketplace.acceptOffer(tokenId, 0);
        
        // Calculate expected amounts
        uint256 platformAmount = (offerPrice * PLATFORM_FEE) / 10000;
        (uint256 royaltyAmount, address royaltyRecipient) = marketplace.calculateRoyalty(tokenId, offerPrice);
        uint256 sellerAmount = offerPrice - platformAmount - royaltyAmount;
        
        // Check results
        assertEq(nft.balanceOf(buyer, tokenId), 1);
        assertEq(nft.balanceOf(seller, tokenId), initialSellerBalance - 1);
        assertEq(marketplace.pendingRevenue(seller), sellerAmount);
        assertEq(marketplace.pendingRevenue(royaltyRecipient), royaltyAmount);
        assertEq(marketplace.pendingRevenue(admin), platformAmount);
    }
    
    function test_CancelOffer() public {
        uint256 offerPrice = LISTING_PRICE * 2;
        uint256 duration = 7 days;
        
        // Make and cancel offer
        vm.startPrank(buyer);
        marketplace.makeOffer(tokenId, offerPrice, duration);
        marketplace.cancelOffer(tokenId, 0);
        vm.stopPrank();
        
        Marketplace.Offer[] memory offers = marketplace.getOffers(tokenId);
        assertEq(offers.length, 0);
    }
    
    function test_ClaimRevenue() public {
        // List and buy token to generate revenue
        vm.prank(seller);
        marketplace.listToken(tokenId, LISTING_PRICE);
        
        vm.prank(buyer);
        marketplace.buyToken(tokenId);
        
        uint256 initialBalance = token.balanceOf(seller);
        uint256 pendingAmount = marketplace.pendingRevenue(seller);
        
        // Claim revenue
        vm.prank(seller);
        marketplace.claimRevenue();
        
        assertEq(token.balanceOf(seller), initialBalance + pendingAmount);
        assertEq(marketplace.pendingRevenue(seller), 0);
    }
    
    function test_UpdatePlatformFee() public {
        uint256 newFee = 500; // 5%
        
        vm.prank(admin);
        marketplace.setPlatformFee(newFee);
        
        assertEq(marketplace.platformFee(), newFee);
    }
    
    function test_PauseAndUnpause() public {
        // List token
        vm.prank(seller);
        marketplace.listToken(tokenId, LISTING_PRICE);
        
        // Pause contract
        vm.prank(admin);
        marketplace.pause();
        
        // Try to buy token (should fail)
        bytes4 selector = bytes4(keccak256("EnforcedPause()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        vm.prank(buyer);
        marketplace.buyToken(tokenId);
        
        // Unpause contract
        vm.prank(admin);
        marketplace.unpause();
        
        // Buy token (should succeed)
        vm.prank(buyer);
        marketplace.buyToken(tokenId);
        
        assertEq(nft.balanceOf(buyer, tokenId), 1);
        assertEq(nft.balanceOf(address(marketplace), tokenId), 0);
    }
    
    function testFail_ListTokenNotOwner() public {
        vm.prank(buyer);
        marketplace.listToken(tokenId, LISTING_PRICE);
    }
    
    function testFail_DelistTokenNotSeller() public {
        vm.prank(seller);
        marketplace.listToken(tokenId, LISTING_PRICE);
        
        vm.prank(buyer);
        marketplace.delistToken(tokenId);
    }
    
    function testFail_BuyTokenNotListed() public {
        vm.prank(buyer);
        marketplace.buyToken(tokenId);
    }
    
    function testFail_MakeOfferInvalidPrice() public {
        vm.prank(buyer);
        marketplace.makeOffer(tokenId, 0, 7 days);
    }
    
    function testFail_CancelOfferNotCreator() public {
        vm.prank(buyer);
        marketplace.makeOffer(tokenId, LISTING_PRICE, 7 days);
        
        vm.prank(seller);
        marketplace.cancelOffer(tokenId, 0);
    }
    
    function testFail_AcceptOfferNotOwner() public {
        vm.prank(buyer);
        marketplace.makeOffer(tokenId, LISTING_PRICE, 7 days);
        
        vm.prank(buyer);
        marketplace.acceptOffer(tokenId, 0);
    }
    
    function testFail_ClaimRevenueNoBalance() public {
        vm.prank(buyer);
        marketplace.claimRevenue();
    }
    
    function testFail_UpdatePlatformFeeNotOwner() public {
        vm.prank(buyer);
        marketplace.setPlatformFee(500);
    }
}
