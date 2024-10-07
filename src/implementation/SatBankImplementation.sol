// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CutDiamond} from "../../lib/cu-osc-diamond-template/src/diamond/CutDiamond.sol";
import {LibStructs} from "../libraries/LibStructs.sol";

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract SatBankImplementation is CutDiamond {
    event GasReturnedToUser(
        uint256 amountReturned,
        uint256 txPrice,
        uint256 gasSpent,
        address indexed user,
        bool indexed success,
        string indexed transactionType
    );

    event GasReturnerMaxGasReturnedPerTransactionChanged(
        uint256 oldMaxGasReturnedPerTransaction,
        uint256 newMaxGasReturnedPerTransaction,
        address indexed admin
    );

    event GasReturnerInsufficientBalance(
        uint256 txPrice,
        uint256 gasSpent,
        address indexed user,
        string indexed transactionType
    );
    event Claimed(
        uint256 indexed dropId,
        address indexed claimant,
        address indexed signer,
        uint256 requestID,
        uint256 amount
    );
    event DropCreated(
        uint256 dropId,
        uint256 indexed tokenType,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );
    event DropStatusChanged(uint256 indexed dropId, bool status);
    event DropURIChanged(uint256 indexed dropId, string uri);
    event DropAuthorizationChanged(
        uint256 indexed dropId,
        address terminusAddress,
        uint256 poolId
    );
    event Withdrawal(
        address recipient,
        uint256 indexed tokenType,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );
    event NewAppCreated(uint256 indexed appIdentifier, string appName);

    event AppFeesChanged(
        uint256 indexed appIdentifier,
        LibStructs.Fee[] oldFees,
        LibStructs.Fee[] newFees
    );

    event AddedTokenRegistry(address indexed newToken);

    event RemovedTokenRegistry(address indexed removedToken);

    event AppDepositActiveChanged(
        uint256 indexed appIdentifier,
        bool indexed depositsAllowed
    );

    event AppWithdrawActiveChanged(
        uint256 indexed appIdentifier,
        bool indexed withdrawsAllowed
    );

    event AppNameChanged(uint256 indexed appIdentifier, string appName);

    event AppOwnershipChanged(
        uint256 indexed appIdentifier,
        address indexed oldOwner,
        address indexed newOwner
    );

    event AddedAppAdmin(
        uint256 indexed appIdentifier,
        address indexed newAdmin
    );

    event RemovedAppAdmin(
        uint256 indexed appIdentifier,
        address indexed removedAdmin
    );

    event AddedAppServer(
        uint256 indexed appIdentifier,
        address indexed newServer
    );

    event RemovedAppServer(
        uint256 indexed appIdentifier,
        address indexed removedServer
    );

    event AppFundsDeposited(
        uint256 indexed appIdentifier,
        address indexed token,
        address indexed depositer,
        uint256 oldBalance,
        uint256 newBalance
    );

    event AppFundsWithdrawn(
        uint256 indexed appIdentifier,
        address indexed token,
        address indexed receiver,
        uint256 oldBalance,
        uint256 newBalance
    );

    event NewProductCreated(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        string productName,
        LibStructs.TokenAmount[] costs,
        uint256 bundleSize,
        bool indexed scalar
    );

    event InventoryChanged(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        int256 oldInventory,
        int256 newInventory
    );

    event ProductActivation(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        bool indexed active
    );

    event ProductDeleted(
        uint256 indexed appIdentifier,
        uint256 indexed removedProductIdentifier
    );

    event ProductNameChanged(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        string oldName,
        string newName
    );

    event BundleSizeChanged(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        uint256 oldBundleSize,
        uint256 newBundleSize
    );

    event ProductCostReset(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        LibStructs.TokenAmount[] oldCosts
    );

    event ProductCostAdded(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        address indexed token,
        uint256 quantity
    );

    event ProductScalarSet(
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        bool indexed scalar
    );

    event ProductPurchased(
        address indexed buyer,
        uint256 indexed appIdentifier,
        uint256 indexed productIdentifier,
        LibStructs.TokenAmount[] costs,
        uint256 SKUQuantity,
        uint256 unitQuantity,
        int256 remainingInventory
    );

    event TokenDisburseSuccess(
        uint256 indexed roundTripId,
        uint256 indexed appIdentifier,
        address indexed user,
        LibStructs.TokenAmount[] yield
    );

    event DirectTokenDisbursement(
        uint256 indexed appIdentifier,
        address indexed user,
        address token, //  Must support IERC20
        uint256 quantity //  wei
    );

    event TokenDisbursementFulfilled(
        uint256 indexed roundTripId,
        uint256 indexed appIdentifier,
        address indexed user,
        address signer
    );

    event TokenDisburseCancelled(
        uint256 indexed roundTripId,
        uint256 indexed appIdentifier,
        address indexed user
    );

    event TxDisbursementLimitChanged(
        address indexed token,
        uint256 oldLimit,
        uint256 newLimit
    );

    event DailyDisbursementLimitChanged(
        address indexed token,
        uint256 oldLimit,
        uint256 newLimit
    );
}
