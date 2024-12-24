# Contract Indexer REST API Todo List

## TDD Approach
- [x] Setup test environment
  - [x] Configure Jest/Mocha with TypeScript
  - [x] Setup supertest for API testing
  - [x] Configure test database
  - [x] Setup test coverage reporting
  - [x] Create test utilities and helpers

## 1. Project Setup (TDD First)
- [x] Create `/indexer` directory structure
  - [x] `/src` - Core application code
  - [x] `/tests` 
    - [x] `/unit` - Unit test suites
    - [x] `/integration` - Integration tests with supertest
    - [x] `/fixtures` - Test data and mocks
    - [x] `/helpers` - Test helper functions
  - [x] `/docs` - API documentation
  - [x] `/config` - Configuration files
  - [x] `/scripts` - Utility scripts

## 2. Core Infrastructure (Each with Tests First)
- [x] Express/FastAPI framework
  - [x] Write basic app test suite with supertest
  - [x] Test middleware chain
  - [x] Implement minimal app setup
  - [x] Test environment configuration
- [x] Database connection
  - [x] Write connection test suite
  - [x] Test connection pooling
  - [x] Implement database setup
- [x] Logging system
  - [x] Test logger interface
  - [x] Test log levels and formats
  - [x] Implement logging system
- [x] Error handling
  - [x] Test error middleware
  - [x] Test error responses
  - [x] Implement error handling
- [x] Security middleware
  - [x] Test CORS configuration
  - [x] Test rate limiting
  - [x] Implement security features

## 3. Database Schema (Test-First Approach)
- [ ] Design and test tables for:
  - [ ] Tracked contracts
    - [ ] Write schema tests
    - [ ] Test constraints
    - [ ] Implement schema
  - [ ] Events
    - [ ] Write event schema tests
    - [ ] Test indexing
    - [ ] Implement schema
  - [ ] Transactions
    - [ ] Write transaction tests
    - [ ] Test relationships
    - [ ] Implement schema
  - [ ] Block data
    - [ ] Write block schema tests
    - [ ] Test chain reorg handling
    - [ ] Implement schema
  - [ ] Metadata cache
    - [ ] Write cache tests
    - [ ] Test invalidation
    - [ ] Implement schema
  - [ ] Indexing status
    - [ ] Write status tests
    - [ ] Test state transitions
    - [ ] Implement schema

## 4. API Endpoints (TDD for Each Route)

### Contract Management
- [ ] POST /api/v1/contracts
  - [ ] Write contract creation tests
  - [ ] Test validation
  - [ ] Implement endpoint
- [ ] GET /api/v1/contracts
  - [ ] Write list contracts tests
  - [ ] Test pagination
  - [ ] Implement endpoint
- [ ] GET /api/v1/contracts/{address}
  - [ ] Write contract detail tests
  - [ ] Test not found cases
  - [ ] Implement endpoint
- [ ] DELETE /api/v1/contracts/{address}
  - [ ] Write deletion tests
  - [ ] Test cleanup
  - [ ] Implement endpoint

### Events
- [ ] GET /api/v1/events
  - [ ] Write event query tests
  - [ ] Test filtering
  - [ ] Implement endpoint
- [ ] GET /api/v1/events/{contractAddress}
  - [ ] Write contract events tests
  - [ ] Test pagination
  - [ ] Implement endpoint
- [ ] GET /api/v1/events/latest
  - [ ] Write latest events tests
  - [ ] Test ordering
  - [ ] Implement endpoint

### NFT Data
- [ ] GET /api/v1/nfts/{tokenId}
  - [ ] Write metadata tests
  - [ ] Test caching
  - [ ] Implement endpoint
- [ ] GET /api/v1/nfts/{tokenId}/history
  - [ ] Write history tests
  - [ ] Test timeline
  - [ ] Implement endpoint
- [ ] GET /api/v1/nfts/owner/{address}
  - [ ] Write ownership tests
  - [ ] Test batch retrieval
  - [ ] Implement endpoint

### Royalties & Revenue
- [ ] GET /api/v1/royalties/{tokenId}
  - [ ] Write royalty tests
  - [ ] Test calculations
  - [ ] Implement endpoint
- [ ] GET /api/v1/revenue/{artistAddress}
  - [ ] Write revenue tests
  - [ ] Test aggregations
  - [ ] Implement endpoint
- [ ] GET /api/v1/payouts/pending
  - [ ] Write payout tests
  - [ ] Test thresholds
  - [ ] Implement endpoint

### Statistics
- [ ] GET /api/v1/stats/global
  - [ ] Write global stats tests
  - [ ] Test performance
  - [ ] Implement endpoint
- [ ] GET /api/v1/stats/artist/{address}
  - [ ] Write artist stats tests
  - [ ] Test calculations
  - [ ] Implement endpoint
- [ ] GET /api/v1/stats/token/{tokenId}
  - [ ] Write token stats tests
  - [ ] Test metrics
  - [ ] Implement endpoint

### Indexer Status
- [x] GET /api/v1/indexer/health
  - [x] Write health check tests
  - [x] Test scenarios
  - [x] Implement endpoint
- [ ] GET /api/v1/indexer/status
  - [ ] Write status tests
  - [ ] Test states
  - [ ] Implement endpoint
- [ ] POST /api/v1/indexer/sync
  - [ ] Write sync tests
  - [ ] Test conflicts
  - [ ] Implement endpoint

## 5. Testing (Continuous)
- [x] Maintain 100% test coverage
- [x] Implement E2E test suite with supertest
- [ ] Setup continuous testing pipeline
- [ ] Implement performance test suite
- [ ] Create regression test suite

## 6. Documentation
- [ ] Document test patterns
- [ ] Document test data setup
- [ ] OpenAPI/Swagger documentation
- [ ] API usage examples
- [ ] Integration guide

## 7. Monitoring & Operations
- [ ] Test metrics collection
- [ ] Test alerting system
- [ ] Test backup procedures
- [ ] Test recovery scenarios
- [ ] Setup CI/CD with test gates

## 8. Security (Test-First)
- [ ] Test authentication
- [ ] Test authorization
- [ ] Test rate limiting
- [ ] Test request signing
- [ ] Test DoS protection

## 9. Performance Testing
- [ ] Test caching layer
- [ ] Test database indexes
- [ ] Test query performance
- [ ] Test pagination
- [ ] Test response compression

## 10. Launch Preparation
- [ ] Complete test suite review
- [ ] Performance test results
- [ ] Security test results
- [ ] API test documentation
- [ ] Backup and recovery test results