// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { TuneToken } from "../src/TuneToken.sol";
import { TuneFiGovernor } from "../src/Governor.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

contract GovernanceTest is Test {
    TuneToken public token;
    TuneFiGovernor public governor;
    TimelockController public timelock;

    address public admin = address(1);
    address public proposer = address(2);
    address public executor = address(3);
    address public voter1 = address(4);
    address public voter2 = address(5);

    uint256 public constant MIN_DELAY = 2 days;
    uint256 public constant VOTING_DELAY = 1; // 1 block
    uint256 public constant VOTING_PERIOD = 50_400; // About 1 week
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of total supply
    uint256 public constant PROPOSAL_THRESHOLD = 1000e18; // 1000 TUNE tokens

    function setUp() public {
        // Deploy TuneToken
        vm.startPrank(admin);
        token = new TuneToken();

        // Setup timelock roles
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = proposer;
        executors[0] = executor;

        // Deploy Timelock
        timelock = new TimelockController(MIN_DELAY, proposers, executors, admin);

        // Deploy Governor
        governor =
            new TuneFiGovernor(token, timelock, VOTING_DELAY, VOTING_PERIOD, PROPOSAL_THRESHOLD, QUORUM_PERCENTAGE);

        // Setup roles
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // Anyone can execute
        timelock.revokeRole(adminRole, admin);

        // Distribute tokens for testing - ensure enough tokens to meet quorum
        token.transfer(voter1, 20_000_000e18); // 20M tokens
        token.transfer(voter2, 30_000_000e18); // 30M tokens
        token.transfer(proposer, 2_000_000e18); // 2M tokens
        token.transfer(address(timelock), 1_000_000e18); // Give timelock 1M tokens for executing proposals
        vm.stopPrank();

        // Delegate voting power
        vm.startPrank(voter1);
        token.delegate(voter1);
        vm.stopPrank();

        vm.startPrank(voter2);
        token.delegate(voter2);
        vm.stopPrank();

        vm.startPrank(proposer);
        token.delegate(proposer);
        vm.stopPrank();

        // Move forward one block to ensure voting power is active
        vm.roll(block.number + 1);
    }

    function test_ProposalCreation() public {
        vm.startPrank(proposer);

        // Prepare proposal data
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Test Proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", proposer, 100e18);

        // Create proposal
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertGt(proposalId, 0, "Proposal should be created with valid ID");
        vm.stopPrank();
    }

    function test_VotingProcess() public {
        // Create proposal
        vm.startPrank(proposer);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Test Proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", proposer, 100e18);

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        vm.stopPrank();

        // Wait for voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote
        vm.startPrank(voter1);
        governor.castVote(proposalId, 1); // Vote in favor
        vm.stopPrank();

        vm.startPrank(voter2);
        governor.castVote(proposalId, 1); // Vote in favor
        vm.stopPrank();

        // Wait for voting period to end
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Check proposal state
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Succeeded));
    }

    function test_ProposalExecution() public {
        // Create and vote on proposal
        vm.startPrank(proposer);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Test Proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", proposer, 100e18);

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        vm.stopPrank();

        // Wait for voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote
        vm.startPrank(voter1);
        governor.castVote(proposalId, 1);
        vm.stopPrank();

        vm.startPrank(voter2);
        governor.castVote(proposalId, 1);
        vm.stopPrank();

        // Wait for voting period to end
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Queue proposal
        bytes32 descriptionHash = keccak256(bytes(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // Wait for timelock
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // Execute
        governor.execute(targets, values, calldatas, descriptionHash);

        // Verify execution
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Executed));
    }

    function test_DelegateVoting() public {
        // Initial delegation
        vm.startPrank(voter1);
        token.delegate(voter2);
        vm.stopPrank();

        // Move forward one block to ensure voting power is active
        vm.roll(block.number + 1);

        // Create proposal
        vm.startPrank(proposer);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Test Proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("transfer(address,uint256)", proposer, 100e18);

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        vm.stopPrank();

        // Wait for voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote with delegated power
        vm.startPrank(voter2);
        governor.castVote(proposalId, 1);
        vm.stopPrank();

        // Wait for voting period to end
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Check proposal state
        assertEq(uint256(governor.state(proposalId)), uint256(IGovernor.ProposalState.Succeeded));
    }
}
