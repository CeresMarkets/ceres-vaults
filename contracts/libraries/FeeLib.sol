// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { BIPS_UNIT, SECONDS_IN_A_YEAR, PRICE_PRECISION } from "../primitives/Constants.sol";
import { FeeRates } from "../primitives/Types.sol";

/**
* @title FeeLib
* @notice Pure math primitives for management, performance, entry, exit, and protocol fees.
* @dev  Kept side-effect free so it can be unit-tested and reused across sync/async paths.
*/
library FeeLib {
    using Math for uint256;

    /**
    * @notice Accrues a time-based management fee against total assets over a given interval.
    * @dev    Uses simple (linear) accrual rather than continuous compounding — the difference
    *         is negligible at typical rates and settlement cadences. Rounds down so the vault
    *         keeps the remainder. 
    * @param totalAssetsAmount The AUM at the start of the accrual interval.
    * @param managementBps The annualized management fee, in bps.
    * @param elapsedSeconds Time elapsed since the last accrual.
    * @return feeAssets The management fee, denominated in the underlying asset.
    */
    function accrueManagementFee(
        uint256 totalAssetsAmount,
        uint16 managementBps,
        uint256 elapsedSeconds
    ) internal pure returns (uint256 feeAssets) {
        if (managementBps == 0 || elapsedSeconds == 0 || totalAssetsAmount == 0) return 0;
        // feeAssets = totalAssets * managementBps * elapsed / (BIPS_UNIT * SECONDS_IN_A_YEAR)
        feeAssets = totalAssetsAmount.mulDiv(
            uint256(managementBps) * elapsedSeconds,
            BIPS_UNIT * SECONDS_IN_A_YEAR,
            Math.Rounding.Floor
        );
    }

    /**
    * @notice Accrues a performance fee on the gain above the previous high-water mark.
    * @dev    Compares the current pricePerShare against the stored HWM. Returns zero if price has not
    *         strictly exceeded the HWM.
    * @param totalSupplyAmount The current share supply.
    * @param currentPricePerShare The pricePerShare at the accrual moment, PRICE_PRECISION units.
    * @param highWaterMark The last-recorded high pricePerShare (0 on first accrual).
    * @param performanceBps The performance fee, in bps.
    * @return feeAssets The performance fee, denominated in the underlying asset.
    * @return newHwm The updated high-water mark (equal to currentPricePerShare if it exceeded HWM,
    *                otherwise unchanged).
    */
    function accruePerformanceFee(
        uint256 totalSupplyAmount,
        uint256 currentPricePerShare,
        uint256 highWaterMark,
        uint16 performanceBps
    ) internal pure returns (uint256 feeAssets, uint256 newHwm) {
        if (performanceBps == 0 || totalSupplyAmount == 0) return (0, highWaterMark);
        if (currentPricePerShare <= highWaterMark) return (0, highWaterMark);

        uint256 delta = currentPricePerShare - highWaterMark;
        uint256 grossGain = delta.mulDiv(totalSupplyAmount, PRICE_PRECISION, Math.Rounding.Floor);
        feeAssets = grossGain.mulDiv(uint256(performanceBps), BIPS_UNIT, Math.Rounding.Floor);
        newHwm = currentPricePerShare;
    }

    /**
    * @notice Computes the entry fee applied to a deposit request at settlement time.
    * @param assetsIn The gross deposit amount.
    * @param entryBps The entry fee, in bps.
    * @return feeAssets The fee amount to deduct from the deposit.
    */
    function computeEntryFee(uint256 assetsIn, uint16 entryBps) internal pure returns (uint256 feeAssets) {
        if (entryBps == 0 || assetsIn == 0) return 0;
        feeAssets = assetsIn.mulDiv(uint256(entryBps), BIPS_UNIT, Math.Rounding.Floor);
    }

    /**
    * @notice Computes the exit fee applied to a redeem request at settlement time.
    * @param assetsOut The gross withdrawal amount.
    * @param exitBps The exit fee, in bps.
    * @return feeAssets The fee amount to deduct from the withdrawal.
    */
    function computeExitFee(uint256 assetsOut, uint16 exitBps) internal pure returns (uint256 feeAssets) {
        if (exitBps == 0 || assetsOut == 0) return 0;
        feeAssets = assetsOut.mulDiv(uint256(exitBps), BIPS_UNIT, Math.Rounding.Floor);
    }

    /**
    * @notice Splits a total fee amount into a protocol share and a manager share.
    * @dev  The protocol share is a percentage OF the fee (not of AUM). protocolBps is the fraction of
    *       the accrued fee that goes to the protocol; the rest goes to the fee recipient (the manager).
    *       This matches how most credible institutional vault protocols price protocol take.
    * @param feeAssets The total fee amount to split.
    * @param protocolBps The protocol take, in bps of the fee.
    * @return protocolShare The portion allocated to the protocol.
    * @return managerShare The portion allocated to the manager / fee recipient.
    */
    function splitProtocolShare(
        uint256 feeAssets,
        uint16 protocolBps
    ) internal pure returns (uint256 protocolShare, uint256 managerShare) {
        if (feeAssets == 0) return (0, 0);
        protocolShare = feeAssets.mulDiv(uint256(protocolBps), BIPS_UNIT, Math.Rounding.Floor);
        managerShare = feeAssets - protocolShare;
    }

    /**
    * @notice Converts an asset-denominated fee to shares at a given pricePerShare, floor-rounded.
    * @dev    Used to mint fee shares dilutively to the fee recipients at settlement.
    * @param feeAssets The fee amount in underlying asset.
    * @param pricePerShare The current pricePerShare, PRICE_PRECISION units.
    * @return feeShares The equivalent share amount.
    */
    function feeAssetsToShares(
        uint256 feeAssets,
        uint256 pricePerShare
    ) internal pure returns (uint256 feeShares) {
        if (feeAssets == 0 || pricePerShare == 0) return 0;
        feeShares = feeAssets.mulDiv(PRICE_PRECISION, pricePerShare, Math.Rounding.Floor);
    }
}
