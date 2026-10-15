// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title INavCancellable
* @notice Minimal surface for a vault that exposes `cancelNavProposal`.
*/
interface INavCancellable {
    function cancelNavProposal() external;
}