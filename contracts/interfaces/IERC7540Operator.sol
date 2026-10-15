// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

/**
* @title IERC7540Operator
* @notice Operator delegation interface per EIP-7540.
* @dev A controller may authorize an operator to submit and claim requests on their behalf.
*/
interface IERC7540Operator {
    event OperatorSet(
        address indexed controller,
        address indexed operator,
        bool approved
    );

    /**
    * @notice Sets or revokes operator status for `operator` on behalf of `msg.sender`.
    * @param operator The address to grant or revoke operator status for.
    * @param approved True to grant, false to revoke.
    * @return success True on success.
    */
    function setOperator(address operator, bool approved) external returns (bool success);

    /**
    * @notice Returns whether `operator` is an approved operator for `controller`.
    * @param controller The controller whose delegation state is queried.
    * @param operator The candidate operator address.
    * @return status True if `operator` is authorized for `controller`.
    */
    function isOperator(address controller, address operator) external view returns (bool status);
}
