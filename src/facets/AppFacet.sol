// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibApp} from "../libraries/LibApp.sol";
import {LibStructs} from "../libraries/LibStructs.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {DiamondReentrancyGuard} from "../../lib/web3/contracts/diamond/security/DiamondReentrancyGuard.sol";
import {LibSatBank} from "../libraries/LibSatBank.sol";

/// @title App Facet
/// @author Shiva Shanmuganathan
/// @notice This contract enables us to create the app and configure its properties.
/// @dev AppFacet contract is attached to the Diamond as a Facet
contract AppFacet is DiamondReentrancyGuard {
    /// @notice Register a new app project
    /// @dev The external function can be accessed by diamond owner
    /// @param appName - Name for the app
    /// @return appIdentifier - Unique identifier for the app
    /// @custom:emits NewAppCreated
    function createNewApp(
        string memory appName
    ) external returns (uint256 appIdentifier) {
        LibContractOwner.enforceIsContractOwner();
        appIdentifier = LibApp.createNewApp(appName);
        return appIdentifier;
    }

    /// @notice Set the app name
    /// @dev The external function can be accessed by app owner
    /// @param appIdentifier - Unique id of an app
    /// @param appName - New name for the app
    /// @custom:emits AppNameChanged
    function setAppName(uint256 appIdentifier, string memory appName) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        return LibApp.setAppName(appIdentifier, appName);
    }

    /// @notice Pause or resume the deposits for an app.
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier - Unique id of an app
    /// @param depositsAllowed - deposit status of an app
    /// @custom:emits AppDepositActiveChanged
    function setAppDepositActive(
        uint256 appIdentifier,
        bool depositsAllowed
    ) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        return LibApp.setAppDepositActive(appIdentifier, depositsAllowed);
    }

    /// @notice Pause or resume the withdraws for an app.
    /// @dev The external function can be accessed by diamond owner or app owner
    /// @param appIdentifier - Unique id of an app
    /// @param withdrawsAllowed - withdraw status of an app
    /// @custom:emits AppWithdrawActiveChanged
    function setAppWithdrawActive(
        uint256 appIdentifier,
        bool withdrawsAllowed
    ) external {
        LibAccessControl.enforceContractOwnerOrAppOwner(appIdentifier);
        return LibApp.setAppWithdrawActive(appIdentifier, withdrawsAllowed);
    }

    /// @notice Set the LG Publisher Fee for revenue on a specific token, for a given app
    /// @dev The external function can be accessed by diamond owner
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param percent - The percent [0-100] fee collected by the LG Treasury
    /// @custom:emits AppFeesChanged
    function setPublisherFee(
        uint256 appIdentifier,
        address token,
        uint8 percent
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibApp.setPublisherFee(appIdentifier, token, percent);
    }

    /// @notice Erase any publisher fees for an app.
    /// @dev The external function can be accessed by diamond owner
    /// @dev App must have deposits paused.
    /// @param appIdentifier - Unique id of an app
    /// @custom:emits AppFeesChanged
    function resetPublisherFees(uint256 appIdentifier) external {
        LibContractOwner.enforceIsContractOwner();
        LibApp.resetPublisherFees(appIdentifier);
    }

    /// @notice Return the name of an app
    /// @param appIdentifier - Unique id of an app
    /// @return appName - Name of the app
    function getAppName(
        uint256 appIdentifier
    ) external view returns (string memory appName) {
        return LibApp.getAppName(appIdentifier);
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
        external
        view
        returns (
            string memory appName,
            uint256 appBalance,
            bool depositsAllowed,
            bool withdrawsAllowed,
            LibStructs.Fee[] memory publisherFees
        )
    {
        return LibApp.getAppStatus(appIdentifier);
    }

    /// @notice Return the current app ID in diamond
    /// @return appCount - The latest app ID of the diamond
    function getAppCount() external view returns (uint256 appCount) {
        return LibApp.getAppCount();
    }

    /// @notice Return token balance of app
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @return quantity - The amount of tokens in balance
    function getAppBalance(
        uint256 appIdentifier,
        address token
    ) external view returns (uint256 quantity) {
        return LibSatBank.getAppBalance(appIdentifier, token);
    }

    /// @notice Retrieve appID from embeddedRequestID
    /// @param embeddedRequestID - requestID with appID embedded
    /// @return appID - Unique id of an app
    function getAppIDfromRequestID(
        uint256 embeddedRequestID
    ) external pure returns (uint32 appID) {
        return LibSatBank.getAppIDfromRequestID(embeddedRequestID);
    }

    /// @notice Transfer tokens from the message sender into an app's account
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - Number of tokens (in wei) to transfer
    /// @custom:emits AppFundsDeposited
    function depositToApp(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) external diamondNonReentrant {
        LibSatBank.depositToApp(appIdentifier, token, quantity);
    }

    /// @notice Transfer tokens out of the Satellite bank from an app's account to the message sender
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - Number of tokens (in wei) to transfer
    /// @custom:emits AppFundsWithdrawn
    function withdrawFromApp(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) external diamondNonReentrant {
        LibAccessControl.enforceAppOwner(appIdentifier);
        LibSatBank.withdrawFromApp(appIdentifier, token, quantity);
    }
}
