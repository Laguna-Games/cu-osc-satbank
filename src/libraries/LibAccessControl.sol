// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibEvents} from "./LibEvents.sol";
import {LibApp} from "./LibApp.sol";
import {LibCheck} from "./LibCheck.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";

library LibAccessControl {
    bytes32 private constant ACCESS_CONTROL_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.LibAccessControl.Storage");

    struct AccessCtrlStorage {
        mapping(uint256 => address) appOwner;
        mapping(uint256 => address[]) admins;
        mapping(uint256 => address[]) servers;
    }

    /// @notice Registers the address as app owner
    /// @dev The internal function validates app id and app owner address
    /// @param appIdentifier The app id to register the app owner
    /// @param appOwner The address to be registered as app owner
    /// @custom:emits AppOwnershipChanged
    function setAppOwner(uint256 appIdentifier, address appOwner) internal {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(appOwner);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        address oldOwner = sbac.appOwner[appIdentifier];
        sbac.appOwner[appIdentifier] = appOwner;
        emit LibEvents.AppOwnershipChanged(appIdentifier, oldOwner, appOwner);
    }

    /// @notice Adds the address as app admins
    /// @dev The internal function validates app id, address array and app admin address
    /// @param appIdentifier The app id to add the admins
    /// @param appAdmin The address to be added as app admins
    /// @custom:emits AddedAppAdmin
    function addAppAdmin(uint256 appIdentifier, address appAdmin) internal {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(appAdmin);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.admins[appIdentifier].length; i++) {
            require(
                sbac.admins[appIdentifier][i] != appAdmin,
                "Admin already exists in satbank"
            );
        }
        sbac.admins[appIdentifier].push(appAdmin);
        emit LibEvents.AddedAppAdmin(appIdentifier, appAdmin);
    }

    /// @notice Removes the address from app admins
    /// @dev The internal function validates app id, address array and app admin address
    /// @param appIdentifier The app id to remove the app admins
    /// @param adminToRemove The address to be removed from app admins
    /// @custom:emits RemovedAppAdmin
    function removeAppAdmin(
        uint256 appIdentifier,
        address adminToRemove
    ) internal returns (bool) {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(adminToRemove);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.admins[appIdentifier].length; i++) {
            if (sbac.admins[appIdentifier][i] == adminToRemove) {
                sbac.admins[appIdentifier][i] = sbac.admins[appIdentifier][
                    sbac.admins[appIdentifier].length - 1
                ];
                sbac.admins[appIdentifier].pop();
                emit LibEvents.RemovedAppAdmin(appIdentifier, adminToRemove);
                return true;
            }
        }
        return false;
    }

    /// @notice Adds the address as app servers
    /// @dev The internal function validates app id, address array and app server address
    /// @param appIdentifier The app id to add the app servers
    /// @param appServer The address to be added as app servers
    /// @custom:emits AddedAppServer
    function addAppServer(uint256 appIdentifier, address appServer) internal {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(appServer);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.servers[appIdentifier].length; i++) {
            require(
                sbac.servers[appIdentifier][i] != appServer,
                "Server already exists in satbank"
            );
        }
        sbac.servers[appIdentifier].push(appServer);
        emit LibEvents.AddedAppServer(appIdentifier, appServer);
    }

    /// @notice Removes the address from app servers
    /// @dev The internal function validates app id, address array and app server address
    /// @param appIdentifier The app id to remove the app servers
    /// @param serverToRemove The address to be removed from app servers
    /// @custom:emits RemovedAppServer
    function removeAppServer(
        uint256 appIdentifier,
        address serverToRemove
    ) internal returns (bool) {
        enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(serverToRemove);
        AccessCtrlStorage storage sbac = accessCtrlStorage();
        for (uint256 i = 0; i < sbac.servers[appIdentifier].length; i++) {
            if (sbac.servers[appIdentifier][i] == serverToRemove) {
                sbac.servers[appIdentifier][i] = sbac.servers[appIdentifier][
                    sbac.servers[appIdentifier].length - 1
                ];
                sbac.servers[appIdentifier].pop();
                emit LibEvents.RemovedAppServer(appIdentifier, serverToRemove);
                return true;
            }
        }
        return false;
    }

    /// @notice Return the admins of the app
    /// @param appIdentifier The id to get the app admins
    /// @return appAdmins The addresses of the app admins
    function getAppAdmins(
        uint256 appIdentifier
    ) internal view returns (address[] memory appAdmins) {
        return accessCtrlStorage().admins[appIdentifier];
    }

    /// @notice Return the servers of the app
    /// @param appIdentifier The id to get the app servers
    /// @return appServers The addresses of the app servers
    function getAppServers(
        uint256 appIdentifier
    ) internal view returns (address[] memory) {
        return accessCtrlStorage().servers[appIdentifier];
    }

    /// @notice Return the owner of the app
    /// @param appIdentifier The id to get the app owner
    /// @return appOwner The address of the app owner
    function getAppOwner(
        uint256 appIdentifier
    ) internal view returns (address appOwner) {
        return accessCtrlStorage().appOwner[appIdentifier];
    }

    function checkAppAdmin(
        uint256 appIdentifier,
        address admin
    ) internal view returns (bool isAppAdmin) {
        address[] memory adminArray = accessCtrlStorage().admins[appIdentifier];
        for (uint256 i = 0; i < adminArray.length; i++) {
            if (adminArray[i] == admin) {
                return true;
            }
        }
        return false;
    }

    function checkAppServer(
        uint256 appIdentifier,
        address server
    ) internal view returns (bool isAppServer) {
        address[] memory serverArray = accessCtrlStorage().servers[
            appIdentifier
        ];
        for (uint256 i = 0; i < serverArray.length; i++) {
            if (serverArray[i] == server) {
                return true;
            }
        }
        return false;
    }

    function enforceValidAppServer(uint256 appIdentifier) internal view {
        require(
            checkAppServer(appIdentifier, msg.sender),
            "Invalid app server"
        );
    }

    function enforceAppServerOrAppOwner(uint256 appIdentifier) internal view {
        require(
            msg.sender == accessCtrlStorage().appOwner[appIdentifier] ||
                checkAppServer(appIdentifier, msg.sender),
            "Invalid app server*"
        );
    }

    function enforceAddressIsAppServerOrAppOwner(
        uint256 appIdentifier,
        address a
    ) internal view {
        require(
            a == accessCtrlStorage().appOwner[appIdentifier] ||
                checkAppServer(appIdentifier, a),
            "Invalid app server**"
        );
    }

    function enforceValidAppOwner(uint256 appIdentifier) internal view {
        require(
            accessCtrlStorage().appOwner[appIdentifier] != address(0),
            "Invalid app identifier"
        );
    }

    function enforceAppOwner(uint256 appIdentifier) internal view {
        require(
            msg.sender == accessCtrlStorage().appOwner[appIdentifier],
            "Must be app owner"
        );
    }

    function enforceAppOwnerOrAdmin(uint256 appIdentifier) internal view {
        require(
            (msg.sender == accessCtrlStorage().appOwner[appIdentifier]) ||
                (checkAppAdmin(appIdentifier, msg.sender)),
            "Must be app owner or admin"
        );
    }

    function enforceContractOwnerOrAppOwner(
        uint256 appIdentifier
    ) internal view {
        require(
            msg.sender == LibContractOwner.ownerStorage().contractOwner ||
                msg.sender == accessCtrlStorage().appOwner[appIdentifier],
            "Must be contract owner or app owner"
        );
    }

    function accessCtrlStorage()
        internal
        pure
        returns (AccessCtrlStorage storage sbac)
    {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbac.slot := position
        }
    }
}
