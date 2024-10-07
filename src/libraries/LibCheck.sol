// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library LibCheck {
    function enforceValidString(string memory str) internal pure {
        require(bytes(str).length > 0, "LibCheck: String cannot be empty");
    }

    function enforceValidAddress(address addr) internal pure {
        require(
            addr != address(0),
            "LibCheck: Address cannnot be zero address"
        );
    }

    function enforceValidPercent(uint256 percent) internal pure {
        require(
            percent >= 0 && percent <= 100,
            "LibCheck: Percent should be between 0 and 100"
        );
    }

    function enforceValidInventory(int256 inventory) internal pure {
        require(inventory != 0 && inventory >= -1, "No inventory");
    }

    function enforceValidAmount(uint256 amount) internal pure {
        require(amount > 0, "LibCheck: Amount should be above 0");
    }

    function enforceValidArray(address[] memory array) internal pure {
        require(array.length > 0, "LibCheck: Array cannot be empty");
    }
}