// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibStructs} from "./LibStructs.sol";

library LibEvents {
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

    event DebugActivity(string method, address indexed caller);
}