// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibStructs} from "./LibStructs.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {LibEvents} from "./LibEvents.sol";
import {LibSatBank} from "./LibSatBank.sol";
import {LibApp} from "./LibApp.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";
import {LibCheck} from "./LibCheck.sol";
import "../../lib/@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibProduct {
    bytes32 private constant PRODUCT_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.LibProduct.Storage");

    struct ProductData {
        uint256 appID;
        uint256 bundleSize;
        int256 inventory;
        string productName;
        bool active;
        bool scalar;
    }

    struct ProductStorage {
        uint256 currentProductID;
        // appID to productsIDs
        mapping(uint256 => uint256[]) appToProductID;
        // productID to ProductData
        mapping(uint256 => ProductData) productDetails;
        // productID to productCosts
        mapping(uint256 => LibStructs.TokenAmount[]) productCosts;
    }

    /// @notice Register a new product SKU for an app, with RBW cost shortcut
    /// @dev The internal function validates app id, name, rbw cost, and bundle size
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param RBWCost - RBW cost for this product
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @return productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProduct(
        uint256 appIdentifier,
        string memory productName,
        uint256 RBWCost,
        uint256 bundleSize,
        bool scalar
    ) internal returns (uint256 productIdentifier) {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidString(productName);
        LibCheck.enforceValidAmount(RBWCost);
        LibCheck.enforceValidAmount(bundleSize);
        LibStructs.TokenAmount[] memory costs = new LibStructs.TokenAmount[](1);
        costs[0] = LibStructs.TokenAmount(
            LibResourceLocator.rbwToken(),
            RBWCost
        );
        return
            createProductHelper(
                appIdentifier,
                productName,
                costs,
                bundleSize,
                scalar
            );
    }

    /// @notice Register a new product SKU for an app, with variable costs
    /// @dev The internal function validates app id, name, token costs, and bundle size
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param costs - List of cryptocurrency costs
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @param productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProductWithCosts(
        uint256 appIdentifier,
        string memory productName,
        LibStructs.TokenAmount[] memory costs,
        uint256 bundleSize,
        bool scalar
    ) internal returns (uint256 productIdentifier) {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidString(productName);
        LibCheck.enforceValidAmount(bundleSize);
        LibSatBank.enforceRBWToken(costs[0].token);
        return
            createProductHelper(
                appIdentifier,
                productName,
                costs,
                bundleSize,
                scalar
            );
    }

    /// @dev Internal helper function to enable registering new product for an app
    /// @param appIdentifier - Unique id of an app
    /// @param productName - A name for the new product
    /// @param costs - List of cryptocurrency costs
    /// @param bundleSize - Number of items bought in this bundle
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @param productIdentifier - Unique identifier for the product
    /// @custom:emits NewProductCreated
    function createProductHelper(
        uint256 appIdentifier,
        string memory productName,
        LibStructs.TokenAmount[] memory costs,
        uint256 bundleSize,
        bool scalar
    ) internal returns (uint256 productIdentifier) {
        ProductStorage storage sbps = productStorage();
        sbps.currentProductID++;
        uint256 productID = sbps.currentProductID;
        sbps.appToProductID[appIdentifier].push(productID);
        sbps.productDetails[productID].appID = appIdentifier;
        sbps.productDetails[productID].productName = productName;
        for (uint256 i = 0; i < costs.length; i++) {
            addProductCost(productID, costs[i].token, costs[i].quantity);
        }
        sbps.productDetails[productID].bundleSize = bundleSize;
        sbps.productDetails[productID].inventory = -1;
        sbps.productDetails[productID].scalar = scalar;
        emit LibEvents.NewProductCreated(
            appIdentifier,
            productID,
            productName,
            sbps.productCosts[productID],
            bundleSize,
            scalar
        );
        return productID;
    }

    /// @notice Set the active flag on a product, allowing or preventing it from being bought.
    /// @dev The internal function validates product id
    /// @param productIdentifier - Unique identifier for a product
    /// @param active - If true, users can buy this product
    /// @custom:emits ProductActivation
    function setProductActive(uint256 productIdentifier, bool active) internal {
        enforceValidProductID(productIdentifier);
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        uint256 appIdentifier = product.appID;
        product.active = active;
        emit LibEvents.ProductActivation(
            appIdentifier,
            productIdentifier,
            active
        );
    }

    /// @notice Delete a product. Product must be inactive.
    /// @dev The internal function validates product id and product status
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductDeleted
    function deleteProduct(uint256 productIdentifier) internal {
        enforceValidProductID(productIdentifier);
        enforceInactiveProduct(productIdentifier);
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        uint256 appID = product.appID;
        delete productStorage().productDetails[productIdentifier];
        delete productStorage().productCosts[productIdentifier];
        emit LibEvents.ProductDeleted(appID, productIdentifier);
    }

    /// @notice Set a new name for a product
    /// @dev The internal function validates product id and name
    /// @param productIdentifier - Unique identifier for a product
    /// @param productName - New product name
    /// @custom:emits ProductNameChanged
    function setProductName(
        uint256 productIdentifier,
        string memory productName
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        LibCheck.enforceValidString(productName);
        string memory oldName = product.productName;
        product.productName = productName;
        emit LibEvents.ProductNameChanged(
            product.appID,
            productIdentifier,
            oldName,
            productName
        );
    }

    /// @notice Set the number of in-app items this bundle buys. Product must be inactive.
    /// @dev The internal function validates product id and quantity
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of in-game items received for purchasing this product
    /// @custom:emits BundleSizeChanged
    function setBundleSize(
        uint256 productIdentifier,
        uint256 quantity
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        enforceInactiveProduct(productIdentifier);
        LibCheck.enforceValidAmount(quantity);
        uint256 oldBundleSize = product.bundleSize;
        product.bundleSize = quantity;
        emit LibEvents.BundleSizeChanged(
            product.appID,
            productIdentifier,
            oldBundleSize,
            quantity
        );
    }

    /// @notice Erase any Cost entries for a product. Product must be inactive.
    /// @dev The internal function validates product id
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductCostReset
    function resetProductCosts(uint256 productIdentifier) internal {
        enforceValidProductID(productIdentifier);
        enforceInactiveProduct(productIdentifier);
        LibStructs.TokenAmount[] memory oldCosts = productStorage()
            .productCosts[productIdentifier];
        delete productStorage().productCosts[productIdentifier];
        emit LibEvents.ProductCostReset(
            productStorage().productDetails[productIdentifier].appID,
            productIdentifier,
            oldCosts
        );
    }

    /// @notice Add a new ERC-20 cost to a product. Product must be inactive.
    /// @notice A product may have multiple "costs" of the same token. [ This method does not overwrite or remove duplicates ]
    /// @dev The internal function validates product id, token address and quantity
    /// @param productIdentifier - Unique identifier for a product
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - The number of <token> this product costs, in wei
    /// @custom:emits ProductCostAdded
    function addProductCost(
        uint256 productIdentifier,
        address token,
        uint256 quantity
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        LibCheck.enforceValidAmount(quantity);
        LibSatBank.enforceTokenIsAllowed(token);
        LibStructs.TokenAmount[] storage productCosts = productStorage()
            .productCosts[productIdentifier];

        productCosts.push(LibStructs.TokenAmount(token, quantity));
        emit LibEvents.ProductCostAdded(
            product.appID,
            productIdentifier,
            token,
            quantity
        );
    }

    /// @notice Set the scalar flag on a product, allowing it to be sold either as a one-at-a-time good, or as a bulk commodity.
    /// @dev The internal function validates product id
    /// @param productIdentifier - Unique identifier for a product
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @custom:emits ProductScalarSet
    function setProductScalar(uint256 productIdentifier, bool scalar) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        product.scalar = scalar;
        emit LibEvents.ProductScalarSet(
            product.appID,
            productIdentifier,
            scalar
        );
    }

    /// @notice Set the bank inventory for a product
    /// @dev The internal function validates product id and inventory
    /// @param productIdentifier - Unique identifier for a product
    /// @param inventory - Number of times this product may be sold
    /// @custom:emits InventoryChanged
    function setProductInventory(
        uint256 productIdentifier,
        int256 inventory
    ) internal {
        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];
        enforceValidProductID(productIdentifier);
        LibCheck.enforceValidInventory(inventory);
        int256 oldInventory = productStorage()
            .productDetails[productIdentifier]
            .inventory;
        product.inventory = inventory;
        emit LibEvents.InventoryChanged(
            product.appID,
            productIdentifier,
            oldInventory,
            inventory
        );
    }

    /// @notice Purchase a single instance/bundle of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @dev The internal function validates app id, product id, product and app status
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductPurchased
    function buyProduct(
        uint256 appIdentifier,
        uint256 productIdentifier
    ) internal {
        uint256 bundleQuantity = 1;
        bool scalar = false;
        buyProductHelper(
            appIdentifier,
            productIdentifier,
            bundleQuantity,
            scalar
        );
    }

    /// @notice Purchase multiple instances/bundles of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @dev The internal function validates app id, product id, product and app status
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of product bundles to purchase
    /// @custom:emits ProductPurchased
    function buyScalarProduct(
        uint256 appIdentifier,
        uint256 productIdentifier,
        uint256 quantity
    ) internal {
        bool scalar = true;

        buyProductHelper(appIdentifier, productIdentifier, quantity, scalar);
    }

    function buyProductHelper(
        uint256 appIdentifier,
        uint256 productIdentifier,
        uint256 bundleQuantity,
        bool scalar
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        enforceValidProductID(productIdentifier);
        enforceActiveProduct(productIdentifier);
        enforceProductBelongsToApp(appIdentifier, productIdentifier);
        LibApp.enforceAppDepositsEnabled(appIdentifier);
        if (scalar) {
            enforceScalarProduct(productIdentifier);
        } else {
            enforceNonScalarProduct(productIdentifier);
        }

        ProductData storage product = productStorage().productDetails[
            productIdentifier
        ];

        for (
            uint256 i = 0;
            i < productStorage().productCosts[productIdentifier].length;
            i++
        ) {
            LibStructs.TokenAmount memory productItem = productStorage()
                .productCosts[productIdentifier][i];
            address satBankAddress = address(this);
            uint256 tokenQuantity = productItem.quantity;
            IERC20 token = IERC20(productItem.token);
            bool status = token.transferFrom(
                msg.sender,
                satBankAddress,
                bundleQuantity * tokenQuantity
            );
            require(status == true, "LibSatBank: Transfer Failed");
            payPublisherFee(
                productItem,
                appIdentifier,
                bundleQuantity * tokenQuantity
            );
        }

        if (product.inventory != -1) {
            enforceSufficientInventory(productIdentifier, bundleQuantity);
            product.inventory -= int256(bundleQuantity);
        }
        emit LibEvents.ProductPurchased(
            msg.sender,
            appIdentifier,
            productIdentifier,
            productStorage().productCosts[productIdentifier],
            product.bundleSize,
            bundleQuantity * product.bundleSize,
            product.inventory
        );
    }

    /// @notice Pay publisher fee for a product to satellite bank.
    /// @notice This endpoint is not called by the end user.
    /// @param productItem - Token address and quantity for the product
    /// @param appIdentifier - Unique id of an app
    /// @param quantity - Number of product bundles to purchase
    function payPublisherFee(
        LibStructs.TokenAmount memory productItem,
        uint256 appIdentifier,
        uint256 quantity
    ) internal {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        uint256 publisherFee = LibApp.externalAppStorage().appPublisherFeesMap[
            appIdentifier
        ][productItem.token];
        if (publisherFee != 0) {
            uint256 percent = publisherFee;
            uint256 satbankBalance = ((quantity * percent) / 100);
            uint256 appBalance = quantity - satbankBalance;
            sbs.appBalance[appIdentifier][productItem.token] += appBalance;
            sbs.satbankBalance[productItem.token] += satbankBalance;
        } else {
            sbs.appBalance[appIdentifier][productItem.token] += quantity;
        }
    }

    /// @notice Return the number of products in the bank's inventory, or `-1` for unlimited.
    /// @param productIdentifier - Unique identifier for a product
    /// @return inventory - Number of purchases remaining, or -1 for unlimited
    function getProductInventory(
        uint256 productIdentifier
    ) internal view returns (int256 inventory) {
        ProductData memory product = productStorage().productDetails[
            productIdentifier
        ];
        return product.inventory;
    }

    /// @notice Return the current state of a product SKU
    /// @param productIdentifier - Unique identifier for a product
    /// @return appIdentifier - Unique id of the app that owns this product
    /// @return bundleSize - Number of in-app items rewarded for buying this product
    /// @return inventory - Number of times this product may be sold
    /// @return productName - Name of the product
    /// @return costs - List of cryptocurrency costs for this product
    /// @return active - When true, the product can be bought
    /// @return scalar - If false, this product can only be bought one-at-a-time
    function getProduct(
        uint256 productIdentifier
    )
        internal
        view
        returns (
            uint256 appIdentifier,
            uint256 bundleSize,
            int256 inventory,
            string memory productName,
            LibStructs.TokenAmount[] memory costs,
            bool active,
            bool scalar
        )
    {
        ProductData memory product = productStorage().productDetails[
            productIdentifier
        ];
        return (
            product.appID,
            product.bundleSize,
            product.inventory,
            product.productName,
            productStorage().productCosts[productIdentifier],
            product.active,
            product.scalar
        );
    }

    /// @notice Return a list of active products that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active product ids of an app
    function getActiveProductsForApp(
        uint256 appIdentifier
    ) internal view returns (uint256[] memory) {
        uint256[] memory productIDs = productStorage().appToProductID[
            appIdentifier
        ];
        uint256 productLength;
        for (uint256 i = 0; i < productIDs.length; i++) {
            if (productStorage().productDetails[productIDs[i]].active == true) {
                productLength++;
            }
        }

        uint256[] memory productIdentifiers = new uint256[](productLength);
        uint256 index;
        for (uint256 i = 0; i < productIDs.length; i++) {
            if (productStorage().productDetails[productIDs[i]].active == true) {
                productIdentifiers[index] = productIDs[i];
                index++;
            }
        }

        return productIdentifiers;
    }

    /// @notice Return a list of products [active and inactive] that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active and inactive product ids of an app
    function getProductsForApp(
        uint256 appIdentifier
    ) internal view returns (uint256[] memory) {
        return productStorage().appToProductID[appIdentifier];
    }

    function getAppIDForProduct(
        uint256 productIdentifier
    ) internal view returns (uint256 appIdentifier) {
        return productStorage().productDetails[productIdentifier].appID;
    }

    function enforceSufficientInventory(
        uint256 productIdentifier,
        uint256 bundleQuantity
    ) private view {
        ProductData memory product = productStorage().productDetails[
            productIdentifier
        ];
        require(
            product.inventory - int256(bundleQuantity) >= 0,
            "Inventory is low on stock"
        );
    }

    function enforceInactiveProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].active == false,
            "Product is active"
        );
    }

    function enforceActiveProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].active == true,
            "Product is inactive"
        );
    }

    function enforceProductBelongsToApp(
        uint256 appIdentifier,
        uint256 productIdentifier
    ) private view {
        require(
            productStorage().productDetails[productIdentifier].appID ==
                appIdentifier,
            "appID mismatch"
        );
    }

    function enforceValidProductID(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].appID != 0,
            "Product does not exist"
        );
    }

    function enforceNonScalarProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].scalar == false,
            "Product should be non scalar"
        );
    }

    function enforceScalarProduct(uint256 productIdentifier) private view {
        require(
            productStorage().productDetails[productIdentifier].scalar == true,
            "Product should be scalar"
        );
    }

    function productStorage()
        internal
        pure
        returns (ProductStorage storage sbps)
    {
        bytes32 position = PRODUCT_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbps.slot := position
        }
    }
}
