// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title IERC7540Redeem
* @notice Asynchronous redemption request/claim interface per EIP-7540.
*/
interface IERC7540Redeem {
    event RedeemRequest(
        address indexed controller,
        address indexed owner,
        uint256 indexed requestId,
        address sender,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
    * @notice Submits a redemption request for `shares` on behalf of `owner`, controlled by `controller`.
    * @param shares The amount of vault shares to request redeeming.
    * @param controller The address that controls the resulting request (also the claim recipient).
    * @param owner The address that owns the shares and from which they are pulled.
    * @return requestId The identifier of the request (equal to the epoch id in this implementation).
    */
    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256 requestId);

    /**
    * @notice Returns the pending (not yet settled) redemption request amount for `controller` on epoch `requestId`.
    * @param requestId The epoch id to query.
    * @param controller The controller whose request is queried.
    * @return shares The pending share amount.
    */
    function pendingRedeemRequest(uint256 requestId, address controller) external view returns (uint256 shares);

    /**
    * @notice Returns the claimable (settled and unclaimed) redemption amount for `controller` on epoch `requestId`.
    * @param requestId The epoch id to query.
    * @param controller The controller whose claim is queried.
    * @return shares The claimable share amount, denominated at the settled share price.
    */
    function claimableRedeemRequest(uint256 requestId, address controller) external view returns (uint256 shares);
}
