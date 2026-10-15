// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title EpochState
* @notice Enumerates the possible states of a vault epoch.
* @dev  - None: The epoch has not been opened yet.
*       - Open: The epoch is currently open for deposits and redemptions.
*       - Settled: The epoch has been settled and is no longer accepting deposits or redemptions.
*/
enum EpochState {
    None,
    Open,
    Settled
}

/**
* @title VaultMode
* @notice Enumerates the possible modes of a vault.
* @dev  - SyncOnly: The vault only supports synchronous deposits and redemptions.
*       - AsyncOnly: The vault only supports asynchronous deposits and redemptions.
*/
enum VaultMode {
    SyncOnly,
    AsyncOnly
}

/**
* @title StrategySettlementMode
* @notice Enumerates the possible settlement modes of a strategy.
* @dev  - Sync: The strategy settles synchronously.
*       - Async: The strategy settles asynchronously.
*/
enum StrategySettlementMode {
    Sync,
    Async
}

/**
* @title FeeType
* @notice Enumerates the possible types of fees in the vault protocol.
* @dev  - Management: Management fee.
*       - Performance: Performance fee.
*       - Entry: Entry fee.
*       - Exit: Exit fee.
*       - Haircut: Haircut fee.
*       - Protocol: Protocol fee.
*/
enum FeeType {
    Management,
    Performance,
    Entry,
    Exit,
    Haircut,
    Protocol
}
