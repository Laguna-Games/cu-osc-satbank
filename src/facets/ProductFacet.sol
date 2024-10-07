// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibStructs} from "../libraries/LibStructs.sol";
import {LibProduct} from "../libraries/LibProduct.sol";
import {DiamondReentrancyGuard} from "../../lib/web3/contracts/diamond/security/DiamondReentrancyGuard.sol";
import {LibGasReturner} from "../../lib/cu-osc-common/src/libraries/LibGasReturner.sol";

/// @title Product Facet
/// @author Shiva Shanmuganathan
/// @notice This contract enables us to create the product and configure its properties.
/// @dev ProductFacet contract is attached to the Diamond as a Facet
contract ProductFacet is DiamondReentrancyGuard {
    /// @notice Register a new product SKU for an app, with RBW cost shortcut
    /// @dev The external function can be accessed by app owner
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
    ) external returns (uint256 productIdentifier) {
        LibAccessControl.enforceAppOwnerOrAdmin(appIdentifier);
        return
            LibProduct.createProduct(
                appIdentifier,
                productName,
                RBWCost,
                bundleSize,
                scalar
            );
    }

    /// @notice Register a new product SKU for an app, with variable costs
    /// @dev The external function can be accessed by app owner
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
    ) external returns (uint256 productIdentifier) {
        LibAccessControl.enforceAppOwnerOrAdmin(appIdentifier);
        return
            LibProduct.createProductWithCosts(
                appIdentifier,
                productName,
                costs,
                bundleSize,
                scalar
            );
    }

    /// @notice Delete a product. Product must be inactive.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductDeleted
    function deleteProduct(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.deleteProduct(productIdentifier);
    }

    /// @notice Set the active flag on a product, allowing or preventing it from being bought.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param active - If true, users can buy this product
    /// @custom:emits ProductActivation
    function setProductActive(uint256 productIdentifier, bool active) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductActive(productIdentifier, active);
    }

    /// @notice Set the active flag on a product, allowing it to be bought.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductActivation
    function activateProduct(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductActive(productIdentifier, true);
    }

    /// @notice Reset the active flag on a product, preventing it from being bought.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductActivation
    function deactivateProduct(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductActive(productIdentifier, false);
    }

    /// @notice Set a new name for a product
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param productName - New product name
    /// @custom:emits ProductNameChanged
    function setProductName(
        uint256 productIdentifier,
        string memory productName
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductName(productIdentifier, productName);
    }

    /// @notice Set the number of in-app items this bundle buys. Product must be inactive.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of in-game items received for purchasing this product
    /// @custom:emits BundleSizeChanged
    function setBundleSize(
        uint256 productIdentifier,
        uint256 quantity
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setBundleSize(productIdentifier, quantity);
    }

    /// @notice Erase any Cost entries for a product. Product must be inactive.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductCostReset
    function resetProductCosts(uint256 productIdentifier) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.resetProductCosts(productIdentifier);
    }

    /// @notice Add a new ERC-20 cost to a product. Product must be inactive.
    /// @notice A product may have multiple "costs" of the same token. [ This method does not overwrite or remove duplicates ]
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - The number of <token> this product costs, in wei
    /// @custom:emits ProductCostAdded
    function addProductCost(
        uint256 productIdentifier,
        address token,
        uint256 quantity
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.addProductCost(productIdentifier, token, quantity);
    }

    /// @notice Set the scalar flag on a product, allowing it to be sold either as a one-at-a-time good, or as a bulk commodity.
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param scalar - If false, this product can only be bought one-at-a-time
    /// @custom:emits ProductScalarSet
    function setProductScalar(uint256 productIdentifier, bool scalar) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductScalar(productIdentifier, scalar);
    }

    /// @notice Set the bank inventory for a product
    /// @dev The external function can be accessed by app owner
    /// @param productIdentifier - Unique identifier for a product
    /// @param inventory - Number of times this product may be sold
    /// @custom:emits InventoryChanged
    function setProductInventory(
        uint256 productIdentifier,
        int256 inventory
    ) external {
        LibAccessControl.enforceAppOwnerOrAdmin(
            LibProduct.getAppIDForProduct(productIdentifier)
        );
        LibProduct.setProductInventory(productIdentifier, inventory);
    }

    /// @notice Purchase a single instance/bundle of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @custom:emits ProductPurchased
    function buyProduct(
        uint256 appIdentifier,
        uint256 productIdentifier
    ) external diamondNonReentrant {
        LibProduct.buyProduct(appIdentifier, productIdentifier);
    }

    /// @notice Purchase multiple instances/bundles of a product. This endpoint is called by the end user.
    /// @dev Caller must approve/allow all costs before buying. Any costs will be transferred from the user wallet into the bank.
    /// @param appIdentifier - Unique id of an app
    /// @param productIdentifier - Unique identifier for a product
    /// @param quantity - Number of product bundles to purchase
    /// @custom:emits ProductPurchased
    function buyScalarProduct(
        uint256 appIdentifier,
        uint256 productIdentifier,
        uint256 quantity
    ) external diamondNonReentrant {
        uint256 availableGas = gasleft();
        LibProduct.buyScalarProduct(appIdentifier, productIdentifier, quantity);
        LibGasReturner.returnGasToUser(
            "buyScalarProduct",
            (availableGas - gasleft()),
            payable(msg.sender)
        );
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
        external
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
        return LibProduct.getProduct(productIdentifier);
    }

    /// @notice Return the number of products in the bank's inventory, or `-1` for unlimited.
    /// @param productIdentifier - Unique identifier for a product
    /// @return inventory - Number of purchases remaining, or -1 for unlimited
    function getProductInventory(
        uint256 productIdentifier
    ) external view returns (int256 inventory) {
        return LibProduct.getProductInventory(productIdentifier);
    }

    /// @notice Return a list of active products that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active product ids of an app
    function getActiveProductsForApp(
        uint256 appIdentifier
    ) external view returns (uint256[] memory productIdentifiers) {
        return LibProduct.getActiveProductsForApp(appIdentifier);
    }

    /// @notice Return a list of products [active and inactive] that belong to the app
    /// @param appIdentifier - Unique id of an app
    /// @return productIdentifiers - List of active and inactive product ids of an app
    function getProductsForApp(
        uint256 appIdentifier
    ) external view returns (uint256[] memory productIdentifiers) {
        return LibProduct.getProductsForApp(appIdentifier);
    }
}
