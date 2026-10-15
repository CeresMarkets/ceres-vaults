# Fee Model

## Overview

Five fee types accrue on-chain, each with a bounded maximum:

| Fee | Basis | Trigger | Max BPS |
|---|---|---|---|
| Management | Time × AUM | On every settlement / sync op | 1_500 (15%) |
| Performance | Gain above HWM | On every settlement / sync op | 4_500 (45%) |
| Entry | Deposit amount | At deposit settlement / `deposit`/`mint` | 100 (1%) |
| Exit | Redeem amount | At redeem settlement / `withdraw`/`redeem` | 100 (1%) |
| Protocol | % OF the fee (not AUM) | Split from each fee above | 3_500 (35%) |
| Haircut | Reserved for loss socialization | — | 1_500 (15%) |

Every accrual mints dilutive shares to the recipients rather than transferring underlying out — this captures value at the current NAV without draining vault liquidity.

## Accrual Flow

```
                         SETTLEMENT
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │  1. Accrue management fee (time-based)  │
        │  2. Accrue performance fee (HWM-based)  │
        └────────────────┬────────────────────────┘
                         │
                         ▼
        ┌─────────────────────────────────────────┐
        │  3. Compute entry fee (deposit stream)  │
        │     or exit fee (redeem stream)         │
        └────────────────┬────────────────────────┘
                         │
                         ▼
        ┌─────────────────────────────────────────┐
        │  4. Split each fee: manager / protocol  │
        │     protocolShare = fee × protocolBps   │
        │     managerShare  = fee − protocolShare │
        └────────────────┬────────────────────────┘
                         │
                         ▼
        ┌─────────────────────────────────────────┐
        │  5. Mint fee shares to both recipients  │
        │     (dilutes existing shareholders)     │
        └────────────────┬────────────────────────┘
                         │
                         ▼
        ┌─────────────────────────────────────────┐
        │  6. Record every accrual in fee ledger  │
        │     (best-effort, non-blocking)         │
        └─────────────────────────────────────────┘
```

## Formulas

### Management Fee (linear time accrual)

```
feeAssets = totalAssets × managementBps × elapsedSeconds
            ─────────────────────────────────────────────
            BIPS_UNIT × SECONDS_IN_A_YEAR
```

Rounded down. Simple linear rather than continuous compounding — negligible difference at typical rates and settlement cadences.

### Performance Fee (HWM gain)

```
delta      = max(0, currentPricePerShare − highWaterMark)
grossGain  = delta × totalSupply / PRICE_PRECISION
feeAssets  = grossGain × performanceBps / BIPS_UNIT
newHwm     = currentPricePerShare        (if strictly greater than HWM)
             highWaterMark               (otherwise, HWM latches)
```

HWM is seeded to `PRICE_PRECISION` (1.0) at initialization so early gains are measured from parity. HWM never decreases — flat or losing periods do not accrue and do not reset the mark.

### Entry / Exit Fee

```
entryFee = assetsIn × entryBps / BIPS_UNIT
exitFee  = assetsOut × exitBps / BIPS_UNIT
```

### Protocol Split

```
protocolShare = feeAssets × protocolBps / BIPS_UNIT
managerShare  = feeAssets − protocolShare
```

Note: `protocolBps` is a percentage OF the fee, not of AUM.

### Asset-to-Share Conversion for Fee Minting

```
feeShares = feeAssets × PRICE_PRECISION / pricePerShare
```

Floor-rounded.

## Sync Vault Entry/Exit Fee Grossing

For `mint(shares, receiver)` and `withdraw(assets, receiver, owner)` — the "specify exact output" variants — the entry/exit fee is grossed up so the user actually receives the specified amount after the fee:

```
grossAssets = netAssets × BIPS_UNIT / (BIPS_UNIT − feeBps)   [ceil]
fee         = grossAssets − netAssets
```

## Fee Ledger

Every accrual is recorded in the `FeeLedger` contract via best-effort low-level call:

```solidity
event FeeAccrued(
    uint256 indexed index,
    address indexed vault,
    FeeType indexed feeType,
    uint256 epochId,
    uint256 amount,
    address recipient
);
```

The ledger is append-only, keyed by monotonic index, and paginated via `getEntries(start, count)`. A missing or broken ledger never blocks settlement — the call is wrapped in a low-level `call` whose failure is silently ignored.

## Invariants

- **HWM monotonicity**: `highWaterMark` is strictly non-decreasing across settlements
- **Fee rate bounds**: every rate ≤ its `MAX_*_BPS` cap after any setter
- **No fee on flat or losing periods**: performance fee is zero when `currentPricePerShare <= highWaterMark`
- **Split correctness**: `protocolShare + managerShare == feeAssets` for every accrual
- **Ledger consistency**: for every fee-shares mint, a `FeeAccrued` event is emitted with matching amount and recipient (when a ledger is bound)
