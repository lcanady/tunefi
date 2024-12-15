// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title MusicNFT
/// @notice This contract handles the creation and trading of music NFTs
/// @dev Implements ERC1155 for semi-fungible music tracks with royalty support
contract MusicNFT is ERC1155, ERC1155Supply, ERC2981, Ownable {
    // Track details
    struct Track {
        string uri;
        uint256 price;
        address[] artists; // Multiple artists for collaboration
        uint256[] royaltyShares; // Corresponding royalty shares for each artist
        bool exists;
        uint256 version; // Track version number
        uint256 albumId; // ID of the album this track belongs to (0 if not part of album)
        mapping(LicenseType => License) licenses;
        mapping(LicenseType => mapping(address => bool)) licensePurchases;
        VersionInfo[] versionHistory;
    }

    // Album details
    struct Album {
        string uri;
        uint256 price; // Price for the full album (should be less than sum of individual tracks)
        uint256[] trackIds;
        address creator;
        bool exists;
        uint256 discountBps; // Discount in basis points (1/100th of a percent)
    }

    // License types
    enum LicenseType { NonCommercial, Commercial, Unlimited }

    struct License {
        LicenseType licenseType;
        uint256 price;
        bool active;
    }

    struct VersionInfo {
        uint256 version;
        string uri;
        string changelog;
        uint256 timestamp;
    }

    // Mapping from token ID to Track details
    mapping(uint256 => Track) public tracks;
    
    // Mapping from album ID to Album details
    mapping(uint256 => Album) public albums;
    
    // Counter for generating unique token IDs
    uint256 private _tokenIdCounter;
    
    // Counter for generating unique album IDs
    uint256 private _albumIdCounter;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Default royalty fee (2.5%)
    uint96 private constant DEFAULT_ROYALTY_FEE = 250;

    // Events
    event TrackCreated(uint256 indexed tokenId, address[] artists, string uri, uint256 initialSupply, uint256 price);
    event AlbumCreated(uint256 indexed albumId, address indexed creator, string uri, uint256[] trackIds, uint256 price);
    event TrackVersionUpdated(uint256 indexed tokenId, uint256 version, string newUri, string changelog);
    event TrackPurchased(uint256 indexed tokenId, address indexed buyer, uint256 amount);
    event TrackUriUpdated(uint256 indexed tokenId, string newUri);
    event AlbumPurchased(uint256 indexed albumId, address indexed buyer);
    event AlbumUpdated(uint256 indexed albumId, string newUri);
    event LicenseCreated(uint256 indexed tokenId, LicenseType licenseType, uint256 price);
    event LicensePurchased(uint256 indexed tokenId, address indexed buyer, LicenseType licenseType);
    event BatchAlbumsCreated(uint256[] albumIds);

    constructor() ERC1155("") Ownable(msg.sender) {
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTY_FEE);
    }

    /// @notice Create a new track with multiple artists and royalty shares
    /// @param trackUri The IPFS URI for the track metadata
    /// @param artists Array of artist addresses who collaborated on the track
    /// @param royaltyShares Array of royalty shares for each artist (must sum to 10000 = 100%)
    /// @param initialSupply Initial number of copies to mint
    /// @param price Price per copy in wei
    /// @return tokenId The ID of the newly created track
    function createTrackWithCollaborators(
        string memory trackUri,
        address[] memory artists,
        uint256[] memory royaltyShares,
        uint256 initialSupply,
        uint256 price
    ) public returns (uint256) {
        require(bytes(trackUri).length > 0, "Invalid URI");
        require(artists.length > 0, "At least one artist required");
        require(artists.length == royaltyShares.length, "Artists and shares mismatch");
        
        uint256 totalShares = 0;
        for (uint256 i = 0; i < royaltyShares.length; i++) {
            totalShares += royaltyShares[i];
        }
        require(totalShares == 10000, "Shares must total 100%");

        uint256 tokenId = _tokenIdCounter++;
        
        Track storage track = tracks[tokenId];
        track.uri = trackUri;
        track.price = price;
        track.artists = artists;
        track.royaltyShares = royaltyShares;
        track.exists = true;
        track.version = 1;
        track.albumId = 0;

        _mint(msg.sender, tokenId, initialSupply, "");
        _setTokenRoyalty(tokenId, address(this), DEFAULT_ROYALTY_FEE);

        emit TrackCreated(tokenId, artists, trackUri, initialSupply, price);
        return tokenId;
    }

    /// @notice Create a new album containing multiple tracks
    /// @param albumUri The IPFS URI for the album metadata
    /// @param trackIds Array of track IDs to include in the album
    /// @param price Price for the complete album
    /// @param discountBps Discount in basis points (100 = 1%)
    /// @return albumId The ID of the newly created album
    function createAlbum(
        string memory albumUri,
        uint256[] memory trackIds,
        uint256 price,
        uint256 discountBps
    ) public returns (uint256) {
        require(trackIds.length > 0, "Album must contain tracks");
        require(discountBps <= 10000, "Invalid discount");
        
        // Verify all tracks exist and caller is creator of all tracks
        for (uint256 i = 0; i < trackIds.length; i++) {
            require(tracks[trackIds[i]].exists, "Track does not exist");
            require(
                tracks[trackIds[i]].artists[0] == msg.sender,
                "Not track creator"
            );
        }

        uint256 albumId = _albumIdCounter++;
        albums[albumId] = Album({
            uri: albumUri,
            price: price,
            trackIds: trackIds,
            creator: msg.sender,
            exists: true,
            discountBps: discountBps
        });

        // Set initial owner
        _owners[albumId] = msg.sender;
        
        // Mint a single copy of the album token
        _mint(msg.sender, albumId, 1, "");
        
        emit AlbumCreated(albumId, msg.sender, albumUri, trackIds, price);
        return albumId;
    }

    /// @notice Get the owner of an album
    /// @param albumId The ID of the album to query
    /// @return The address of the album owner
    function ownerOf(uint256 albumId) public view returns (address) {
        require(albums[albumId].exists, "Album does not exist");
        return _owners[albumId];
    }

    /// @notice Purchase a track
    /// @param tokenId The ID of the track to purchase
    /// @param amount The amount of copies to purchase
    function purchaseTrack(uint256 tokenId, uint256 amount) external payable {
        Track storage track = tracks[tokenId];
        require(track.exists, "Track does not exist");
        require(msg.value >= track.price * amount, "Insufficient payment");
        
        // Calculate and transfer royalties
        (address royaltyReceiver, uint256 royaltyAmount) = royaltyInfo(tokenId, msg.value);
        uint256 artistPayment = msg.value - royaltyAmount;
        
        // Transfer payments
        (bool success1, ) = royaltyReceiver.call{value: royaltyAmount}("");
        (bool success2, ) = track.artists[0].call{value: artistPayment}("");
        require(success1 && success2, "Payment failed");
        
        // Transfer NFT to buyer
        _safeTransferFrom(track.artists[0], msg.sender, tokenId, amount, "");
        
        emit TrackPurchased(tokenId, msg.sender, amount);
    }

    /// @notice Purchase an album
    /// @param albumId The ID of the album to purchase
    function purchaseAlbum(uint256 albumId) external payable {
        Album memory album = albums[albumId];
        require(album.exists, "Album does not exist");
        
        uint256 discountedPrice = album.price * (10000 - album.discountBps) / 10000;
        require(msg.value >= discountedPrice, "Insufficient payment");

        address currentOwner = ownerOf(albumId);

        // Transfer album ownership
        _owners[albumId] = msg.sender;

        // Transfer individual tracks
        for (uint256 i = 0; i < album.trackIds.length; i++) {
            uint256 trackId = album.trackIds[i];
            _safeTransferFrom(tracks[trackId].artists[0], msg.sender, trackId, 1, "");
        }

        // Calculate and distribute payments
        uint256 royaltyAmount = (msg.value * DEFAULT_ROYALTY_FEE) / 10000;
        uint256 artistPayment = msg.value - royaltyAmount;

        // Transfer royalties to contract
        (bool success1, ) = address(this).call{value: royaltyAmount}("");
        require(success1, "Royalty transfer failed");

        // Transfer remaining payment to album creator
        (bool success2, ) = currentOwner.call{value: artistPayment}("");
        require(success2, "Payment transfer failed");

        emit AlbumPurchased(albumId, msg.sender);
    }

    /// @notice Update track metadata with a new version
    /// @param tokenId The ID of the track to update
    /// @param newUri The new IPFS URI for the track metadata
    /// @param changelog Description of changes in this version
    function updateTrackVersion(
        uint256 tokenId,
        string memory newUri,
        string memory changelog
    ) public {
        Track storage track = tracks[tokenId];
        require(track.exists, "Track does not exist");
        require(track.artists[0] == msg.sender, "Not track creator");

        track.version += 1;
        track.uri = newUri;

        track.versionHistory.push(VersionInfo({
            version: track.version,
            uri: newUri,
            changelog: changelog,
            timestamp: block.timestamp
        }));

        emit TrackVersionUpdated(tokenId, track.version, newUri, changelog);
    }

    /// @notice Get version history for a track
    /// @param tokenId The ID of the track
    /// @return Array of version information
    function getVersionHistory(uint256 tokenId) public view returns (VersionInfo[] memory) {
        require(tracks[tokenId].exists, "Track does not exist");
        return tracks[tokenId].versionHistory;
    }

    /// @notice Get the URI for a specific token, overriding ERC1155 implementation
    /// @param tokenId The ID of the token to query
    /// @return The URI string
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tracks[tokenId].exists, "URI query for nonexistent token");
        return tracks[tokenId].uri;
    }

    /// @notice Distribute accumulated royalties to collaborating artists
    /// @param tokenId The ID of the track to distribute royalties for
    function distributeRoyalties(uint256 tokenId) public {
        Track storage track = tracks[tokenId];
        require(track.exists, "Track does not exist");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No royalties to distribute");

        // Distribute according to shares
        uint256 remaining = balance;
        for (uint256 i = 0; i < track.artists.length - 1; i++) {
            uint256 share = (balance * track.royaltyShares[i]) / 10000;
            payable(track.artists[i]).transfer(share);
            remaining -= share;
        }
        
        // Send remaining to last artist to avoid rounding issues
        payable(track.artists[track.artists.length - 1]).transfer(remaining);
    }

    /// @notice Updates the URI of a track
    /// @param tokenId The ID of the track to update
    /// @param newUri The new URI for the track
    function updateTrackUri(uint256 tokenId, string memory newUri) external {
        require(tracks[tokenId].exists, "Track does not exist");
        require(tracks[tokenId].artists[0] == msg.sender, "Not track artist");
        require(bytes(newUri).length > 0, "Invalid URI");
        
        tracks[tokenId].uri = newUri;
        emit TrackUriUpdated(tokenId, newUri);
    }

    /// @notice Get track details
    /// @param tokenId The ID of the track to query
    /// @return trackUri The URI of the track
    /// @return price The price of the track
    /// @return artists The array of artist addresses
    /// @return royaltyShares The array of royalty shares
    /// @return exists Whether the track exists
    /// @return version The version number of the track
    /// @return albumId The ID of the album this track belongs to
    function getTrack(uint256 tokenId) public view returns (
        string memory trackUri,
        uint256 price,
        address[] memory artists,
        uint256[] memory royaltyShares,
        bool exists,
        uint256 version,
        uint256 albumId
    ) {
        Track storage track = tracks[tokenId];
        require(track.exists, "Track does not exist");
        return (
            track.uri,
            track.price,
            track.artists,
            track.royaltyShares,
            track.exists,
            track.version,
            track.albumId
        );
    }

    /// @notice Get album details
    /// @param albumId The ID of the album to query
    /// @return albumUri The IPFS URI for the album metadata
    /// @return price The price of the album
    /// @return trackIds Array of track IDs included in the album
    /// @return discountBps The discount in basis points
    function getAlbum(uint256 albumId) public view returns (
        string memory albumUri,
        uint256 price,
        uint256[] memory trackIds,
        uint256 discountBps
    ) {
        require(albums[albumId].exists, "Album does not exist");
        Album memory album = albums[albumId];
        return (album.uri, album.price, album.trackIds, album.discountBps);
    }

    /// @notice Update album metadata
    /// @param albumId The ID of the album to update
    /// @param newUri The new IPFS URI for the album metadata
    function updateAlbumUri(uint256 albumId, string memory newUri) external {
        require(albums[albumId].exists, "Album does not exist");
        require(ownerOf(albumId) == msg.sender, "Not album owner");
        
        albums[albumId].uri = newUri;
        emit AlbumUpdated(albumId, newUri);
    }

    /// @notice Create a new license for a track
    /// @param tokenId The ID of the track
    /// @param licenseType The type of license
    /// @param price The price for the license
    function createLicense(
        uint256 tokenId,
        LicenseType licenseType,
        uint256 price
    ) external {
        Track storage track = tracks[tokenId];
        require(track.exists, "Track does not exist");
        require(track.artists[0] == msg.sender, "Not track creator");
        
        track.licenses[licenseType] = License({
            licenseType: licenseType,
            price: price,
            active: true
        });
        
        emit LicenseCreated(tokenId, licenseType, price);
    }

    /// @notice Purchase a license for a track
    /// @param tokenId The ID of the track
    /// @param licenseType The type of license to purchase
    function purchaseLicense(uint256 tokenId, LicenseType licenseType) external payable {
        Track storage track = tracks[tokenId];
        require(track.exists, "Track does not exist");
        License memory license = track.licenses[licenseType];
        require(license.active, "License not available");
        require(msg.value >= license.price, "Insufficient payment");

        // Calculate and distribute payments
        uint256 royaltyAmount = (msg.value * DEFAULT_ROYALTY_FEE) / 10000;
        uint256 artistPayment = msg.value - royaltyAmount;

        // Transfer royalties to contract
        (bool success1, ) = address(this).call{value: royaltyAmount}("");
        require(success1, "Royalty transfer failed");

        // Transfer remaining payment to track creator
        (bool success2, ) = track.artists[0].call{value: artistPayment}("");
        require(success2, "Payment transfer failed");

        // Record the license purchase
        track.licensePurchases[licenseType][msg.sender] = true;

        emit LicensePurchased(tokenId, msg.sender, licenseType);
    }

    /// @notice Create multiple albums in a single transaction
    /// @param albumUris Array of IPFS URIs for album metadata
    /// @param trackIdArrays Array of track ID arrays for each album
    /// @param prices Array of prices for each album
    /// @param discountBpsArray Array of discount basis points for each album
    /// @return albumIds Array of created album IDs
    function createBatchAlbums(
        string[] memory albumUris,
        uint256[][] memory trackIdArrays,
        uint256[] memory prices,
        uint256[] memory discountBpsArray
    ) public returns (uint256[] memory) {
        require(
            albumUris.length == trackIdArrays.length &&
            albumUris.length == prices.length &&
            albumUris.length == discountBpsArray.length,
            "Array lengths must match"
        );

        uint256[] memory albumIds = new uint256[](albumUris.length);

        for (uint256 i = 0; i < albumUris.length; i++) {
            albumIds[i] = createAlbum(
                albumUris[i],
                trackIdArrays[i],
                prices[i],
                discountBpsArray[i]
            );
        }

        emit BatchAlbumsCreated(albumIds);
        return albumIds;
    }

    /// @notice Check if an address has purchased a specific license for a track
    /// @param tokenId The ID of the track
    /// @param licenseType The type of license to check
    /// @param user The address to check
    /// @return Whether the user has purchased the license
    function hasLicense(
        uint256 tokenId,
        LicenseType licenseType,
        address user
    ) public view returns (bool) {
        Track storage track = tracks[tokenId];
        require(track.exists, "Track does not exist");
        
        // If user owns the NFT or is the creator, they have all licenses
        if (balanceOf(user, tokenId) > 0 || track.artists[0] == user) {
            return true;
        }

        // Check if they've purchased this specific license
        return track.licensePurchases[licenseType][user];
    }

    // The following functions are overrides required by Solidity

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Function to receive Ether
    receive() external payable {}
}