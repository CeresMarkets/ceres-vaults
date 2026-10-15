// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

import { BelowMinimum, AboveMaximum } from "../primitives/Errors.sol";
import { requireLocalDevChain } from "../primitives/SnapshotGuard.sol";

/**
* @title TimelockedGovernor
* @notice Governance role holder gated behind a delay-based timelock.
* @dev  Thin wrapper around OpenZeppelin's `TimelockController`. It is intended to hold the
*        `DEFAULT_ADMIN_ROLE` on every vault-protocol contract (vaults, strategies, strategy managers,
*        access registries, price oracle guards, guardian).
*
*        The timelock enforces a minimum delay between proposal and execution. Standard OZ role model:
*          - `TIMELOCK_ADMIN_ROLE` (address(this)) — self-administers
*          - `PROPOSER_ROLE`                       — queue operations
*          - `EXECUTOR_ROLE`                       — execute after the delay
*          - `CANCELLER_ROLE`                      — cancel a pending proposal
*
*        Non-upgradeable by design: the whole point of a timelock is that it cannot itself be
*        upgraded in place. If governance topology must change, deploy a new timelock and rotate
*        the admin role on the managed contracts through the existing timelock.
*
*        Bounded minimum delay to prevent misconfiguration at deployment.
*/
contract TimelockedGovernor is TimelockController {
    /** @notice Minimum permissible delay. Anything below is refused at construction to prevent
     *          governance from being deployed without meaningful `_review_` time.
     */
    uint256 public constant MIN_DELAY_SECONDS = 1 hours;

    /** 
    * @notice Maximum permissible delay.
    *         Prevents governance from being locked out effectively forever.
    */
    uint256 public constant MAX_DELAY_SECONDS = 30 days;

    /**
    * @notice Deploys the timelocked governor.
    * @param _minDelay The minimum delay in seconds between propose and execute. Must lie within
    *                 [MIN_DELAY_SECONDS, MAX_DELAY_SECONDS].
    * @param _proposers Addresses granted PROPOSER_ROLE (and CANCELLER_ROLE per OZ default).
    * @param _executors Addresses granted EXECUTOR_ROLE. Pass `address(0)` in the array to allow any
    *                  address to execute (public execution — common in DAOs where the mempool acts
    *                  as an execution keeper).
    * @param _admin Initial admin (typically address(0) so only the timelock itself can administer;
    *              or a bootstrap multi-sig that later renounces).
    */
    constructor(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors,
        address _admin
    ) TimelockController(_validateDelay(_minDelay), _proposers, _executors, _admin) {
        requireLocalDevChain();
    }

    /**
    * @dev Applies the min/max delay bounds. Reverts with custom errors so failures surface
    *      through the shared error surface rather than string-typed reverts.
    * @param _minDelay The minimum delay to validate.
    */
    function _validateDelay(uint256 _minDelay) private pure returns (uint256) {
        if (_minDelay < MIN_DELAY_SECONDS) revert BelowMinimum(_minDelay, MIN_DELAY_SECONDS);
        if (_minDelay > MAX_DELAY_SECONDS) revert AboveMaximum(_minDelay, MAX_DELAY_SECONDS);
        return _minDelay;
    }
}
