// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibStructs} from "./LibStructs.sol";
import {LibEvents} from "./LibEvents.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {LibSatBank} from "./LibSatBank.sol";
import {LibCheck} from "./LibCheck.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

library LibApp {
    bytes32 private constant APP_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.LibApp.Storage");

    struct AppData {
        string name;
        bool depositsAllowed;
        bool withdrawsAllowed;
    }

    struct ExternalAppStorage {
        uint256 appCount;
        // appID to appData
        mapping(uint256 => AppData) appRegistry;
        // appID to publisherFee array
        mapping(uint256 => LibStructs.Fee[]) appPublisherFeesList;
        // appID to publisherFee map
        mapping(uint256 => mapping(address => uint256)) appPublisherFeesMap;
    }

    /// @notice Register a new app project
    /// @dev The internal function validates app name and creates a new app with unique id
    /// @param appName - Name for the app
    /// @return appIdentifier - Unique identifier for the app
    /// @custom:emits NewAppCreated
    function createNewApp(string memory appName) internal returns (uint256) {
        LibCheck.enforceValidString(appName);
        ExternalAppStorage storage sbes = externalAppStorage();
        sbes.appCount++;
        uint256 appCount = sbes.appCount;
        AppData storage app = sbes.appRegistry[appCount];

        app.name = appName;
        app.depositsAllowed = false;
        app.withdrawsAllowed = false;
        LibAccessControl.accessCtrlStorage().appOwner[appCount] = msg.sender;

        emit LibEvents.NewAppCreated(appCount, appName);
        return appCount;
    }

    /// @notice Set the LG Publisher Fee for revenue on a specific token, for a given app
    /// @dev The internal function validates app id, token address, and percentage
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param percent - The percent [0-100] fee collected by the LG Treasury
    /// @custom:emits AppFeesChanged
    function setPublisherFee(
        uint256 appIdentifier,
        address token,
        uint8 percent
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        LibCheck.enforceValidPercent(percent);

        ExternalAppStorage storage sbes = externalAppStorage();
        LibStructs.Fee[] storage publisherFees = sbes.appPublisherFeesList[
            appIdentifier
        ];
        LibStructs.Fee[] memory oldFees = publisherFees;
        LibStructs.Fee memory fee = LibStructs.Fee(token, percent);
        publisherFees.push(fee);
        sbes.appPublisherFeesMap[appIdentifier][token] = percent;
        emit LibEvents.AppFeesChanged(appIdentifier, oldFees, publisherFees);
    }

    /// @notice Erase any publisher fees for an app.
    /// @dev The internal function validates app id and deposits paused
    /// @param appIdentifier - Unique id of an app
    /// @custom:emits AppFeesChanged
    function resetPublisherFees(uint256 appIdentifier) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        enforceAppDepositsDisabled(appIdentifier);
        ExternalAppStorage storage sbes = externalAppStorage();
        LibStructs.Fee[] memory oldFees = sbes.appPublisherFeesList[
            appIdentifier
        ];
        delete sbes.appPublisherFeesList[appIdentifier];
        for (uint256 i = 0; i < oldFees.length; i++) {
            address tokenToDelete = oldFees[i].token;
            delete sbes.appPublisherFeesMap[appIdentifier][tokenToDelete];
        }
        emit LibEvents.AppFeesChanged(
            appIdentifier,
            oldFees,
            sbes.appPublisherFeesList[appIdentifier]
        );
    }

    /// @notice Set the app name
    /// @dev The internal function validates app id and app name
    /// @param appIdentifier - Unique id of an app
    /// @param appName - New name for the app
    /// @custom:emits AppNameChanged
    function setAppName(uint256 appIdentifier, string memory appName) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidString(appName);
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        app.name = appName;
        emit LibEvents.AppNameChanged(appIdentifier, appName);
    }

    /// @notice Pause or resume the deposits for an app.
    /// @dev The internal function validates app id
    /// @param appIdentifier - Unique id of an app
    /// @param depositsAllowed - deposit status of an app
    /// @custom:emits AppDepositActiveChanged
    function setAppDepositActive(
        uint256 appIdentifier,
        bool depositsAllowed
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        app.depositsAllowed = depositsAllowed;
        emit LibEvents.AppDepositActiveChanged(appIdentifier, depositsAllowed);
    }

    /// @notice Pause or resume the withdraws for an app.
    /// @dev The internal function validates app id
    /// @param appIdentifier - Unique id of an app
    /// @param withdrawsAllowed - withdraw status of an app
    /// @custom:emits AppWithdrawActiveChanged
    function setAppWithdrawActive(
        uint256 appIdentifier,
        bool withdrawsAllowed
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        enforceAppIsInitialized(appIdentifier);
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        app.withdrawsAllowed = withdrawsAllowed;
        emit LibEvents.AppWithdrawActiveChanged(
            appIdentifier,
            withdrawsAllowed
        );
    }

    /// @notice Return the name of an app
    /// @param appIdentifier - Unique id of an app
    /// @return appName - Name of the app
    function getAppName(
        uint256 appIdentifier
    ) internal view returns (string memory) {
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        return app.name;
    }

    /// @notice Return the current state of an app
    /// @param appIdentifier - Unique id of an app
    /// @return appName The name of the app queried
    /// @return appBalance - The number of RBW in this app's account
    /// @return depositsAllowed - If true, users may stash in to this app
    /// @return withdrawsAllowed - If true, users may stash out of this app
    /// @return publisherFees - List of fees taken by the LG Treasury
    function getAppStatus(
        uint256 appIdentifier
    )
        internal
        view
        returns (
            string memory appName,
            uint256 appBalance,
            bool depositsAllowed,
            bool withdrawsAllowed,
            LibStructs.Fee[] memory publisherFees
        )
    {
        ExternalAppStorage storage sbes = externalAppStorage();
        AppData storage app = sbes.appRegistry[appIdentifier];
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        address token = LibResourceLocator.rbwToken();
        appBalance = sbs.appBalance[appIdentifier][token];
        return (
            app.name,
            appBalance,
            app.depositsAllowed,
            app.withdrawsAllowed,
            sbes.appPublisherFeesList[appIdentifier]
        );
    }

    /// @notice Return the current app ID in diamond
    /// @return appCount - The latest app ID of the diamond
    function getAppCount() internal view returns (uint256) {
        return externalAppStorage().appCount;
    }

    function enforceAppWithdrawsAllowed(uint256 appIdentifier) internal view {
        require(
            externalAppStorage().appRegistry[appIdentifier].withdrawsAllowed ==
                true,
            "Withdraws are paused for this app"
        );
    }

    function enforceAppDepositsDisabled(uint256 appIdentifier) private view {
        require(
            externalAppStorage().appRegistry[appIdentifier].depositsAllowed ==
                false,
            "Deposits are active for this app"
        );
    }

    function enforceAppDepositsEnabled(uint256 appIdentifier) internal view {
        require(
            externalAppStorage().appRegistry[appIdentifier].depositsAllowed ==
                true,
            "Deposits are paused for this app"
        );
    }

    function enforceAppIsInitialized(uint256 appIdentifier) internal view {
        require(
            bytes(externalAppStorage().appRegistry[appIdentifier].name).length >
                0,
            "App name cannot be empty"
        );
    }

    function externalAppStorage()
        internal
        pure
        returns (ExternalAppStorage storage sbes)
    {
        bytes32 position = APP_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbes.slot := position
        }
    }
}
