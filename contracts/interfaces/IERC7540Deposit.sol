// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title IERC7540Deposit
* @notice Asynchronous deposit request/claim interface per EIP-7540.
*/
interface IERC7540Deposit {
    event DepositRequest(
        address indexed controller,
        address indexed owner,
        uint256 indexed requestId,
        address sender,
        uint256 assets
    );

    event Deposit(
        address indexed caller,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    /**
    * @notice Submits a deposit request for `assets` on behalf of `owner`, controlled by `controller`.
    * @param assets The amount of underlying asset to request depositing.
    * @param controller The address that controls the resulting request (also the claim recipient).
    * @param owner The address that owns the assets and from which they are pulled.
    * @return requestId The identifier of the request (equal to the epoch id in this implementation).
    */
    function requestDeposit(uint256 assets, address controller, address owner) external returns (uint256 requestId);

    /**
    * @notice Returns the pending (not yet settled) deposit request amount for `controller` on epoch `requestId`.
    * @param requestId The epoch id to query.
    * @param controller The controller whose request is queried.
    * @return assets The pending asset amount.
    */
    function pendingDepositRequest(uint256 requestId, address controller) external view returns (uint256 assets);

    /**
    * @notice Returns the claimable (settled and unclaimed) deposit amount for `controller` on epoch `requestId`.
    * @param requestId The epoch id to query.
    * @param controller The controller whose claim is queried.
    * @return assets The claimable asset amount, denominated in the settled share price.
    */
    function claimableDepositRequest(uint256 requestId, address controller) external view returns (uint256 assets);
}
