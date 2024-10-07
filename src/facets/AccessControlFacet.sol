// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";

/// @title Access Control Facet
/// @author Shiva Shanmuganathan
/// @notice This contract enables us to manage the app owner, app admins, and app servers by adding, removing, and viewing them.
/// @dev AccessControlFacet contract is attached to the Diamond as a Facet
contract AccessControlFacet {
    /// @notice Registers the address as app owner
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to register the app owner
    /// @param appOwner The address to be registered as app owner
    /// @custom:emits AppOwnershipChanged
    function setAppOwner(uint256 appIdentifier, address appOwner) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        LibAccessControl.setAppOwner(appIdentifier, appOwner);
    }

    /// @notice Adds the address as app admins
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to add the admins
    /// @param appAdmin The address to be added as app admins
    /// @custom:emits AddedAppAdmin
    function addAppAdmin(uint256 appIdentifier, address appAdmin) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        LibAccessControl.addAppAdmin(appIdentifier, appAdmin);
    }

    /// @notice Adds the address as app servers
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to add the app servers
    /// @param appServer The address to be added as app servers
    /// @custom:emits AddedAppServer
    function addAppServer(uint256 appIdentifier, address appServer) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        LibAccessControl.addAppServer(appIdentifier, appServer);
    }

    /// @notice Removes the address from app admins
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to remove the app admins
    /// @param adminToRemove The address to be removed from app admins
    /// @return appServers The addresses of the app servers
    /// @custom:emits RemovedAppAdmin
    function removeAppAdmin(
        uint256 appIdentifier,
        address adminToRemove
    ) external returns (bool) {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        return LibAccessControl.removeAppAdmin(appIdentifier, adminToRemove);
    }

    /// @notice Removes the address from app servers
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier The app id to remove the app servers
    /// @param appServerToRemove The address to be removed from app servers
    /// @custom:emits RemovedAppServer
    function removeAppServer(
        uint256 appIdentifier,
        address appServerToRemove
    ) external returns (bool) {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        return
            LibAccessControl.removeAppServer(appIdentifier, appServerToRemove);
    }

    /// @notice Return the owner of the app
    /// @param appIdentifier The id to get the app owner
    /// @return appOwner The address of the app owner
    function getAppOwner(
        uint256 appIdentifier
    ) external view returns (address appOwner) {
        return LibAccessControl.getAppOwner(appIdentifier);
    }

    /// @notice Return the admins of the app
    /// @param appIdentifier The id to get the app admins
    /// @return appAdmins The addresses of the app admins
    function getAppAdmins(
        uint256 appIdentifier
    ) external view returns (address[] memory appAdmins) {
        return LibAccessControl.getAppAdmins(appIdentifier);
    }

    /// @notice Return the servers of the app
    /// @param appIdentifier The id to get the app servers
    /// @return appServers The addresses of the app servers
    function getAppServers(
        uint256 appIdentifier
    ) external view returns (address[] memory appServers) {
        return LibAccessControl.getAppServers(appIdentifier);
    }
}