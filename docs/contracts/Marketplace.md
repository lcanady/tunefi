# Marketplace Contract Documentation

## Overview
The Marketplace contract facilitates the buying, selling, and trading of music NFTs in the TuneFi ecosystem. It handles listings, offers, royalty payments, and platform fees.

## Features

### Listing Management
- Fixed price listings
- Timed auctions
- Batch listings
- Listing modification

### Trading Functions
- Direct purchases
- Offer making/accepting
- Auction bidding
- Batch trading

### Payment Processing
- Automatic royalty distribution
- Platform fee handling
- Revenue sharing
- Escrow management

## Functions

### Listing Management

#### createListing
```solidity
function createListing(
    uint256 tokenId,
    uint256 amount,
    uint256 price,
    uint256 duration
) external
```
Creates a new listing for a token with specified price and duration.

#### cancelListing
```solidity
function cancelListing(uint256 listingId) external
```
Cancels an active listing.

#### updateListingPrice
```solidity
function updateListingPrice(uint256 listingId, uint256 newPrice) external
```
Updates the price of an existing listing.

### Trading

#### buyToken
```solidity
function buyToken(uint256 listingId) external payable
```
Purchases a token from an active listing.

#### makeOffer
```solidity
function makeOffer(uint256 listingId, uint256 price) external payable
```
Makes an offer on a listed token.

#### acceptOffer
```solidity
function acceptOffer(uint256 offerId) external
```
Accepts an existing offer.

### Revenue Management

#### claimRevenue
```solidity
function claimRevenue() external
```
Claims accumulated revenue from sales.

#### updatePlatformFee
```solidity
function updatePlatformFee(uint256 newFee) external onlyOwner
```
Updates the platform fee percentage.

## Events

```solidity
event ListingCreated(uint256 indexed listingId, uint256 indexed tokenId, uint256 price);
event ListingCancelled(uint256 indexed listingId);
event ListingUpdated(uint256 indexed listingId, uint256 newPrice);
event TokenPurchased(uint256 indexed listingId, address indexed buyer, uint256 price);
event OfferMade(uint256 indexed listingId, address indexed offeror, uint256 price);
event OfferAccepted(uint256 indexed offerId, address indexed seller);
event RevenueClaimed(address indexed user, uint256 amount);
event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
```

## Security Considerations

1. **Access Control**
   - Listing ownership verification
   - Offer validation
   - Revenue claim authorization

2. **Economic Security**
   - Price validation
   - Fee calculation
   - Royalty distribution
   - Escrow management

3. **Operational Security**
   - Reentrancy protection
   - Price manipulation prevention
   - Gas optimization
   - State consistency

## Integration Guide

### Creating a Listing
```solidity
// Create a new listing
marketplace.createListing(
    tokenId,
    1, // amount
    1 ether, // price
    7 days // duration
);
```

### Purchasing a Token
```solidity
// Buy a token from a listing
marketplace.buyToken{value: price}(listingId);
```

### Making an Offer
```solidity
// Make an offer on a listing
marketplace.makeOffer{value: offerPrice}(
    listingId,
    offerPrice
);
```

## Testing

The contract includes comprehensive tests in `test/Marketplace.t.sol`:
- Listing functionality
- Purchase flows
- Offer system
- Revenue distribution
- Access control

## Deployment

Required parameters:
- Platform fee percentage
- Fee recipient address
- MusicNFT contract address
- RoyaltyDistributor address

## Gas Optimization

1. Batch listing support
2. Efficient storage layout
3. Minimal state changes
4. Optimized calculations

## Audits

Focus areas:
1. Trading logic
2. Fee handling
3. Access control
4. Revenue distribution
5. Economic security
