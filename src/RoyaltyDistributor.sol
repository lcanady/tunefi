// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title RoyaltyDistributor
 * @dev Contract for managing and distributing royalties to multiple payees for music NFTs
 */
contract RoyaltyDistributor is Ownable, ReentrancyGuard {
    IERC20 public immutable token;
    
    struct PayeeInfo {
        address payee;
        uint256 shares;
        bool exists;
    }
    
    // Mapping from tokenId to array of payees
    mapping(uint256 => PayeeInfo[]) private _payees;
    
    // Mapping from tokenId to accumulated royalties
    mapping(uint256 => uint256) private _accumulatedRoyalties;
    
    // Mapping from tokenId to auto-distribution threshold
    mapping(uint256 => uint256) private _autoDistributionThresholds;
    
    // Minimum amount required for distribution
    uint256 public distributionThreshold;
    
    // Mapping from tokenId to streaming rate (tokens per minute)
    mapping(uint256 => uint256) private _streamingRates;
    
    // Mapping from tokenId to accumulated streaming minutes
    mapping(uint256 => uint256) private _streamingMinutes;
    
    event RoyaltyDistributed(uint256 indexed tokenId, uint256 amount);
    event PayeeAdded(uint256 indexed tokenId, address indexed account, uint256 shares);
    event PayeeRemoved(uint256 indexed tokenId, address indexed account);
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event RoyaltyAccumulated(uint256 indexed tokenId, uint256 amount);
    event AutoDistributionThresholdSet(uint256 indexed tokenId, uint256 threshold);
    event RoyaltyReconciled(uint256 indexed tokenId, uint256 amount, bool isPositive);
    event StreamingRateSet(uint256 indexed tokenId, uint256 rate);
    event StreamingMinutesAdded(uint256 indexed tokenId, uint256 streamedMinutes);
    event StreamingRoyaltyDistributed(uint256 indexed tokenId, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "Token address cannot be zero");
        token = IERC20(_token);
    }
    
    /**
     * @dev Sets the payees and their respective shares for a token
     * @param tokenId The ID of the token
     * @param payees Array of payee addresses
     * @param shares Array of corresponding shares
     */
    function setPayees(uint256 tokenId, address[] memory payees, uint256[] memory shares) 
        external 
        onlyOwner 
    {
        require(payees.length == shares.length, "Arrays length mismatch");
        require(payees.length > 0, "No payees provided");
        
        uint256 totalShares;
        delete _payees[tokenId];
        
        for(uint i = 0; i < payees.length; i++) {
            require(payees[i] != address(0), "Invalid payee address");
            require(shares[i] > 0, "Invalid shares value");
            totalShares += shares[i];
            
            _payees[tokenId].push(PayeeInfo({
                payee: payees[i],
                shares: shares[i],
                exists: true
            }));
            
            emit PayeeAdded(tokenId, payees[i], shares[i]);
        }
        
        require(totalShares == 100, "Total shares must be 100");
    }
    
    /**
     * @dev Removes a payee from a token's royalty distribution
     * @param tokenId The ID of the token
     * @param payeeAddress The address of the payee to remove
     */
    function removePayee(uint256 tokenId, address payeeAddress) 
        external 
        onlyOwner 
    {
        uint256 removedShares;
        uint256 index = type(uint256).max;
        
        for(uint i = 0; i < _payees[tokenId].length; i++) {
            if(_payees[tokenId][i].payee == payeeAddress) {
                removedShares = _payees[tokenId][i].shares;
                index = i;
                break;
            }
        }
        
        require(index != type(uint256).max, "Payee not found");
        
        // Remove payee and redistribute shares
        _payees[tokenId][index] = _payees[tokenId][_payees[tokenId].length - 1];
        _payees[tokenId].pop();
        
        uint256 sharePerPayee = removedShares / _payees[tokenId].length;
        for(uint i = 0; i < _payees[tokenId].length; i++) {
            _payees[tokenId][i].shares += sharePerPayee;
        }
        
        emit PayeeRemoved(tokenId, payeeAddress);
    }
    
    /**
     * @dev Distributes royalties for a specific token
     * @param tokenId The ID of the token
     * @param amount The amount to distribute
     */
    function distributeRoyalties(uint256 tokenId, uint256 amount) 
        external 
        nonReentrant 
    {
        require(amount >= distributionThreshold, "Amount below threshold");
        
        for(uint i = 0; i < _payees[tokenId].length; i++) {
            PayeeInfo memory payee = _payees[tokenId][i];
            uint256 payeeAmount = (amount * payee.shares) / 100;
            require(token.transfer(payee.payee, payeeAmount), "Transfer failed");
        }
        
        emit RoyaltyDistributed(tokenId, amount);
    }
    
    /**
     * @dev Distributes royalties for multiple tokens
     * @param tokenIds Array of token IDs
     * @param amounts Array of corresponding amounts
     */
    function batchDistributeRoyalties(uint256[] memory tokenIds, uint256[] memory amounts) 
        external 
        nonReentrant 
    {
        require(tokenIds.length == amounts.length, "Arrays length mismatch");
        
        for(uint i = 0; i < tokenIds.length; i++) {
            require(amounts[i] >= distributionThreshold, "Amount below threshold");
            
            for(uint j = 0; j < _payees[tokenIds[i]].length; j++) {
                PayeeInfo memory payee = _payees[tokenIds[i]][j];
                uint256 payeeAmount = (amounts[i] * payee.shares) / 100;
                require(token.transfer(payee.payee, payeeAmount), "Transfer failed");
            }
            
            emit RoyaltyDistributed(tokenIds[i], amounts[i]);
        }
    }
    
    /**
     * @dev Sets the minimum threshold for distribution
     * @param threshold New threshold value
     */
    function setDistributionThreshold(uint256 threshold) 
        external 
        onlyOwner 
    {
        uint256 oldThreshold = distributionThreshold;
        distributionThreshold = threshold;
        emit ThresholdUpdated(oldThreshold, threshold);
    }
    
    /**
     * @dev Sets the automatic distribution threshold for a token
     * @param tokenId The ID of the token
     * @param threshold The threshold amount
     */
    function setAutoDistributionThreshold(uint256 tokenId, uint256 threshold) 
        external 
        onlyOwner 
    {
        _autoDistributionThresholds[tokenId] = threshold;
        emit AutoDistributionThresholdSet(tokenId, threshold);
    }
    
    /**
     * @dev Accumulates royalties for a token and automatically distributes if threshold is met
     * @param tokenId The ID of the token
     * @param amount The amount to accumulate
     */
    function accumulateRoyalties(uint256 tokenId, uint256 amount) 
        external 
        nonReentrant 
    {
        _accumulatedRoyalties[tokenId] += amount;
        emit RoyaltyAccumulated(tokenId, amount);
        
        if(_autoDistributionThresholds[tokenId] > 0 && 
           _accumulatedRoyalties[tokenId] >= _autoDistributionThresholds[tokenId]) {
            uint256 amountToDistribute = _accumulatedRoyalties[tokenId];
            _accumulatedRoyalties[tokenId] = 0;
            
            for(uint i = 0; i < _payees[tokenId].length; i++) {
                PayeeInfo memory payee = _payees[tokenId][i];
                uint256 payeeAmount = (amountToDistribute * payee.shares) / 100;
                require(token.transfer(payee.payee, payeeAmount), "Transfer failed");
            }
            
            emit RoyaltyDistributed(tokenId, amountToDistribute);
        }
    }
    
    /**
     * @dev Reconciles royalty payments with adjustments
     * @param tokenId The ID of the token
     * @param amount The adjustment amount
     * @param isPositive Whether the adjustment is positive or negative
     */
    function reconcileRoyalties(uint256 tokenId, uint256 amount, bool isPositive) 
        external 
        nonReentrant 
        onlyOwner 
    {
        require(amount > 0, "Invalid adjustment amount");
        
        for(uint i = 0; i < _payees[tokenId].length; i++) {
            PayeeInfo memory payee = _payees[tokenId][i];
            uint256 adjustmentAmount = (amount * payee.shares) / 100;
            
            if(isPositive) {
                require(token.transfer(payee.payee, adjustmentAmount), "Transfer failed");
            } else {
                // Handle negative adjustments (implementation depends on business logic)
                // Could involve requesting funds back or adjusting future payments
            }
        }
        
        emit RoyaltyReconciled(tokenId, amount, isPositive);
    }
    
    /**
     * @dev Sets the streaming rate for a token
     * @param tokenId The ID of the token
     * @param ratePerMinute The rate in tokens per minute (in wei)
     */
    function setStreamingRate(uint256 tokenId, uint256 ratePerMinute) 
        external 
        onlyOwner 
    {
        _streamingRates[tokenId] = ratePerMinute;
        emit StreamingRateSet(tokenId, ratePerMinute);
    }

    /**
     * @dev Internal function to distribute royalties to payees
     * @param tokenId The ID of the token
     * @param amount The amount to distribute
     */
    function _distributeRoyalties(uint256 tokenId, uint256 amount) internal {
        require(amount >= distributionThreshold, "Amount below threshold");
        require(_payees[tokenId].length > 0, "No payees set");
        
        for(uint i = 0; i < _payees[tokenId].length; i++) {
            PayeeInfo memory payee = _payees[tokenId][i];
            if(payee.exists) {
                uint256 payeeAmount = (amount * payee.shares) / 100;
                require(token.transfer(payee.payee, payeeAmount), "Transfer failed");
            }
        }
        
        emit RoyaltyDistributed(tokenId, amount);
    }

    /**
     * @dev Records streaming minutes for a token and triggers royalty distribution if threshold is met
     * @param tokenId The ID of the token
     * @param streamedMinutes The number of minutes streamed
     */
    function _recordStreamingMinutes(uint256 tokenId, uint256 streamedMinutes) 
        internal 
    {
        require(_streamingRates[tokenId] > 0, "Streaming rate not set");
        _streamingMinutes[tokenId] += streamedMinutes;
        
        uint256 royaltyAmount = streamedMinutes * _streamingRates[tokenId];
        _accumulatedRoyalties[tokenId] += royaltyAmount;
        
        emit StreamingMinutesAdded(tokenId, streamedMinutes);
        emit RoyaltyAccumulated(tokenId, royaltyAmount);
        
        // Auto-distribute if threshold is met
        if (_autoDistributionThresholds[tokenId] > 0 && 
            _accumulatedRoyalties[tokenId] >= _autoDistributionThresholds[tokenId]) {
            _distributeRoyalties(tokenId, _accumulatedRoyalties[tokenId]);
            _accumulatedRoyalties[tokenId] = 0;
        }
    }

    /**
     * @dev Public wrapper for recording streaming minutes
     * @param tokenId The ID of the token
     * @param streamedMinutes The number of minutes streamed
     */
    function recordStreamingMinutes(uint256 tokenId, uint256 streamedMinutes) 
        external 
        onlyOwner 
    {
        _recordStreamingMinutes(tokenId, streamedMinutes);
    }

    /**
     * @dev Batch record streaming minutes for multiple tokens
     * @param tokenIds Array of token IDs
     * @param streamedMinutes Array of minutes streamed for each token
     */
    function batchRecordStreamingMinutes(uint256[] memory tokenIds, uint256[] memory streamedMinutes) 
        external 
        onlyOwner 
    {
        require(tokenIds.length == streamedMinutes.length, "Arrays length mismatch");
        
        for(uint i = 0; i < tokenIds.length; i++) {
            _recordStreamingMinutes(tokenIds[i], streamedMinutes[i]);
        }
    }
    
    /**
     * @dev Get streaming statistics for a token
     * @param tokenId The ID of the token
     * @return rate The streaming rate per minute
     * @return streamedMinutes Total minutes streamed
     * @return accumulated Accumulated undistributed royalties
     */
    function getStreamingStats(uint256 tokenId) 
        external 
        view 
        returns (uint256 rate, uint256 streamedMinutes, uint256 accumulated) 
    {
        return (
            _streamingRates[tokenId],
            _streamingMinutes[tokenId],
            _accumulatedRoyalties[tokenId]
        );
    }

    // View functions
    
    function getPayeeCount(uint256 tokenId) external view returns (uint256) {
        return _payees[tokenId].length;
    }
    
    function payeeInfo(uint256 tokenId, uint256 index) 
        external 
        view 
        returns (address payee, uint256 shares) 
    {
        require(index < _payees[tokenId].length, "Invalid index");
        PayeeInfo memory info = _payees[tokenId][index];
        return (info.payee, info.shares);
    }
    
    function getPayeeShares(uint256 tokenId, address payeeAddress) 
        external 
        view 
        returns (uint256) 
    {
        for(uint i = 0; i < _payees[tokenId].length; i++) {
            if(_payees[tokenId][i].payee == payeeAddress) {
                return _payees[tokenId][i].shares;
            }
        }
        revert("Payee not found");
    }
    
    function getAccumulatedRoyalties(uint256 tokenId) 
        external 
        view 
        returns (uint256) 
    {
        return _accumulatedRoyalties[tokenId];
    }
    
    function getAutoDistributionThreshold(uint256 tokenId) 
        external 
        view 
        returns (uint256) 
    {
        return _autoDistributionThresholds[tokenId];
    }
}
