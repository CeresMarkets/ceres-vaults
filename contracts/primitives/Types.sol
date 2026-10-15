// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VaultMode} from "./Enums.sol";

/**
* @title DepositEpoch
* @notice Represents the state and data of a deposit epoch in the vault.
* @dev  - totalAssetsDeposited: Total assets deposited in this epoch.
*       - totalSharesMinted: Total shares minted in this epoch.
*       - pricePerShare: Price per share at the time of settlement.
*       - openedAt: Timestamp when the epoch was opened.
*       - settledAt: Timestamp when the epoch was settled.
*       - state: Current state of the epoch (None, Open, Settled).
*       - lastRequestBlock: Block number of the most recent requestDeposit against this epoch.
*/
struct DepositEpoch {
    uint128 totalAssetsDeposited;
    uint128 totalSharesMinted;
    uint256 pricePerShare;
    uint64 openedAt;
    uint64 settledAt;
    uint8 state;
    uint64 lastRequestBlock;
}

/**
* @title RedeemEpoch
* @notice Represents the state and data of a redeem epoch in the vault.
* @dev  - totalSharesRedeemed: Total shares redeemed in this epoch.
*       - totalAssetsWithdrawn: Total assets withdrawn in this epoch.
*       - pricePerShare: Price per share at the time of settlement.
*       - openedAt: Timestamp when the epoch was opened.
*       - settledAt: Timestamp when the epoch was settled.
*       - state: Current state of the epoch (None, Open, Settled).
*       - lastRequestBlock: Block number of the most recent requestRedeem against this epoch.
*/
struct RedeemEpoch {
    uint128 totalSharesRedeemed;
    uint128 totalAssetsWithdrawn;
    uint256 pricePerShare;
    uint64 openedAt;
    uint64 settledAt;
    uint8 state;
    uint64 lastRequestBlock;
    // Appended partial-redemption totals preserve the original field slots.
    uint128 totalSharesFilled;
    uint128 totalAssetsFilled;
}

/**
* @title FeeRates
* @notice Represents the fee rates for different types of fees in the vault.
* @dev  - managementBps: Management fee in basis points.
*       - performanceBps: Performance fee in basis points.
*       - entryBps: Entry fee in basis points.
*       - exitBps: Exit fee in basis points.
*       - haircutBps: Haircut fee in basis points.
*       - protocolBps: Protocol fee in basis points.
*/
struct FeeRates {
    uint16 managementBps;
    uint16 performanceBps;
    uint16 entryBps;
    uint16 exitBps;
    uint16 haircutBps;
    uint16 protocolBps;
}

/**
* @title NavCommitment
* @notice Represents a proposed change to the vault's net asset value (NAV).
* @dev  - proposedTotalAssets: The proposed total assets for the vault.
*       - proposedAt: Timestamp when the proposal was made.
*       - committableAt: Timestamp when the proposal can be committed.
*       - pending: Indicates if the proposal is still pending.
*/
struct NavCommitment {
    uint256 proposedTotalAssets;
    uint64 proposedAt;
    uint64 committableAt;
    bool pending;
    uint256 assetsAddedAfterProposal;
    uint256 assetsRemovedAfterProposal;
}

/**
* @title StrategyParams
* @notice Represents the parameters and state of a strategy.
* @dev  - debtCap: Maximum debt the strategy can take.
*       - currentDebt: Current debt of the strategy.
*       - lastReport: Timestamp of the last report from the strategy.
*       - active: Indicates if the strategy is active.
*/
struct StrategyParams {
    uint256 debtCap;
    uint256 currentDebt;
    uint256 lastReport;
    bool active;
}

/**
* @title EpochLifecycleConfig
* @notice Represents the configuration parameters for the lifecycle of a vault epoch.
* @dev  - maxEpochDuration: Maximum duration of an epoch.
*       - maxNavStaleness: Maximum staleness allowed for the NAV.
*       - navCommitDelay: Delay before a NAV commitment can be applied.
*       - minDepositRequest: Minimum deposit request amount.
*       - minRedeemRequest: Minimum redeem request amount.
*/
struct EpochLifecycleConfig {
    uint256 maxEpochDuration;
    uint256 maxNavStaleness;
    uint256 navCommitDelay;
    uint256 minDepositRequest;
    uint256 minRedeemRequest;
}

/**
* @title UserDepositPosition
* @notice Represents a user's deposit position in a specific epoch.
* @dev  - epochId: The ID of the epoch.
*       - assets: The amount of assets deposited by the user.
*/
struct UserDepositPosition {
    uint256 epochId;
    uint256 assets;
}

/**
* @title UserRedeemPosition
* @notice Represents a user's redeem position in a specific epoch.
* @dev  - epochId: The ID of the epoch.
*       - shares: The amount of shares the user wants to redeem.
*/
struct UserRedeemPosition {
    uint256 epochId;
    uint256 shares;
}



/**
* @dev Storage layout for the Vault Base.
* - underlyingAsset: The vault's underlying ERC-20.
* - underlyingDecimals: The decimals of the underlying asset.
* - decimals: The decimals of the vault's shares.
* - decimalsOffset: The virtual-shares offset used by the vault.
* - vaultMode: The vault's current mode (SyncOnly / AsyncOnly).
* - totalManagedAssets: The total assets under management (AUM) after the latest NAV update and epoch settlements.
* - idleAssets: The assets currently idle in the vault.
* - navCommitment: The current NAV commitment.
* - lastNavUpdateAt: The timestamp of the last NAV update.
* - maxNavStaleness: The maximum allowed staleness for the NAV.
* - navCommitDelay: The delay required for NAV commit-reveal.
* - feeRates: The current fee rates.
* - feeRecipient: The recipient of the management and performance fees.
* - protocolFeeRecipient: The recipient of the protocol fees.
* - accessRegistry: The address of the access registry contract.
* - priceOracleGuard: The address of the price oracle guard contract.
* - feeLedger: The address of the fee ledger contract.
* - maxCap: The maximum cap for the vault.
* - strategyManager: The address of the strategy manager contract.
* - highWaterMark: The last recorded high pricePerShare (PRICE_PRECISION units).
* - lastFeeAccrualAt: The timestamp of the last management-fee accrual.
* - lastCommittedTotalAssets: totalManagedAssets as of the last commitNav, before any subsequent
*   flow-driven settlement mutates it. Used as the undiluted percentage base for drift checks.
*/
struct VaultBaseStorage {
    IERC20 underlyingAsset;
    uint8 underlyingDecimals;
    uint8 decimals;
    uint8 decimalsOffset;
    VaultMode vaultMode;
    uint256 totalManagedAssets;
    uint256 idleAssets;
    NavCommitment navCommitment;
    uint256 lastNavUpdateAt;
    uint256 maxNavStaleness;
    uint256 navCommitDelay;
    FeeRates feeRates;
    address feeRecipient;
    address protocolFeeRecipient;
    address accessRegistry;
    address priceOracleGuard;
    address feeLedger;
    uint256 maxCap;
    address strategyManager;
    uint256 highWaterMark;      // last recorded high pricePerShare (PRICE_PRECISION units)
    uint256 lastFeeAccrualAt;   // timestamp of last management-fee accrual
    uint256 lastCommittedTotalAssets;
}

/**
* @title ERC7540EpochVaultStorage
* @notice Represents the storage layout for an ERC-7540 compliant epoch vault.
* @dev  - currentDepositEpochId: The ID of the current deposit epoch.
*       - depositEpochs: Mapping of deposit epochs by their ID.
*       - depositRequestByEpoch: Mapping of deposit requests by epoch ID and user address.
*       - lastDepositEpochId: Mapping of the last deposit epoch ID for each user.
*       - currentRedeemEpochId: The ID of the current redeem epoch.
*       - redeemEpochs: Mapping of redeem epochs by their ID.
*       - redeemRequestByEpoch: Mapping of redeem requests by epoch ID and user address.
*       - lastRedeemEpochId: Mapping of the last redeem epoch ID for each user.
*       - operatorApprovals: Mapping of operator approvals for delegation (EIP-7540).
*       - maxEpochDuration: Maximum duration of an epoch.
*       - minDepositRequest: Minimum deposit request amount.
*       - minRedeemRequest: Minimum redeem request amount.
*       - pendingDepositAssets: Total pending deposit assets.
*       - pendingRedeemShares: Total pending redeem shares.
*       - claimableRedeemAssets: Total claimable assets from settled but unclaimed red
*/
struct ERC7540EpochVaultStorage {
    // Deposit stream
    uint256 currentDepositEpochId;
    mapping(uint256 => DepositEpoch) depositEpochs;
    mapping(uint256 => mapping(address => uint256)) depositRequestByEpoch;
    mapping(address => uint256) lastDepositEpochId;
    // Redeem stream
    uint256 currentRedeemEpochId;
    mapping(uint256 => RedeemEpoch) redeemEpochs;
    mapping(uint256 => mapping(address => uint256)) redeemRequestByEpoch;
    mapping(address => uint256) lastRedeemEpochId;
    // Operator delegation (EIP-7540)
    mapping(address => mapping(address => bool)) operatorApprovals;
    // Lifecycle configuration
    uint256 maxEpochDuration;
    uint256 minDepositRequest;
    uint256 minRedeemRequest;
    // Pending pool bookkeeping
    uint256 pendingDepositAssets;
    uint256 pendingRedeemShares;
    // Reserved asset obligations from settled-but-unclaimed redemptions.
    uint256 claimableRedeemAssets;
    // Partial-redemption bookkeeping. These fields are appended for storage compatibility.
    mapping(uint256 => address[]) redeemControllers;
    mapping(uint256 => mapping(address => uint256)) redeemFilledSharesByController;
    mapping(uint256 => mapping(address => uint256)) redeemClaimableAssetsByController;
}
