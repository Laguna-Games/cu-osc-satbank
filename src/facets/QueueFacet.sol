// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibSatBank} from "../libraries/LibSatBank.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";

/// @title Queue Facet
/// @author Ignacio Borovsky
/// @notice This contract adds methods to manage the state of the queue in the sattelite bank
/// @dev QueueFacet contract is attached to the Diamond as a Facet
contract QueueFacet {
    /// @notice Returns the transaction data at queue index
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param user - The address of the user
    /// @param index - The index of transaction in the queue
    /// @return time - The time of transaction
    /// @return quantity - The quantity of tokens claimed in transaction
    function getTxDataAtQueueIndex(
        uint256 appIdentifier,
        address token,
        address user,
        uint256 index
    ) external view returns (uint256 time, uint256 quantity) {
        return
            LibSatBank.getTxDataAtQueueIndex(appIdentifier, token, user, index);
    }

    /// @notice Returns the transaction queue for given user, token and appID
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param user - The address of the user
    /// @return time - The timestamp series of transactions
    /// @return quantity - The quantity series of transactions
    function getTxQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) external view returns (uint256[] memory time, uint256[] memory quantity) {
        return LibSatBank.getTxQueue(appIdentifier, token, user);
    }

    /// @notice Returns the transaction queue length for given user, token and appID
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param user - The address of the user
    /// @return length - The length of transaction queue
    function getTxQueueLength(
        uint256 appIdentifier,
        address token,
        address user
    ) external view returns (uint256 length) {
        return LibSatBank.getTxQueueLength(appIdentifier, token, user);
    }

    /// @notice Returns the first element of transaction queue for given user, token and appID
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param user - The address of the user
    /// @return time - The timestamp series of transactions
    /// @return quantity - The quantity series of transactions
    function getFirstTxInQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) external view returns (uint256 time, uint256 quantity) {
        return LibSatBank.getFirstTxInQueue(appIdentifier, token, user);
    }

    /// @notice Returns the last element of transaction queue for given user, token and appID
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param user - The address of the user
    /// @return time - The timestamp series of transactions
    /// @return quantity - The quantity series of transactions
    function getLastTxInQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) external view returns (uint256 time, uint256 quantity) {
        return LibSatBank.getLastTxInQueue(appIdentifier, token, user);
    }

    /// @notice Returns the first element's index in queue for given user, token and appID
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param user - The address of the user
    /// @return idx - first element's index in queue
    function getTxQueueFirstIdx(
        uint256 appIdentifier,
        address token,
        address user
    ) external view returns (uint256 idx) {
        return LibSatBank.getTxQueueFirstIdx(appIdentifier, token, user);
    }

    /// @notice Returns the last element's index in queue for given user, token and appID
    /// @param appIdentifier - Unique id of an app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param user - The address of the user
    /// @return idx - last element's index in queue
    function getTxQueueLastIdx(
        uint256 appIdentifier,
        address token,
        address user
    ) external view returns (uint256 idx) {
        return LibSatBank.getTxQueueLastIdx(appIdentifier, token, user);
    }
}
