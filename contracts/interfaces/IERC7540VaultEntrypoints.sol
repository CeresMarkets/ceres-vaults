// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

interface IERC7540VaultEntrypoints {
    event Deposit(address indexed caller, address indexed receiver, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    error ZeroAmount();
    error InvalidPrice();
    error MustClaimFirst(uint256 pendingEpochId);
    error NothingToClaim(address controller);
    error InsufficientBacking(uint256 required, uint256 available);
    error CallerNotOperator(address caller, address controller);
    error StrategyManagerNotSet();
    error StrategyRecallShortfall(uint256 requested, uint256 recovered);

    function requestDeposit(uint256 assets, address controller, address owner) external returns (uint256);
    function cancelDepositRequest() external;
    function settleDepositEpoch(uint256 pricePerShare) external;
    function forceSettleDepositEpoch() external;
    function deposit(uint256 assets, address receiver, address controller) external returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function mint(uint256 shares, address receiver, address controller) external returns (uint256);
    function mint(uint256 shares, address receiver) external returns (uint256);
    function claimAndRequestDeposit(uint256 assets, address controller, address owner) external returns (uint256, uint256);
    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256);
    function cancelRedeemRequest() external;
    function settleRedeemEpoch(uint256 pricePerShare) external;
    function settleRedeemEpoch(uint256 pricePerShare, uint256 maxControllers) external;
    function forceSettleRedeemEpoch() external;
    function forceSettleRedeemEpoch(uint256 maxControllers) external;
    function redeem(uint256 shares, address receiver, address controller) external returns (uint256);
    function withdraw(uint256 assets, address receiver, address controller) external returns (uint256);
    function setOperator(address operator, bool approved) external returns (bool);
    function deployToStrategy(uint256 assets, address strategy) external;
    function recallFromStrategy(uint256 assets, address strategy) external returns (uint256);
    function recallFromStrategyBestEffort(uint256 assets, address strategy) external returns (uint256);
    function harvestStrategy(address strategy) external returns (uint256, uint256);
}