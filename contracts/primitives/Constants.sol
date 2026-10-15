// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

uint256 constant MAX_UINT256 = type(uint256).max;

uint256 constant BIPS_UNIT = 10_000;
uint256 constant SECONDS_IN_A_YEAR = 365 days;

uint48 constant DEFAULT_ADMIN_TRANSFER_DELAY = 1 days;

uint16 constant MAX_MANAGEMENT_FEE_BPS = 1_500; // 15%
uint16 constant MAX_PERFORMANCE_FEE_BPS = 4_500; // 45%
uint16 constant MAX_ENTRY_FEE_BPS = 100; // 1%
uint16 constant MAX_EXIT_FEE_BPS = 100; // 1%
uint16 constant MAX_HAIRCUT_BPS = 1_500; // 15%
uint16 constant MAX_PROTOCOL_FEE_BPS = 3_500; // 35%

uint256 constant MIN_DEPOSIT_REQUEST = 1;
uint256 constant MIN_REDEEM_REQUEST = 1;

uint256 constant DEFAULT_MAX_EPOCH_DURATION = 7 days;
uint256 constant DEFAULT_MAX_NAV_STALENESS = 1 days;
uint256 constant DEFAULT_NAV_COMMIT_DELAY = 5 minutes;

uint256 constant PRICE_PRECISION = 1e18;