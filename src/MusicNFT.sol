// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interfaces/IRoyaltyDistributor.sol";

/**
 * @title MusicNFT
 * @dev Contract for managing music NFTs with royalty distribution
 */
contract MusicNFT is ERC1155, ERC1155Holder, AccessControl, ReentrancyGuard, IERC2981 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    IERC20 public immutable tuneToken;
    IRoyaltyDistributor public immutable royaltyDistributor;
    uint256 public constant ROYALTY_PERCENTAGE = 250; // 2.5%

    struct Track {
        string uri;
        uint256 price;
        bool isActive;
        address[] collaborators;
        uint256[] royaltyShares;
        uint256 version;
        uint256 albumId;
    }

    struct VersionInfo {
        string uri;
        string changelog;
        uint256 timestamp;
    }

    // Mapping from token ID to track info
    mapping(uint256 => Track) private _tracks;

    // Mapping from token ID to version history
    mapping(uint256 => VersionInfo[]) private _versionHistory;

    // Counter for token IDs
    uint256 private _tokenIdCounter;

    // Events
    event TrackCreated(uint256 indexed tokenId, address indexed creator, uint256 price);
    event TrackPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event TrackVersionUpdated(uint256 indexed tokenId, string newUri, string changelog);
    event TrackUriUpdated(uint256 indexed tokenId, string newUri);

    constructor(string memory baseUri, address _tuneToken, address _royaltyDistributor) ERC1155(baseUri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);

        tuneToken = IERC20(_tuneToken);
        royaltyDistributor = IRoyaltyDistributor(_royaltyDistributor);
    }

    /**
     * @dev Creates a new track with collaborators and royalty shares
     * @param uri The IPFS URI for track metadata
     * @param collaborators Array of collaborator addresses
     * @param shares Array of royalty shares (in basis points)
     * @param maxSupply Maximum supply of the track
     * @param price Price in TuneTokens
     */
    function createTrackWithCollaborators(
        string memory uri,
        address[] memory collaborators,
        uint256[] memory shares,
        uint256 maxSupply,
        uint256 price
    )
        external
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        require(bytes(uri).length > 0, "URI cannot be empty");
        require(collaborators.length == shares.length, "Arrays length mismatch");
        require(collaborators.length > 0, "No collaborators provided");

        uint256 totalShares;
        for (uint256 i = 0; i < shares.length; i++) {
            require(collaborators[i] != address(0), "Invalid collaborator address");
            require(shares[i] > 0, "Invalid share value");
            totalShares += shares[i];
        }
        require(totalShares == 10_000, "Total shares must be 100%");

        uint256 tokenId = _tokenIdCounter++;

        _tracks[tokenId] = Track({
            uri: uri,
            price: price,
            isActive: true,
            collaborators: collaborators,
            royaltyShares: shares,
            version: 1,
            albumId: 0
        });

        _versionHistory[tokenId].push(
            VersionInfo({ uri: uri, changelog: "Initial version", timestamp: block.timestamp })
        );

        _mint(msg.sender, tokenId, maxSupply, "");

        emit TrackCreated(tokenId, msg.sender, price);
        return tokenId;
    }

    /**
     * @dev Purchases a track using TuneTokens
     * @param tokenId The ID of the track to purchase
     */
    function purchaseTrack(uint256 tokenId) external nonReentrant {
        require(_tracks[tokenId].isActive, "Track not active");
        require(_tracks[tokenId].price > 0, "Track not for sale");
        require(balanceOf(address(this), tokenId) > 0, "Track sold out");

        uint256 price = _tracks[tokenId].price;

        // Transfer TuneTokens from buyer to contract
        require(tuneToken.transferFrom(msg.sender, address(this), price), "Payment failed");

        // Distribute royalties
        uint256 royaltyAmount = (price * 250) / 10_000; // 2.5% royalty
        require(tuneToken.approve(address(royaltyDistributor), royaltyAmount), "Royalty approval failed");
        royaltyDistributor.distributeRoyalties(tokenId, royaltyAmount);

        // Transfer track to buyer
        _safeTransferFrom(address(this), msg.sender, tokenId, 1, "");

        emit TrackPurchased(tokenId, msg.sender, price);
    }

    /**
     * @dev Updates track version with changelog
     * @param tokenId The ID of the track
     * @param newUri New IPFS URI
     * @param changelog Description of changes
     */
    function updateTrackVersion(uint256 tokenId, string memory newUri, string memory changelog) external {
        require(_tracks[tokenId].collaborators[0] == msg.sender, "Not track creator");
        require(bytes(newUri).length > 0, "URI cannot be empty");
        require(bytes(changelog).length > 0, "Changelog cannot be empty");

        _tracks[tokenId].uri = newUri;
        _tracks[tokenId].version++;

        _versionHistory[tokenId].push(VersionInfo({ uri: newUri, changelog: changelog, timestamp: block.timestamp }));

        emit TrackVersionUpdated(tokenId, newUri, changelog);
    }

    /**
     * @dev Updates track URI
     * @param tokenId The ID of the track
     * @param newUri New IPFS URI
     */
    function updateTrackUri(uint256 tokenId, string memory newUri) external onlyRole(URI_SETTER_ROLE) {
        require(bytes(newUri).length > 0, "URI cannot be empty");
        _tracks[tokenId].uri = newUri;
        emit TrackUriUpdated(tokenId, newUri);
    }

    /**
     * @dev Gets track information
     * @param tokenId The ID of the track
     */
    function getTrack(uint256 tokenId)
        external
        view
        returns (
            string memory uri,
            uint256 price,
            bool isActive,
            address[] memory collaborators,
            uint256[] memory royaltyShares,
            uint256 version,
            uint256 albumId
        )
    {
        Track storage track = _tracks[tokenId];
        return (
            track.uri,
            track.price,
            track.isActive,
            track.collaborators,
            track.royaltyShares,
            track.version,
            track.albumId
        );
    }

    /**
     * @dev Gets version history of a track
     * @param tokenId The ID of the track
     */
    function getVersionHistory(uint256 tokenId) external view returns (VersionInfo[] memory) {
        return _versionHistory[tokenId];
    }

    /**
     * @dev Checks if a token exists
     * @param tokenId The ID of the token to check
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return bytes(_tracks[tokenId].uri).length > 0;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Track storage track = _tracks[tokenId];
        require(track.collaborators.length > 0, "Token does not exist");

        // Return the first collaborator as the royalty receiver
        // The actual distribution will be handled by the RoyaltyDistributor
        return (track.collaborators[0], (salePrice * ROYALTY_PERCENTAGE) / 10_000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC1155Holder, AccessControl, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
