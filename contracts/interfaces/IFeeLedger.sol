// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { FeeType } from "../primitives/Enums.sol";

/**
* @title IFeeLedger
* @notice External append-only ledger recording every fee accrual for off-chain audit.
*/
interface IFeeLedger {
    /**
     * @notice Authorizes a vault to submit fee accrual records.
     * @param vault The vault to authorize.
     */
    function authorizeVault(address vault) external;

    /**
     * @notice Revokes a vault's fee-record authorization.
     * @param vault The vault to revoke.
     */
    function revokeVault(address vault) external;

    /**
     * @notice Records a fee accrual event.
     * @param vault The vault emitting the fee.
     * @param feeType The category of fee accrued.
     * @param epochId The epoch the accrual is associated with (0 if not epoch-scoped).
     * @param amount The fee amount, denominated in the underlying asset.
     * @param recipient The address that received the fee.
     */
    function recordFee(address vault, FeeType feeType, uint256 epochId, uint256 amount, address recipient) external;
}
