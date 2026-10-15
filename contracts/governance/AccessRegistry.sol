// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2026 Aperta. All rights reserved. Review only, see LICENSE.
pragma solidity 0.8.36;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    AccessControlDefaultAdminRulesUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";

import { IAccessRegistry } from "../interfaces/IAccessRegistry.sol";
import { ZeroAddress } from "../primitives/Errors.sol";
import { DEFAULT_ADMIN_TRANSFER_DELAY } from "../primitives/Constants.sol";
import { requireLocalDevChain } from "../primitives/SnapshotGuard.sol";

/**
 * @title AccessRegistry
 * @notice Access-gating module supporting Allowlist / Blocklist / Open modes.
 * @dev Three modes:
 *        - Open (default) : every address allowed unless explicitly blocked
 *        - Allowlist      : only explicitly allowed addresses may interact (KYC gating)
 *        - Blocklist      : every address allowed EXCEPT explicitly blocked ones
 *
 *      Per-address explicit overrides always take precedence over the default mode.
 *      Batch operations are supported for gas-efficient onboarding / offboarding.
 *      UUPS upgradeable behind the standard `DEFAULT_ADMIN_ROLE` timelock.
 */
contract AccessRegistry is
    IAccessRegistry,
    Initializable,
    UUPSUpgradeable,
    AccessControlDefaultAdminRulesUpgradeable
{
    /**
    * @notice Access mode enum. Values match the storage byte layout.
    *         0 — permissionless with optional block overrides
    *         1 — only explicitly allowed principals may interact
    *         2 — everyone except explicitly blocked principals may interact
    */
    enum AccessMode {
        Open,
        Allowlist,
        Blocklist
    }

    /**
     * @notice Manages the allow/block lists. Kept distinct from the admin role so onboarding operators
     *         can act without upgrade authority.
     */
    bytes32 public constant LIST_MANAGER_ROLE = keccak256("LIST_MANAGER_ROLE");

    /**
     * @notice Upgrade authority. Kept distinct from the default admin to reduce upgrade trust concentration.
     */
    bytes32 public constant UPGRADE_ADMIN_ROLE = keccak256("UPGRADE_ADMIN_ROLE");

    /**
    * - allowed: explicit allow override
    * - blocked: explicit block override
    */
    /// @custom:storage-location erc7201:aperta.storage.AccessRegistry
    struct AccessRegistryStorage {
        AccessMode mode;
        mapping(address => bool) allowed;
        mapping(address => bool) blocked;
    }

    /**
    * @dev Storage slot for the Access Registry.
    * keccak256(abi.encode(uint256(keccak256("aperta.storage.AccessRegistry")) - 1)) & ~bytes32(uint256(0xff))
    * @custom:slot registry:aperta.storage.AccessRegistry
    * solhint-disable-next-line const-name-snakecase
    */
    bytes32 private constant _ACCESS_REGISTRY_STORAGE_SLOT =
        0xc518618d6f1a3d4fd69bdf496a0678bcb54d02bd9c08130df3a5bee4aa146900;

    function _getAccessRegistryStorage() internal pure returns (AccessRegistryStorage storage $) {
        bytes32 slot = _ACCESS_REGISTRY_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := slot
        }
    }

    /****************************************************************************
    *                                    EVENTS                                 *
    ****************************************************************************/

    event AccessModeChanged(AccessMode previousMode, AccessMode newMode);
    event AddressAllowed(address indexed user, bool allowed);
    event AddressBlocked(address indexed user, bool blocked);

    /****************************************************************************
    *                                    ERRORS                                 *
    ****************************************************************************/

    error EmptyBatch();
    error InvalidMode();


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        requireLocalDevChain();
        _disableInitializers();
    }

    /**
     * @notice Initializes the registry with an admin, a list manager, and a starting mode.
     * @param _admin The DEFAULT_ADMIN_ROLE holder (typically a timelock).
     * @param _listManager The LIST_MANAGER_ROLE holder (onboarding operator).
     * @param _initialMode The starting access mode (0=Open, 1=Allowlist, 2=Blocklist).
     */
    function initialize(
        address _admin,
        address _listManager,
        AccessMode _initialMode
    ) external initializer {
        requireLocalDevChain();
        if (_admin == address(0) || _listManager == address(0)) revert ZeroAddress();

        __AccessControlDefaultAdminRules_init(DEFAULT_ADMIN_TRANSFER_DELAY, _admin);
        _grantRole(LIST_MANAGER_ROLE, _listManager);
        _grantRole(UPGRADE_ADMIN_ROLE, _admin);
        _getAccessRegistryStorage().mode = _initialMode;
    }

    /****************************************************************************
    *                               WRITE FUNCTIONS                             *
    ****************************************************************************/

    /** 
    * @notice Changes the access mode. Timelocked-admin only.
    * @param _newMode The new access mode (0=Open, 1=Allowlist, 2=Blocklist).
    */
    function setMode(AccessMode _newMode) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AccessRegistryStorage storage $ = _getAccessRegistryStorage();
        AccessMode previous = $.mode;
        // Ensure the new mode is valid.
        if (_newMode != AccessMode.Open && _newMode != AccessMode.Allowlist && _newMode != AccessMode.Blocklist)
            revert InvalidMode();
        $.mode = _newMode;

        emit AccessModeChanged(previous, _newMode);
    }

    /**
    * @notice Toggles an address's explicit allow status.
    * @dev  In Allowlist mode this is the primary onboarding lever. In other modes it acts as an
    *       override — an explicitly allowed address is always permitted regardless of the default.
    * @param _user The address to allow or disallow.
    * @param _allowed Whether the address is allowed (true) or disallowed (false).
    */
    function setAllowed(address _user, bool _allowed) external onlyRole(LIST_MANAGER_ROLE) {
        if (_user == address(0)) revert ZeroAddress();
        _getAccessRegistryStorage().allowed[_user] = _allowed;

        emit AddressAllowed(_user, _allowed);
    }

    /**
    * @notice Toggles an address's explicit block status.
    * @dev  Block always beats allow — if an address is both allowed and blocked, it is treated as blocked.
    * @param _user The address to block or unblock.
    * @param _blocked Whether the address is blocked (true) or unblocked (false).
    */
    function setBlocked(address _user, bool _blocked) external onlyRole(LIST_MANAGER_ROLE) {
        if (_user == address(0)) revert ZeroAddress();
        _getAccessRegistryStorage().blocked[_user] = _blocked;

        emit AddressBlocked(_user, _blocked);
    }

    /**
    * @notice Batch-sets the allowed flag for multiple addresses.
    * @param _users The addresses to allow or disallow.
    * @param _allowed Whether the addresses are allowed (true) or disallowed (false).
    */
    function setAllowedBatch(address[] calldata _users, bool _allowed) external onlyRole(LIST_MANAGER_ROLE) {
        uint256 n = _users.length;
        if (n == 0) revert EmptyBatch();

        AccessRegistryStorage storage $ = _getAccessRegistryStorage();
        for (uint256 i; i < n; ) {
            address user = _users[i];
            if (user == address(0)) revert ZeroAddress();
            $.allowed[user] = _allowed;

            emit AddressAllowed(user, _allowed);
            unchecked { ++i; }
        }
    }

    /**
    * @notice Batch-sets the blocked flag for multiple addresses.
    * @param _users The addresses to block or unblock.
    * @param _blocked Whether the addresses are blocked (true) or unblocked (false).
    */
    function setBlockedBatch(address[] calldata _users, bool _blocked) external onlyRole(LIST_MANAGER_ROLE) {
        uint256 n = _users.length;
        if (n == 0) revert EmptyBatch();

        AccessRegistryStorage storage $ = _getAccessRegistryStorage();
        for (uint256 i; i < n; ) {
            address user = _users[i];
            if (user == address(0)) revert ZeroAddress();
            $.blocked[user] = _blocked;

            emit AddressBlocked(user, _blocked);
            unchecked { ++i; }
        }
    }

    /****************************************************************************
    *                               VIEW FUNCTIONS                              *
    ****************************************************************************/
    /**
    * @inheritdoc IAccessRegistry
    * @dev  Precedence: block override > allow override > mode default.
    *        - Any explicitly blocked address is always denied.
    *        - Any explicitly allowed address is always permitted (in Open and Blocklist modes it is
    *          effectively a no-op; in Allowlist mode it is the primary onboarding path).
    *        - Otherwise, the default depends on the mode: Open/Blocklist allow, Allowlist denies.
    */
    function isAllowed(address _user) external view override returns (bool) {
        AccessRegistryStorage storage $ = _getAccessRegistryStorage();

        if ($.blocked[_user]) return false;
        if ($.allowed[_user]) return true;
        if ($.mode == AccessMode.Allowlist) return false;
        // Open or Blocklist: default allow.
        return true;
    }

    /// @notice Returns the current mode.
    function getMode() external view returns (AccessMode) {
        return _getAccessRegistryStorage().mode;
    }

    /**
    * @notice Returns whether a user has an explicit allow flag.
    * @param _user The address to check.
    * @return True if the user is explicitly allowed, false otherwise.
    */ 
    function isExplicitlyAllowed(address _user) external view returns (bool) {
        return _getAccessRegistryStorage().allowed[_user];
    }

    /**
    * @notice Returns whether a user has an explicit block flag.
    * @param _user The address to check.
    * @return True if the user is explicitly blocked, false otherwise.
    */
    function isExplicitlyBlocked(address _user) external view returns (bool) {
        return _getAccessRegistryStorage().blocked[_user];
    }

    /****************************************************************************
    *                                   UUPS                                    *
    ****************************************************************************/

    function _authorizeUpgrade(address _newImplementation) internal view override onlyRole(UPGRADE_ADMIN_ROLE) {
        _newImplementation;
    }
}
