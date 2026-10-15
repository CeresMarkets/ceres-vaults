# Ceres Vaults

Ceres is a loans and trade finance application built on the Aperta vault SDK.

This repository is a work-in-progress snapshot of the vault layer Ceres runs on. It is partial by design. It contains the shared types, the interfaces, the pricing and fee math, and the access and governance modules. The core vault contracts, the factory, the strategy layer and the deployment tooling are still in development and review, and are not part of this snapshot.

## Status

Testnet stage (Sepolia). Unaudited. Not for production use.

This snapshot is for review only. Its contracts are locked to the local development network: construction and initialization revert with `EvaluationSnapshotOnly` on any other chain (see `contracts/primitives/SnapshotGuard.sol`).

## What is in this repository

| Path | Contents |
|---|---|
| `contracts/primitives/` | File-level constants, enums, errors, events and storage types shared by every contract |
| `contracts/interfaces/` | External surface of the vaults (ERC-7540 deposit, redeem and operator flows), the strategy layer and the pluggable modules |
| `contracts/libraries/` | `EpochLib` and `FeeLib`: side-effect-free math for epoch settlement pricing and fee accrual |
| `contracts/governance/` | `AccessRegistry` (open, allowlist and blocklist gating), `TimelockedGovernor` (bounded-delay timelock), `FeeLedger` (append-only fee record) |
| `test/unit/` | Unit tests for `AccessRegistry` and `TimelockedGovernor` |
| `docs/` | Epoch lifecycle and fee model |

## What is not in this snapshot

- The vault core and the two vault types (synchronous ERC-4626 and asynchronous, epoch-based ERC-7540), including the deposit, redeem and strategy modules
- The vault factory
- The strategy manager and the strategies
- The guardian and the valuation guard (their interfaces are included)
- Deployment and upgrade scripts

## Design in brief

- **Two standards, one codebase.** ERC-4626 for atomic deposits and redemptions, ERC-7540 for the request, settle and claim lifecycle used when a strategy cannot be unwound atomically.
- **Independent deposit and redeem streams.** Each stream has its own epoch counter and settles at a single price per epoch. Settlement opens the next epoch in the same call. See `docs/EPOCH_LIFECYCLE.md`.
- **Two-step valuation.** A new valuation is proposed, waits a delay, then is committed.
- **Fees as shares.** Management, performance, entry and exit fees are minted as shares to the recipients, with a protocol split taken from each fee. See `docs/FEE_MODEL.md`.
- **Access gating.** A per-vault registry with open, allowlist and blocklist modes.
- **Upgradeable storage.** UUPS proxies with ERC-7201 namespaced storage.

## Build and test

```bash
npm install
npx hardhat compile
npx hardhat test
```

Every contract compiles against `pragma solidity 0.8.36;` exactly. The compiler is pinned in `hardhat.config.js` and enforced by solhint. The snapshot compiles and its 23 tests pass on their own, on the local Hardhat network.

## Licence

Proprietary. All rights reserved. This repository is shared for review of the hackathon submission only; no right to use, copy, modify, deploy or distribute the code is granted. See [LICENSE](./LICENSE).
