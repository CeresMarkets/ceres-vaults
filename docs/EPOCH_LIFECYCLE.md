# Epoch Lifecycle

## Collapsed State Machine

The `PENDING` state is not an operator-visible phase — it exists only as an implicit micro-state inside `settleEpoch()`. In production, the state machine reduces to two states per epoch:

```
        ┌──────────┐
        │   OPEN   │◄─── requestDeposit / requestRedeem accepted
        └────┬─────┘
             │ settleEpoch(pricePerShare)  ← single operator call
             │   [atomically: freeze requests, price, mint shares,
             │    mark SETTLED, open next epoch]
             ▼
        ┌──────────┐         ┌──────────┐
        │ SETTLED  │  +      │   OPEN   │  (next epoch, new id)
        │ (frozen) │         │          │
        └──────────┘         └──────────┘
             ▲                    │
             │                    │ requests accumulate here now
             │                    ▼
        claimable                (repeat)
        forever
```

## Two Independent Streams

Each stream has its own monotonic epoch counter and its own OPEN epoch at any time:

```
Deposit stream:   E0(SETTLED) → E1(OPEN → SETTLED) → E2(OPEN → ...) → ...
Redeem stream:    R0(SETTLED) → R1(OPEN → SETTLED) → R2(OPEN → ...) → ...
```

Deposits can be on epoch 12 while redemptions are on epoch 5. They evolve independently.

## Genesis

At `initialize()`, epoch 1 is opened for both streams atomically:

```solidity
_openDepositEpoch(1);
_openRedeemEpoch(1);
```

After initialization, `currentDepositEpochId` and `currentRedeemEpochId` are never zero.

## Function Guards

Every state-changing entry point has a precise precondition:

| Function | Guard |
|---|---|
| `requestDeposit(...)` | `depositEpochs[currentDepositEpochId].state == Open` |
| `settleDepositEpoch(price)` | `depositEpochs[currentDepositEpochId].state == Open` and `pricePerShare == previewSettleDepositPricePerShare()` |
| `deposit/mint (claim)` | Target epoch `state == Settled`; independent of current epoch |
| Same three for redeem stream | Symmetric |

## Formal Invariants

At every function boundary, for each stream independently:

1. **Single OPEN epoch per stream**: at most one epoch has state `Open`.
2. **Monotone epoch ids**: `currentDepositEpochId` / `currentRedeemEpochId` are strictly non-decreasing.
3. **Terminal SETTLED state**: once `state == Settled`, no field ever mutates.
4. **No requests outside OPEN**: `requestDeposit` / `requestRedeem` revert unless current epoch is Open.
5. **Sum reconciliation**: `sum(depositRequestByEpoch[E][*]) == depositEpochs[E].totalAssetsDeposited` for every epoch `E`.
6. **Settled epochs have non-zero price**: `depositEpochs[E].pricePerShare > 0` for all `E < currentDepositEpochId`.
7. **totalSupply reconciliation**: `totalSupply()` is consistent with the mint-on-settle + burn-on-settle flow.

## Operator Playbook

Per stream:

1. Monitor the OPEN epoch: track pending queue, time since `openedAt`
2. When (time ≥ epochDuration) OR (queue ≥ sizeThreshold) OR (governance signal):
   a. Compute NAV off-chain (strategy.totalAssets sum, oracle cross-check)
   b. For redeem stream: ensure idle assets cover redemptions, else divest first
   c. `proposeNav(nav)` → wait `navCommitDelay` → `commitNav()`
   d. `settleDepositEpoch(previewSettleDepositPricePerShare())` or the redeem counterpart
3. Emit indexer events; users claim on their own schedule
4. Return to step 1 for the newly opened epoch

## Permissionless Fallback

If the operator stalls, anyone can call `forceSettleDepositEpoch()` / `forceSettleRedeemEpoch()` once `block.timestamp >= openedAt + maxEpochDuration`. The fallback uses the current preview price directly and does not require a fresh NAV commit.

## Serialization Guarantee

**A new epoch cannot open until the current one is Settled.** This is guaranteed because `settleX()` is the only path that increments `currentXEpochId`, and it always sets the settled epoch's `state = Settled` before opening the next.
