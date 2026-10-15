// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title IPriceOracleGuard
* @notice Pluggable NAV guardrail. Validates proposed totalAssets values against configurable bounds
*         (annualized drift, fixed bps deviation, oracle cross-check, etc.).
*/
interface IPriceOracleGuard {
    /**
    * @notice Validates a proposed NAV against the guard's policy.
    * @dev Reverts if the proposal falls outside allowed bounds. Returns silently on success.
    * @param previousTotalAssets The current (flow-inclusive) NAV, used to compute the real asset delta.
    * @param proposedTotalAssets The new NAV being proposed.
    * @param referenceTotalAssets The NAV as of the last commit, before any subsequent deposit/redeem
    *        settlement. Used as the percentage base for the annualized drift check so that flows
    *        occurring between commits cannot dilute (mask) a genuine price change.
    * @param elapsedSeconds Seconds since the last commit.
    */
    function validateNavProposal(
        uint256 previousTotalAssets,
        uint256 proposedTotalAssets,
        uint256 referenceTotalAssets,
        uint256 elapsedSeconds
    ) external view;
}
