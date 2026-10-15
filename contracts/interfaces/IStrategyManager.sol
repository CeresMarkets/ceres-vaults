// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { StrategyParams } from "../primitives/Types.sol";

/**
* @title IStrategyManager
* @notice Surface exposed by the on-chain strategy allocator to the vault.
*/
interface IStrategyManager {
    /**
    * @notice Registers a new strategy with an initial debt cap.
    * @param strategy The address of the strategy contract.
    * @param debtCap The maximum amount of assets that can be allocated to this strategy.
    */
    function addStrategy(address strategy, uint256 debtCap) external;

    /**
    * @notice Removes a strategy after fully divesting it.
    * @param strategy The address of the strategy contract to remove.
    */
    function removeStrategy(address strategy) external;

    /**
    * @notice Updates the debt cap of an existing strategy.
    * @param strategy The address of the strategy contract.
    * @param newCap The new debt cap for the strategy.
    */
    function setStrategyDebtCap(address strategy, uint256 newCap) external;

    /**
    * @notice Deploys idle vault assets into a strategy, up to its remaining debt cap.
    * @param strategy The address of the strategy contract.
    * @param assets The amount of assets to deploy.
    */
    function deployToStrategy(address strategy, uint256 assets) external;

    /**
    * @notice Recalls assets from a strategy back to the vault.
    * @param strategy The address of the strategy contract.
    * @param assets The amount of assets to recall.
    * @return recalled The actual amount recalled from the strategy.
    */
    function recallFromStrategy(address strategy, uint256 assets) external returns (uint256 recalled);

    /**
    * @notice Triggers a strategy harvest, updating debt bookkeeping.
    * @param strategy The address of the strategy contract.
    * @return profit The amount of profit realized by the strategy.
    * @return loss The amount of loss realized by the strategy.
    */
    function harvestStrategy(address strategy) external returns (uint256 profit, uint256 loss);

    /**
    * @notice Emergency divestment of a strategy's full position.
    * @param strategy The address of the strategy contract.
    * @return recovered The amount of assets recovered from the strategy.
    */
    function emergencyExitStrategy(address strategy) external returns (uint256 recovered);

    /**
    * @notice Returns the aggregate assets under management across all registered strategies.
    * @return The total assets managed by all strategies.
    */
    function totalStrategyAssets() external view returns (uint256);

    /**
    * @notice Returns the parameters of a registered strategy.
    * @param strategy The address of the strategy contract.
    * @return The StrategyParams struct containing the strategy's parameters.
    */
    function getStrategyParams(address strategy) external view returns (StrategyParams memory);

    /**
    * @notice Returns the ordered list of registered strategies.
    * @return An array of strategy addresses in the order they were registered.
    */
    function getStrategies() external view returns (address[] memory);
}
