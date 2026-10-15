// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/// @dev Chain id of the local development network (Hardhat, Anvil).
uint256 constant LOCAL_DEV_CHAIN_ID = 31337;

/// @dev Thrown when a contract from this snapshot is deployed or initialized on any other chain.
error EvaluationSnapshotOnly(uint256 chainId);

/**
* @dev Reverts unless executing on the local development network.
*      This repository is a review snapshot, not a release. Its contracts call this guard
*      at construction and initialization, so they cannot be brought up on a public network.
*/
function requireLocalDevChain() view {
    if (block.chainid != LOCAL_DEV_CHAIN_ID) revert EvaluationSnapshotOnly(block.chainid);
}
