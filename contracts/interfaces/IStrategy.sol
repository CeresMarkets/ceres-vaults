// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { StrategySettlementMode } from "../primitives/Enums.sol";

/**
* @title IStrategy
* @notice Minimum surface a strategy contract must expose to be managed by StrategyManager.
* @dev Each strategy encapsulates exactly one external protocol integration.
*/
interface IStrategy {
    /// @notice Returns the address of the vault that this strategy serves.
    function vault() external view returns (address);

    /// @notice Returns the underlying asset the strategy accepts.
    function asset() external view returns (address);

    /// @notice Returns whether the strategy is synchronous (unwinds atomically) or asynchronous.
    function settlementMode() external view returns (StrategySettlementMode);

    /// @notice Returns the current value of the strategy's holdings, denominated in the underlying asset.
    function totalAssets() external view returns (uint256);

    /**
    * @notice Deploys `assets` from the vault into the strategy.
    * @param assets The amount of the underlying asset to invest.
    */
    function invest(uint256 assets) external;

    /**
    * @notice Withdraws up to `assets` back to the vault.
    * @param assets The requested withdrawal amount.
    * @return withdrawn The actual amount withdrawn (may be less on illiquid strategies).
    */
    function divest(uint256 assets) external returns (uint256 withdrawn);

    /**
    * @notice Realizes accrued rewards or interest, returning any freed assets to the vault.
    * @return profit Any profit realized during the harvest.
    * @return loss Any loss recognized during the harvest.
    */
    function harvest() external returns (uint256 profit, uint256 loss);

    /**
    * @notice Emergency divestment of the full position.
    * @return recovered The amount of underlying asset recovered.
    */
    function emergencyExit() external returns (uint256 recovered);
}
