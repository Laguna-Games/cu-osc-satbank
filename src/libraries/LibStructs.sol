// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library LibStructs {
    struct TokenAmount {
        address token; //  Must support IERC20
        uint256 quantity; //  wei
    }

    struct Fee {
        address token; //  Must support IERC20
        uint8 percent; //  [0-100]
    }
}