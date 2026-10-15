// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { IFeeLedger } from "../interfaces/IFeeLedger.sol";
import { FeeType } from "../primitives/Enums.sol";
import { ZeroAddress, Unauthorized } from "../primitives/Errors.sol";
import { requireLocalDevChain } from "../primitives/SnapshotGuard.sol";

/**
* @title FeeLedger
* @notice Append-only ledger recording every fee accrual for off-chain audit.
* @dev  Only explicitly authorized vaults may write to the ledger. The ledger stores an ordered log
*       of entries keyed by monotonic index, and emits a `FeeAccrued` event so indexers can reconstruct
*       the full accrual history without scanning storage.
*/
contract FeeLedger is IFeeLedger {
    struct FeeEntry {
        address vault;
        FeeType feeType;
        uint256 epochId;
        uint256 amount;
        address recipient;
        uint64 timestamp;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUTHORIZER_ROLE = keccak256("AUTHORIZER_ROLE");

    event VaultAuthorized(address indexed vault);
    event VaultRevoked(address indexed vault);

    event FeeAccrued(
        uint256 indexed index,
        address indexed vault,
        FeeType indexed feeType,
        uint256 epochId,
        uint256 amount,
        address recipient
    );

    uint256 public totalEntries;
    mapping(uint256 => FeeEntry) private _entries;
    mapping(address => bool) public authorizedVaults;
    address public admin;
    address public authorizer;

    constructor(address _admin, address _authorizer) {
        requireLocalDevChain();
        if (_admin == address(0) || _authorizer == address(0)) revert ZeroAddress();
        admin = _admin;
        authorizer = _authorizer;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized(msg.sender);
        _;
    }

    modifier onlyAuthorizer() {
        if (msg.sender != authorizer && msg.sender != admin) revert Unauthorized(msg.sender);
        _;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        admin = newAdmin;
    }

    function setAuthorizer(address newAuthorizer) external onlyAdmin {
        if (newAuthorizer == address(0)) revert ZeroAddress();
        authorizer = newAuthorizer;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        if (role == ADMIN_ROLE) return account == admin;
        if (role == AUTHORIZER_ROLE) return account == authorizer;
        return false;
    }

    function authorizeVault(address vault) external override onlyAuthorizer {
        if (vault == address(0)) revert ZeroAddress();
        if (!authorizedVaults[vault]) {
            authorizedVaults[vault] = true;
            emit VaultAuthorized(vault);
        }
    }

    function revokeVault(address vault) external override onlyAdmin {
        if (authorizedVaults[vault]) {
            delete authorizedVaults[vault];
            emit VaultRevoked(vault);
        }
    }

    /// @inheritdoc IFeeLedger
    function recordFee(
        address vault,
        FeeType feeType,
        uint256 epochId,
        uint256 amount,
        address recipient
    ) external override {
        if (vault == address(0)) revert ZeroAddress();
        if (recipient == address(0)) revert ZeroAddress();
        if (!authorizedVaults[vault]) revert Unauthorized(vault);
        if (msg.sender != vault) revert Unauthorized(msg.sender);
        // Amount == 0 is permitted (indexers may skip these but we still record for continuity).

        uint256 idx = totalEntries;
        _entries[idx] = FeeEntry({
            vault: vault,
            feeType: feeType,
            epochId: epochId,
            amount: amount,
            recipient: recipient,
            timestamp: uint64(block.timestamp)
        });
        unchecked {
            totalEntries = idx + 1;
        }

        emit FeeAccrued(idx, vault, feeType, epochId, amount, recipient);
    }

    /// @notice Returns a single ledger entry by index.
    function getEntry(uint256 index) external view returns (FeeEntry memory) {
        return _entries[index];
    }

    /// @notice Returns a page of entries [start, start+count).
    function getEntries(uint256 start, uint256 count) external view returns (FeeEntry[] memory page) {
        uint256 available = start >= totalEntries ? 0 : totalEntries - start;
        uint256 n = count < available ? count : available;
        page = new FeeEntry[](n);
        for (uint256 i; i < n; ) {
            page[i] = _entries[start + i];
            unchecked { ++i; }
        }
    }
}
