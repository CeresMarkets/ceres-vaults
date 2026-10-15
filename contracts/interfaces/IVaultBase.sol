// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { VaultMode } from "../primitives/Enums.sol";
import { FeeRates, NavCommitment, EpochLifecycleConfig } from "../primitives/Types.sol";

/**
 * @title IVaultBase
 * @notice Common surface exposed by every vault (sync or async) built on VaultBase.
 */
interface IVaultBase {
    function initialize(
        address underlyingAsset_,
        string memory name_,
        string memory symbol_,
        address initialAdmin_,
        address guardian_,
        address operator_,
        address feeRecipient_,
        address protocolFeeRecipient_,
        FeeRates memory feeRates_,
        EpochLifecycleConfig memory config_,
        uint256 maxCap_
    ) external;

    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);

    function getVaultMode() external view returns (VaultMode);

    function getFeeRates() external view returns (FeeRates memory);

    function getMaxCap() external view returns (uint256);

    function getIdleAssets() external view returns (uint256);

    function isNavFresh() external view returns (bool);

    function getPendingNavCommitment() external view returns (NavCommitment memory);
}
