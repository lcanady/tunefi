# TuneFi Test Suites Documentation

## Overview
This document provides detailed information about the test suites in the TuneFi project. Each contract has its own comprehensive test suite following Test-Driven Development (TDD) principles.

## Test Suites

### 1. MusicNFT Tests (`test/MusicNFT.t.sol`)

#### Core Functionality Tests
- `test_InitialState`: Verifies correct contract initialization and owner assignment
- `test_SupportsInterface`: Confirms support for ERC1155 and ERC2981 interfaces
- `test_CreateTrack`: Tests basic track creation functionality
- `test_CreateTrackWithCollaborators`: Verifies collaborative track creation with multiple artists
- `test_MetadataUpdate`: Tests track metadata update functionality
- `test_TrackVersionHistory`: Validates version history tracking for tracks

#### Album Management Tests
- `test_CreateAlbumWithDiscount`: Tests album creation with discount pricing
- `test_CreateAndPurchaseAlbum`: Validates complete album purchase workflow
- `test_CreateBatchAlbums`: Tests batch creation of multiple albums
- `test_UpdateAlbumUri`: Verifies album metadata update functionality

#### Licensing and Royalties Tests
- `test_CreateAndPurchaseLicense`: Tests license creation and purchase workflow
- `test_DistributeRoyalties`: Validates royalty distribution among collaborators
- `test_RoyaltyInfo`: Verifies correct royalty calculations
- `test_PurchaseTrackWithRoyalty`: Tests complete purchase flow with royalties

#### Failure Cases
- `testFail_CreateInvalidLicense`: Validates license creation restrictions
- `testFail_PurchaseInactiveLicense`: Tests inactive license purchase prevention
- `testFail_PurchaseTrackInsufficientFunds`: Verifies insufficient funds handling
- `testFail_UnauthorizedMetadataUpdate`: Tests unauthorized metadata update prevention
- `testFail_UpdateAlbumUriUnauthorized`: Validates album update authorization

### 2. RecommendationGraph Tests (`test/RecommendationGraph.t.sol`)

#### Graph Structure Tests
- `testAddTrackNode`: Validates track node addition to the graph
- `testAddArtistNode`: Tests artist node creation
- `testTrackToTrackRelationship`: Verifies relationship creation between tracks

#### Recommendation Algorithm Tests
- `testCollaborativeFiltering`: Tests the recommendation algorithm's effectiveness
- `testUserToTrackInteraction`: Validates user interaction recording
- `testConcurrentInteractions`: Tests system behavior under concurrent usage

#### Security Tests
- `testAccessControl`: Verifies proper access control implementation

### 3. TuneToken Tests (`test/TuneToken.t.sol`)

#### Core Token Tests
- `test_InitialState`: Verifies token initialization
- `test_Transfer`: Tests basic token transfer functionality
- `test_TransferFrom`: Validates delegated transfer functionality

#### Vesting Tests
- `test_CreateVestingSchedule`: Tests vesting schedule creation
- `test_VestedAmount`: Verifies vesting amount calculations
- `test_ReleaseVestedTokens`: Tests token release functionality
- `test_RevokeVesting`: Validates vesting revocation functionality

#### Failure Cases
- `testFail_CreateDuplicateVesting`: Tests duplicate vesting prevention
- `testFail_RevokeNonRevocableVesting`: Validates revocation restrictions
- `testFail_UnauthorizedRevoke`: Tests unauthorized revocation prevention

## Test Coverage

### MusicNFT Contract
- Functions: 100% coverage
- Lines: 100% coverage
- Branches: 100% coverage

### RecommendationGraph Contract
- Functions: 100% coverage
- Lines: 100% coverage
- Branches: 100% coverage

### TuneToken Contract
- Functions: 100% coverage
- Lines: 100% coverage
- Branches: 100% coverage

## Running Tests

To run all tests:
```bash
forge test
```

To run a specific test suite:
```bash
forge test --match-path test/MusicNFT.t.sol
forge test --match-path test/RecommendationGraph.t.sol
forge test --match-path test/TuneToken.t.sol
```

To run with detailed output:
```bash
forge test -vv
```

## Test Patterns

### Setup Pattern
Each test contract follows a consistent setup pattern:
1. Contract deployment in `setUp()`
2. Initial state verification
3. Test-specific setup within each test function

### Failure Testing Pattern
Failure tests use the `testFail_` prefix and verify:
1. Proper revert messages
2. State remains unchanged after failure
3. Correct access control enforcement

### Event Testing Pattern
Event tests verify:
1. Correct event emission
2. Accurate event parameters
3. Event ordering where relevant
