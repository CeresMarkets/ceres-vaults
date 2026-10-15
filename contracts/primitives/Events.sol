// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { FeeRates } from "./Types.sol";

event DepositEpochSettled(
    uint256 indexed epochId,
    uint256 totalAssetsDeposited,
    uint256 totalSharesMinted,
    uint256 pricePerShare
);

event RedeemEpochSettled(
    uint256 indexed epochId,
    uint256 totalSharesRedeemed,
    uint256 totalAssetsWithdrawn,
    uint256 pricePerShare
);

event DepositEpochOpened(uint256 indexed epochId, uint256 openedAt);
event RedeemEpochOpened(uint256 indexed epochId, uint256 openedAt);

event CancelDepositRequest(
    address indexed sender,
    uint256 epochId,
    uint256 assets
);

event CancelRedeemRequest(
    address indexed controller,
    uint256 indexed epochId,
    uint256 shares
);

event UpdateMinDepositRequest(uint256 previousMin, uint256 newMin);

event UpdateMinRedeemRequest(uint256 previousMin, uint256 newMin);

event ProposeNAV(uint256 newTotalAssets, uint256 committableAt);
event CommitNAV(uint256 totalAssets, uint256 committedAt);
event CancelNavProposal(address indexed canceller, uint256 cancelledAt);

event OperatorSet(address indexed controller, address indexed operator, bool approved);
event ChangeVaultMode(uint8 previousMode, uint8 newMode);

event PauseGuardian(address indexed guardian);
event UnpauseGuardian(address indexed guardian);

event StrategyAdded(address indexed strategy, uint256 debtCap);
event StrategyRemoved(address indexed strategy);
event StrategyReported(address indexed strategy, uint256 profit, uint256 loss, uint256 debt);

event UpdateFeeRates(FeeRates newRates);
event UpdateFeeRecipient(address indexed previousRecipient, address indexed newRecipient);
event UpdateProtocolFeeRecipient(address indexed previousRecipient, address indexed newRecipient);

event UpdateAccessRegistry(address indexed previousRegistry, address indexed newRegistry);
event UpdatePriceOracleGuard(address indexed previousGuard, address indexed newGuard);
event UpdateFeeLedger(address indexed previousLedger, address indexed newLedger);
event UpdateStrategyManager(address indexed previousManager, address indexed newManager);

event UpdateMaxCap(uint256 previousCap, uint256 newCap);
event UpdateMaxNavStaleness(uint256 previousStaleness, uint256 newStaleness);
event UpdateNavCommitDelay(uint256 previousDelay, uint256 newDelay);

event UpdateMaxEpochDuration(uint256 previousDuration, uint256 newDuration);
event ForceSettlementTriggered(address indexed caller, uint256 indexed epochId, bool isDepositStream);
event RecoverERC20(address indexed token, address indexed to, uint256 amount);

event AssetsDeployedToStrategy(address indexed strategy, uint256 assets);
event AssetsRecalledFromStrategy(address indexed strategy, uint256 requested, uint256 recovered);
