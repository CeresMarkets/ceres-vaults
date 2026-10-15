// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title IPausable
* @notice Minimal surface for a contract that exposes `pause` and `unpause`.
*/
interface IPausable {
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}
