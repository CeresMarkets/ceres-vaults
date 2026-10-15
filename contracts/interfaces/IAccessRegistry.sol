// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title IAccessRegistry
* @notice Pluggable access-gating module. A vault delegates whitelist / blacklist / KYC checks here.
*/
interface IAccessRegistry {
    /**
    * @notice Returns whether `user` is allowed to interact with the vault.
    * @param user The address to check.
    * @return allowed True if the address is permitted.
    */
    function isAllowed(address user) external view returns (bool allowed);
}
