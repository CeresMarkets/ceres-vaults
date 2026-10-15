// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { PRICE_PRECISION } from "../primitives/Constants.sol";

/**
* @title EpochLib
* @notice Pure math primitives for epoch settlement pricing and share/asset conversion at a fixed epoch price.
* @dev  Kept side-effect free so it can be unit-tested in isolation and reused across sync/async paths.
*/
library EpochLib {
    using Math for uint256;

    /**
    * @notice Computes the number of shares a given asset amount converts to at a fixed epoch price.
    * @param assets The asset amount.
    * @param pricePerShare The frozen epoch price, in PRICE_PRECISION units (assets per share).
    * @param rounding The rounding direction.
    * @return shares The share amount.
    */
    function assetsToShares(
        uint256 assets,
        uint256 pricePerShare,
        Math.Rounding rounding
    ) internal pure returns (uint256 shares) {
        if (pricePerShare == 0) return 0;
        shares = assets.mulDiv(PRICE_PRECISION, pricePerShare, rounding);
    }

    /**
    * @notice Computes the number of assets a given share amount converts to at a fixed epoch price.
    * @param shares The share amount.
    * @param pricePerShare The frozen epoch price, in PRICE_PRECISION units (assets per share).
    * @param rounding The rounding direction.
    * @return assets The asset amount.
    */
    function sharesToAssets(
        uint256 shares,
        uint256 pricePerShare,
        Math.Rounding rounding
    ) internal pure returns (uint256 assets) {
        assets = shares.mulDiv(pricePerShare, PRICE_PRECISION, rounding);
    }

    /**
    * @notice Computes the settlement pricePerShare given the current NAV and outstanding share supply.
    * @dev  Uses the virtual-shares inflation defense: adds 10**decimalsOffset to the supply and 1 to the assets.
    * @param totalAssetsAtSettlement The vault's total assets at the moment of settlement.
    * @param totalSupplyAtSettlement The vault's total share supply at the moment of settlement.
    * @param decimalsOffset The virtual-shares offset used by the vault.
    * @return pricePerShare The computed price in PRICE_PRECISION units.
    */
    function computeSettlementPrice(
        uint256 totalAssetsAtSettlement,
        uint256 totalSupplyAtSettlement,
        uint8 decimalsOffset
    ) internal pure returns (uint256 pricePerShare) {
        uint256 supplyWithVirtual = totalSupplyAtSettlement + 10 ** decimalsOffset;
        uint256 assetsWithVirtual = totalAssetsAtSettlement + 1;
        pricePerShare = assetsWithVirtual.mulDiv(PRICE_PRECISION, supplyWithVirtual, Math.Rounding.Floor);
    }
}
