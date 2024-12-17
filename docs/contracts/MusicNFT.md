# MusicNFT Contract Documentation

## Overview
MusicNFT is an ERC1155-based smart contract that represents music tracks and albums as NFTs on the TuneFi platform. It implements royalty distribution, licensing, and metadata management for music assets.

## Features

### NFT Types
1. Single Tracks
   - Unique tokenId per track
   - Individual metadata and licensing
   - Track-specific royalty splits

2. Albums
   - Collection of tracks
   - Bundle pricing
   - Shared metadata
   - Album-wide royalty distribution

### Royalty System
- Configurable royalty percentages
- Multiple beneficiary support
- Automated distribution
- Minimum distribution thresholds

### Metadata Management
- IPFS-based storage
- Version history tracking
- Updatable metadata
- Content verification

## Functions

### Minting

#### mintTrack
```solidity
function mintTrack(
    string memory uri,
    uint256 amount,
    address[] memory royaltyRecipients,
    uint256[] memory royaltyShares
) external returns (uint256)
```
Mints a new music track NFT with specified royalty distribution.

#### mintAlbum
```solidity
function mintAlbum(
    string memory uri,
    uint256[] memory trackIds,
    uint256 amount
) external returns (uint256)
```
Creates an album NFT containing multiple tracks.

### Royalty Management

#### updateRoyaltyInfo
```solidity
function updateRoyaltyInfo(
    uint256 tokenId,
    address[] memory recipients,
    uint256[] memory shares
) external
```
Updates royalty distribution for a token.

#### getRoyaltyInfo
```solidity
function getRoyaltyInfo(
    uint256 tokenId,
    uint256 salePrice
) external view returns (address[] memory, uint256[] memory)
```
Returns royalty information for a token sale.

### Metadata Management

#### setURI
```solidity
function setURI(uint256 tokenId, string memory newuri) external
```
Updates the metadata URI for a token.

#### getVersionHistory
```solidity
function getVersionHistory(uint256 tokenId) external view returns (string[] memory)
```
Returns the version history of token metadata.

## Events

```solidity
event TrackMinted(uint256 indexed tokenId, address indexed artist, string uri);
event AlbumMinted(uint256 indexed tokenId, uint256[] trackIds);
event RoyaltyUpdated(uint256 indexed tokenId, address[] recipients, uint256[] shares);
event MetadataUpdated(uint256 indexed tokenId, string newUri);
event RoyaltyPaid(uint256 indexed tokenId, address indexed recipient, uint256 amount);
```

## Security Considerations

1. **Access Control**
   - Artist-only minting
   - Royalty recipient verification
   - Metadata update restrictions

2. **Economic Security**
   - Royalty calculation accuracy
   - Distribution thresholds
   - Fee management

3. **Data Integrity**
   - Metadata immutability
   - Version history tracking
   - Content verification

## Integration Guide

### Minting a Track
```solidity
// Mint a new track
address[] memory recipients = [artist, producer];
uint256[] memory shares = [80, 20];
uint256 tokenId = musicNFT.mintTrack(
    "ipfs://QmTrackMetadata",
    1000,
    recipients,
    shares
);
```

### Creating an Album
```solidity
// Create an album from tracks
uint256[] memory trackIds = [track1, track2, track3];
uint256 albumId = musicNFT.mintAlbum(
    "ipfs://QmAlbumMetadata",
    trackIds,
    500
);
```

### Updating Metadata
```solidity
// Update track metadata
musicNFT.setURI(tokenId, "ipfs://QmNewMetadata");
```

## Testing

The contract includes comprehensive tests in `test/MusicNFT.t.sol`:
- Minting functionality
- Royalty calculations
- Metadata management
- Access control
- Error cases

## Deployment

Required parameters:
- RoyaltyDistributor contract address
- Platform fee percentage
- Minimum distribution threshold

## Gas Optimization

1. Batch minting support
2. Efficient metadata storage
3. Optimized royalty calculations
4. Minimal storage operations

## Audits

Focus areas:
1. Royalty distribution logic
2. Access control implementation
3. Metadata management
4. ERC1155 compliance
5. Economic model security
