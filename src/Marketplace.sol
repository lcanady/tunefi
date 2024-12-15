// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./MusicNFT.sol";

/**
 * @title Marketplace
 * @dev A marketplace contract for trading TuneFi Music NFTs
 */
contract Marketplace is ReentrancyGuard, Ownable, Pausable, ERC1155Holder {
    using SafeERC20 for IERC20;

    // State variables
    IERC1155 public immutable nftContract;
    IERC2981 private immutable royaltyContract;
    IERC20 public immutable paymentToken;
    uint256 public platformFee; // Fee in basis points (e.g., 250 = 2.5%)
    
    // Listing struct
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }
    
    // Offer struct
    struct Offer {
        address buyer;
        uint256 price;
        uint256 expirationTime;
    }
    
    // Mappings
    mapping(uint256 => Listing) public listings; // tokenId => Listing
    mapping(uint256 => Offer[]) public offers; // tokenId => Offer[]
    mapping(address => uint256) public pendingRevenue; // address => amount
    
    // Events
    event TokenListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event TokenDelisted(uint256 indexed tokenId, address indexed seller);
    event TokenSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event OfferCreated(uint256 indexed tokenId, address indexed buyer, uint256 price, uint256 expirationTime);
    event OfferAccepted(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event OfferCancelled(uint256 indexed tokenId, address indexed buyer);
    event RevenueClaimed(address indexed user, uint256 amount);
    event PlatformFeeUpdated(uint256 newFee);
    
    // Constants
    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant MAX_PLATFORM_FEE = 1000; // 10%
    uint256 private constant MIN_LISTING_PRICE = 0.001 ether;
    uint256 private constant MAX_OFFER_DURATION = 30 days;
    
    /**
     * @dev Constructor
     * @param _nftContract Address of the MusicNFT contract
     * @param _paymentToken Address of the payment token (e.g., TUNE)
     * @param _platformFee Initial platform fee in basis points
     */
    constructor(
        address _nftContract,
        address _paymentToken,
        uint256 _platformFee
    ) Ownable(msg.sender) {
        require(_nftContract != address(0), "Invalid NFT contract");
        require(_paymentToken != address(0), "Invalid payment token");
        require(_platformFee <= MAX_PLATFORM_FEE, "Fee too high");
        
        nftContract = IERC1155(_nftContract);
        royaltyContract = IERC2981(_nftContract);
        paymentToken = IERC20(_paymentToken);
        platformFee = _platformFee;
    }
    
    /**
     * @dev List a token for sale
     * @param tokenId Token ID to list
     * @param price Listing price
     */
    function listToken(uint256 tokenId, uint256 price) external nonReentrant whenNotPaused {
        require(price >= MIN_LISTING_PRICE, "Price too low");
        require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not token owner");
        require(!listings[tokenId].active, "Already listed");
        
        // Transfer NFT to marketplace
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        
        // Create listing
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });
        
        emit TokenListed(tokenId, msg.sender, price);
    }
    
    /**
     * @dev Delist a token
     * @param tokenId Token ID to delist
     */
    function delistToken(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId];
        require(listing.active, "Not listed");
        require(listing.seller == msg.sender, "Not seller");
        
        // Transfer NFT back to seller
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        
        // Remove listing
        delete listings[tokenId];
        
        emit TokenDelisted(tokenId, msg.sender);
    }
    
    /**
     * @dev Buy a listed token
     * @param tokenId Token ID to buy
     */
    function buyToken(uint256 tokenId) external nonReentrant whenNotPaused {
        Listing storage listing = listings[tokenId];
        require(listing.active, "Not listed");
        require(msg.sender != listing.seller, "Seller cannot buy");
        
        uint256 price = listing.price;
        address seller = listing.seller;
        
        // Calculate fees
        uint256 platformAmount = (price * platformFee) / BASIS_POINTS;
        (uint256 royaltyAmount, address royaltyRecipient) = calculateRoyalty(tokenId, price);
        uint256 sellerAmount = price - platformAmount - royaltyAmount;
        
        // Transfer payment token from buyer
        paymentToken.safeTransferFrom(msg.sender, address(this), price);
        
        // Update pending revenue
        pendingRevenue[owner()] += platformAmount;
        pendingRevenue[royaltyRecipient] += royaltyAmount;
        pendingRevenue[seller] += sellerAmount;
        
        // Transfer NFT to buyer
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        
        // Remove listing
        delete listings[tokenId];
        
        emit TokenSold(tokenId, seller, msg.sender, price);
    }
    
    /**
     * @dev Make an offer for a token
     * @param tokenId Token ID to make offer for
     * @param price Offer price
     * @param duration Duration of the offer in seconds
     */
    function makeOffer(uint256 tokenId, uint256 price, uint256 duration) external nonReentrant whenNotPaused {
        require(price >= MIN_LISTING_PRICE, "Price too low");
        require(duration <= MAX_OFFER_DURATION, "Duration too long");
        require(nftContract.balanceOf(msg.sender, tokenId) == 0, "Token owner cannot make offer");
        
        uint256 expirationTime = block.timestamp + duration;
        
        offers[tokenId].push(Offer({
            buyer: msg.sender,
            price: price,
            expirationTime: expirationTime
        }));
        
        emit OfferCreated(tokenId, msg.sender, price, expirationTime);
    }
    
    /**
     * @dev Accept an offer for a token
     * @param tokenId Token ID of the offer
     * @param offerIndex Index of the offer to accept
     */
    function acceptOffer(uint256 tokenId, uint256 offerIndex) external nonReentrant whenNotPaused {
        require(nftContract.balanceOf(msg.sender, tokenId) > 0, "Not token owner");
        require(offerIndex < offers[tokenId].length, "Invalid offer index");
        
        Offer memory offer = offers[tokenId][offerIndex];
        require(block.timestamp <= offer.expirationTime, "Offer expired");
        
        uint256 price = offer.price;
        address buyer = offer.buyer;
        
        // Calculate fees
        uint256 platformAmount = (price * platformFee) / BASIS_POINTS;
        (uint256 royaltyAmount, address royaltyRecipient) = calculateRoyalty(tokenId, price);
        uint256 sellerAmount = price - platformAmount - royaltyAmount;
        
        // Transfer payment token from buyer
        paymentToken.safeTransferFrom(buyer, address(this), price);
        
        // Update pending revenue
        pendingRevenue[owner()] += platformAmount;
        pendingRevenue[royaltyRecipient] += royaltyAmount;
        pendingRevenue[msg.sender] += sellerAmount;
        
        // Transfer NFT to buyer
        nftContract.safeTransferFrom(msg.sender, buyer, tokenId, 1, "");
        
        // Remove all offers for this token
        delete offers[tokenId];
        
        emit OfferAccepted(tokenId, msg.sender, buyer, price);
    }
    
    /**
     * @dev Cancel an offer
     * @param tokenId Token ID of the offer
     * @param offerIndex Index of the offer to cancel
     */
    function cancelOffer(uint256 tokenId, uint256 offerIndex) external nonReentrant {
        require(offerIndex < offers[tokenId].length, "Invalid offer index");
        require(offers[tokenId][offerIndex].buyer == msg.sender, "Not offer creator");
        
        // Remove offer
        offers[tokenId][offerIndex] = offers[tokenId][offers[tokenId].length - 1];
        offers[tokenId].pop();
        
        emit OfferCancelled(tokenId, msg.sender);
    }
    
    /**
     * @dev Claim pending revenue
     */
    function claimRevenue() external nonReentrant {
        uint256 amount = pendingRevenue[msg.sender];
        require(amount > 0, "No pending revenue");
        
        // Reset pending revenue before transfer
        pendingRevenue[msg.sender] = 0;
        
        // Transfer payment token to user
        paymentToken.safeTransfer(msg.sender, amount);
        
        emit RevenueClaimed(msg.sender, amount);
    }
    
    /**
     * @dev Calculate royalty for a token sale
     * @param tokenId Token ID
     * @param price Sale price
     * @return amount Royalty amount
     * @return recipient Royalty recipient
     */
    function calculateRoyalty(uint256 tokenId, uint256 price) public view returns (uint256 amount, address recipient) {
        (address royaltyRecipient, uint256 royaltyAmount) = royaltyContract.royaltyInfo(tokenId, price);
        return (royaltyAmount, royaltyRecipient);
    }
    
    /**
     * @dev Get listing for a token
     * @param tokenId Token ID
     * @return Listing struct
     */
    function getListing(uint256 tokenId) external view returns (Listing memory) {
        return listings[tokenId];
    }
    
    /**
     * @dev Get offers for a token
     * @param tokenId Token ID
     * @return Array of Offer structs
     */
    function getOffers(uint256 tokenId) external view returns (Offer[] memory) {
        return offers[tokenId];
    }
    
    /**
     * @dev Update platform fee
     * @param newFee New platform fee in basis points
     */
    function setPlatformFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_PLATFORM_FEE, "Fee too high");
        platformFee = newFee;
        emit PlatformFeeUpdated(newFee);
    }
    
    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
