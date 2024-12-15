// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MusicNFT.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MusicNFTTest is Test, ERC1155Holder {
    MusicNFT public nft;
    
    // Test data
    address constant ADMIN = address(0x1);
    address constant ARTIST = address(0x2);
    address constant FAN = address(0x3);
    string constant TRACK_URI = "ipfs://QmTrackHash";
    uint256 constant INITIAL_SUPPLY = 100;
    uint256 constant PRICE = 0.1 ether;
    uint96 constant DEFAULT_ROYALTY_FEE = 250; // 2.5%
    uint96 constant ROYALTY_FEE = 250; // 2.5%
    
    receive() external payable {}
    
    function setUp() public {
        vm.prank(ADMIN);
        nft = new MusicNFT();
    }

    // ERC-1155 Compliance Tests
    function test_InitialState() public view {
        assertEq(nft.owner(), ADMIN);
    }

    function test_SupportsInterface() public view {
        assertTrue(nft.supportsInterface(type(IERC1155).interfaceId));
        assertTrue(nft.supportsInterface(type(IERC2981).interfaceId));
    }

    function test_CreateTrack() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        
        (
            string memory uri,
            uint256 price,
            address[] memory trackArtists,
            uint256[] memory royaltyShares,
            bool exists,
            uint256 version,
            uint256 albumId
        ) = nft.getTrack(tokenId);
        
        assertEq(uri, TRACK_URI);
        assertEq(price, PRICE);
        assertTrue(exists);
        assertEq(trackArtists[0], ARTIST);
        assertEq(royaltyShares[0], 10000);
        assertEq(version, 1);
        assertEq(albumId, 0);
        assertEq(nft.balanceOf(ARTIST, tokenId), INITIAL_SUPPLY);
        
        vm.stopPrank();
    }

    function test_BatchMint() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        string[] memory uris = new string[](2);
        uris[0] = TRACK_URI;
        uris[1] = "ipfs://QmTrack2Hash";
        
        uint256[] memory supplies = new uint256[](2);
        supplies[0] = INITIAL_SUPPLY;
        supplies[1] = INITIAL_SUPPLY * 2;
        
        uint256[] memory prices = new uint256[](2);
        prices[0] = PRICE;
        prices[1] = PRICE * 2;
        
        uint256[] memory tokenIds = new uint256[](2);
        
        for (uint256 i = 0; i < 2; i++) {
            tokenIds[i] = nft.createTrackWithCollaborators(
                uris[i],
                artists,
                shares,
                supplies[i],
                prices[i]
            );
        }
        
        for (uint256 i = 0; i < 2; i++) {
            (
                string memory uri,
                uint256 price,
                address[] memory trackArtists,
                ,
                bool exists,
                ,
                
            ) = nft.getTrack(tokenIds[i]);
            assertEq(uri, uris[i]);
            assertEq(price, prices[i]);
            assertTrue(exists);
            assertEq(trackArtists[0], ARTIST);
            assertEq(nft.balanceOf(ARTIST, tokenIds[i]), supplies[i]);
        }
        
        vm.stopPrank();
    }

    function test_MetadataValidation() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        vm.expectRevert("Invalid URI");
        nft.createTrackWithCollaborators("", artists, shares, INITIAL_SUPPLY, PRICE);
        vm.stopPrank();
    }

    function test_MetadataUpdate() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        
        string memory newUri = "ipfs://QmNewTrackHash";
        nft.updateTrackUri(tokenId, newUri);
        
        (string memory uri, , , , , , ) = nft.getTrack(tokenId);
        assertEq(uri, newUri);
        
        vm.stopPrank();
    }

    function test_PurchaseTrackWithRoyalty() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        vm.stopPrank();

        vm.startPrank(FAN);
        vm.deal(FAN, PRICE);
        
        uint256 initialArtistBalance = ARTIST.balance;
        nft.purchaseTrack{value: PRICE}(tokenId, 1);
        
        uint256 royalty = (PRICE * 250) / 10000; // 2.5% royalty
        uint256 artistPayment = PRICE - royalty;
        
        assertEq(ARTIST.balance - initialArtistBalance, artistPayment);
        assertEq(nft.balanceOf(FAN, tokenId), 1);
        
        vm.stopPrank();
    }

    function testFail_UnauthorizedMetadataUpdate() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        vm.stopPrank();

        vm.startPrank(FAN);
        nft.updateTrackUri(tokenId, "ipfs://QmNewTrackHash");
        vm.stopPrank();
    }

    function testFail_PurchaseTrackInsufficientFunds() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        vm.stopPrank();

        vm.startPrank(FAN);
        vm.deal(FAN, PRICE / 2);
        nft.purchaseTrack{value: PRICE / 2}(tokenId, 1);
        vm.stopPrank();
    }

    function test_CreateTrackWithCollaborators() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](2);
        artists[0] = ARTIST;
        artists[1] = address(0x123);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 7000; // 70%
        shares[1] = 3000; // 30%
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        
        (
            string memory uri,
            uint256 price,
            address[] memory trackArtists,
            uint256[] memory royaltyShares,
            bool exists,
            uint256 version,
            uint256 albumId
        ) = nft.getTrack(tokenId);
        
        assertEq(uri, TRACK_URI);
        assertEq(price, PRICE);
        assertTrue(exists);
        assertEq(trackArtists[0], ARTIST);
        assertEq(trackArtists[1], address(0x123));
        assertEq(royaltyShares[0], 7000);
        assertEq(royaltyShares[1], 3000);
        assertEq(version, 1);
        assertEq(albumId, 0);
        
        vm.stopPrank();
    }

    function test_CreateAndPurchaseAlbum() public {
        // Create tracks first
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 trackId1 = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        uint256 trackId2 = nft.createTrackWithCollaborators(
            "track2.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        uint256[] memory trackIds = new uint256[](2);
        trackIds[0] = trackId1;
        trackIds[1] = trackId2;

        uint256 albumPrice = 1.8 ether;
        uint256 discountBps = 1000; // 10% discount

        uint256 albumId = nft.createAlbum(
            "album.json",
            trackIds,
            albumPrice,
            discountBps
        );

        // Purchase album
        address buyer = address(0x1);
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        uint256 discountedPrice = (albumPrice * (10000 - discountBps)) / 10000;
        nft.purchaseAlbum{value: discountedPrice}(albumId);

        // Verify ownership
        assertEq(nft.ownerOf(albumId), buyer);
        assertEq(nft.balanceOf(buyer, trackId1), 1);
        assertEq(nft.balanceOf(buyer, trackId2), 1);
    }

    function test_UpdateTrackVersion() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        
        string memory newUri = "ipfs://QmNewTrackHash";
        string memory changelog = "Updated track metadata";
        nft.updateTrackVersion(tokenId, newUri, changelog);
        
        (string memory uri, , , , , uint256 version, ) = nft.getTrack(tokenId);
        assertEq(uri, newUri);
        assertEq(version, 2);
        
        vm.stopPrank();
    }

    function test_DistributeRoyalties() public {
        vm.startPrank(ARTIST);
        
        address collaborator = address(0x123);
        address[] memory artists = new address[](2);
        artists[0] = ARTIST;
        artists[1] = collaborator;
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 6000; // 60%
        shares[1] = 4000; // 40%
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        
        vm.stopPrank();
        
        // Purchase track as fan
        vm.startPrank(FAN);
        vm.deal(FAN, PRICE);
        nft.purchaseTrack{value: PRICE}(tokenId, 1);
        vm.stopPrank();
        
        // Get initial balances
        uint256 initialArtistBalance = ARTIST.balance;
        uint256 initialCollaboratorBalance = collaborator.balance;
        
        // Distribute royalties
        vm.prank(ARTIST);
        nft.distributeRoyalties(tokenId);
        
        // Verify royalty distribution
        uint256 royalty = (PRICE * 250) / 10000; // 2.5% royalty
        assertEq(ARTIST.balance - initialArtistBalance, (royalty * 6000) / 10000);
        assertEq(collaborator.balance - initialCollaboratorBalance, (royalty * 4000) / 10000);
    }

    function test_RoyaltyInfo() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        
        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, PRICE);
        assertEq(receiver, address(nft)); // Contract is set as royalty receiver
        assertEq(royaltyAmount, (PRICE * DEFAULT_ROYALTY_FEE) / 10000);
        vm.stopPrank();
    }

    function test_SafeTransfer() public {
        vm.startPrank(ARTIST);
        
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId = nft.createTrackWithCollaborators(
            TRACK_URI,
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        
        nft.safeTransferFrom(ARTIST, FAN, tokenId, 1, "");
        
        assertEq(nft.balanceOf(FAN, tokenId), 1);
        assertEq(nft.balanceOf(ARTIST, tokenId), INITIAL_SUPPLY - 1);
        vm.stopPrank();
    }

    function test_CreateAlbumWithDiscount() public {
        // Create tracks first
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 trackId1 = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        uint256 trackId2 = nft.createTrackWithCollaborators(
            "track2.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        uint256[] memory trackIds = new uint256[](2);
        trackIds[0] = trackId1;
        trackIds[1] = trackId2;

        uint256 albumPrice = 1.8 ether; // 10% less than buying tracks separately
        uint256 discountBps = 1000; // 10% discount

        uint256 albumId = nft.createAlbum(
            "album.json",
            trackIds,
            albumPrice,
            discountBps
        );
        
        (string memory uri, uint256 price, uint256[] memory ids, uint256 discount) = nft.getAlbum(albumId);
        
        assertEq(uri, "album.json");
        assertEq(price, albumPrice);
        assertEq(ids.length, 2);
        assertEq(ids[0], trackId1);
        assertEq(ids[1], trackId2);
        assertEq(discount, discountBps);
    }

    function test_PurchaseAlbumWithDiscount() public {
        // Create tracks first
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 trackId1 = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        uint256 trackId2 = nft.createTrackWithCollaborators(
            "track2.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        uint256[] memory trackIds = new uint256[](2);
        trackIds[0] = trackId1;
        trackIds[1] = trackId2;

        uint256 albumPrice = 1.8 ether;
        uint256 discountBps = 1000; // 10% discount
        uint256 albumId = nft.createAlbum(
            "album.json",
            trackIds,
            albumPrice,
            discountBps
        );

        // Calculate discounted price
        uint256 discountedPrice = (albumPrice * (10000 - discountBps)) / 10000;
        
        address buyer = address(0x1);
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        nft.purchaseAlbum{value: discountedPrice}(albumId);

        // Verify buyer received album and tracks
        assertEq(nft.balanceOf(buyer, albumId), 1);
        assertEq(nft.balanceOf(buyer, trackId1), 1);
        assertEq(nft.balanceOf(buyer, trackId2), 1);
    }

    function test_UpdateAlbumUri() public {
        // Create tracks first
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 trackId1 = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        uint256[] memory trackIds = new uint256[](1);
        trackIds[0] = trackId1;

        uint256 albumId = nft.createAlbum(
            "album.json",
            trackIds,
            1 ether,
            0
        );
        
        // Update album URI
        nft.updateAlbumUri(albumId, "new_album.json");
        
        (string memory uri,,, ) = nft.getAlbum(albumId);
        assertEq(uri, "new_album.json");
    }

    function testFail_UpdateAlbumUriUnauthorized() public {
        // Create tracks first
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 trackId1 = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        uint256[] memory trackIds = new uint256[](1);
        trackIds[0] = trackId1;

        uint256 albumId = nft.createAlbum(
            "album.json",
            trackIds,
            1 ether,
            0
        );
        
        // Try to update album URI from unauthorized address
        vm.prank(address(0x1));
        nft.updateAlbumUri(albumId, "new_album.json");
    }

    function test_CreateAndPurchaseLicense() public {
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 tokenId = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        // Create commercial license
        uint256 licensePrice = 0.5 ether;
        nft.createLicense(tokenId, MusicNFT.LicenseType.Commercial, licensePrice);

        // Purchase license as fan
        address buyer = address(0x1);
        vm.deal(buyer, licensePrice);
        vm.prank(buyer);
        nft.purchaseLicense{value: licensePrice}(tokenId, MusicNFT.LicenseType.Commercial);

        // Verify license
        assertTrue(nft.hasLicense(tokenId, MusicNFT.LicenseType.Commercial, buyer));
    }

    function test_TrackVersionHistory() public {
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 tokenId = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        // Update track version
        nft.updateTrackVersion(tokenId, "track1_v2.json", "Added bass line");
        nft.updateTrackVersion(tokenId, "track1_v3.json", "Added vocals");

        // Get version history
        MusicNFT.VersionInfo[] memory history = nft.getVersionHistory(tokenId);
        
        assertEq(history.length, 2);
        assertEq(history[0].version, 2);
        assertEq(history[0].uri, "track1_v2.json");
        assertEq(history[0].changelog, "Added bass line");
        assertEq(history[1].version, 3);
        assertEq(history[1].uri, "track1_v3.json");
        assertEq(history[1].changelog, "Added vocals");
    }

    function test_CreateBatchAlbums() public {
        // Create tracks first
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 trackId1 = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        uint256 trackId2 = nft.createTrackWithCollaborators(
            "track2.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );
        uint256 trackId3 = nft.createTrackWithCollaborators(
            "track3.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        // Prepare batch album creation data
        string[] memory albumUris = new string[](2);
        albumUris[0] = "album1.json";
        albumUris[1] = "album2.json";

        uint256[][] memory trackIdArrays = new uint256[][](2);
        trackIdArrays[0] = new uint256[](2);
        trackIdArrays[0][0] = trackId1;
        trackIdArrays[0][1] = trackId2;
        trackIdArrays[1] = new uint256[](1);
        trackIdArrays[1][0] = trackId3;

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1.8 ether;
        prices[1] = 1 ether;

        uint256[] memory discounts = new uint256[](2);
        discounts[0] = 1000; // 10% discount
        discounts[1] = 500;  // 5% discount

        uint256[] memory albumIds = nft.createBatchAlbums(
            albumUris,
            trackIdArrays,
            prices,
            discounts
        );

        assertEq(albumIds.length, 2);

        // Verify first album
        (string memory uri1, uint256 price1, uint256[] memory tracks1, uint256 discount1) = nft.getAlbum(albumIds[0]);
        assertEq(uri1, "album1.json");
        assertEq(price1, 1.8 ether);
        assertEq(tracks1.length, 2);
        assertEq(tracks1[0], trackId1);
        assertEq(tracks1[1], trackId2);
        assertEq(discount1, 1000);

        // Verify second album
        (string memory uri2, uint256 price2, uint256[] memory tracks2, uint256 discount2) = nft.getAlbum(albumIds[1]);
        assertEq(uri2, "album2.json");
        assertEq(price2, 1 ether);
        assertEq(tracks2.length, 1);
        assertEq(tracks2[0], trackId3);
        assertEq(discount2, 500);
    }

    function testFail_CreateInvalidLicense() public {
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 tokenId = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        // Try to create license as non-creator
        vm.prank(address(0x1));
        nft.createLicense(tokenId, MusicNFT.LicenseType.Commercial, 0.5 ether);
    }

    function testFail_PurchaseInactiveLicense() public {
        address[] memory artists = new address[](1);
        artists[0] = address(this);
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;

        uint256 tokenId = nft.createTrackWithCollaborators(
            "track1.json",
            artists,
            shares,
            INITIAL_SUPPLY,
            PRICE
        );

        // Try to purchase a license that hasn't been created
        vm.deal(address(0x1), 1 ether);
        vm.prank(address(0x1));
        nft.purchaseLicense{value: 1 ether}(tokenId, MusicNFT.LicenseType.Commercial);
    }
}