// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibCheck} from "../libraries/LibCheck.sol";
import {LibSatBank} from "../libraries/LibSatBank.sol";
import {LibEvents} from "../libraries/LibEvents.sol";
import {LibServerSideSigning} from "../../lib/cu-osc-common/src/libraries/LibServerSideSigning.sol";
import {DiamondReentrancyGuard} from "../../lib/web3/contracts/diamond/security/DiamondReentrancyGuard.sol";
import {LibEnvironment} from "../../lib/cu-osc-common/src/libraries/LibEnvironment.sol";
import "../../lib/@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../../lib/@openzeppelin/contracts/utils/Strings.sol";
import {LibGasReturner} from "../../lib/cu-osc-common/src/libraries/LibGasReturner.sol";

/// @title Withdrawal Facet
/// @notice Public interface for game servers and players to withdraw game funds
contract WithdrawFacet is DiamondReentrancyGuard {
    /// @notice Distribute funds directly from an app to a user wallet
    /// @dev Only callable by Game Server wallets
    /// @dev read: https://www.notion.so/cryptounicorns/Stashing-Out-2-Super-user-Method-0538183f0e7d4772bd0fe520fca3f730
    /// @param appIdentifier - Unique id of an app
    /// @param to - Wallet to send funds to
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - Number of tokens (in wei) to transfer
    /// @param countTowardPlayersLimit - If false, this Tx ignores daily withdraw limits
    /// @custom:emits AppFundsWithdrawn event
    function disburseFundsToPlayer(
        uint256 appIdentifier,
        address to,
        address token,
        uint256 quantity,
        bool countTowardPlayersLimit
    ) public {
        LibAccessControl.enforceAppServerOrAppOwner(appIdentifier);
        LibSatBank.withdrawFromAppTo(
            appIdentifier,
            to,
            token,
            quantity,
            countTowardPlayersLimit
        );
    }

    /// @notice Batch call to disburseFundsToPlayer
    /// @dev Only callable by Game Server wallets
    /// @dev read: https://www.notion.so/cryptounicorns/Stashing-Out-2-Super-user-Method-0538183f0e7d4772bd0fe520fca3f730
    /// @param appIdentifier - Unique id of an app
    /// @param to - Array of wallets to send funds to
    /// @param token - Addresses of ERC20 cryptocurrency to distribute
    /// @param quantity - Number of tokens (in wei) to transfer per token
    /// @param countTowardPlayersLimit - If false, this Tx ignores daily withdraw limits
    /// @custom:emits AppFundsWithdrawn event for each transfer
    function batchDisburseFundsToPlayers(
        uint256 appIdentifier,
        address[] memory to,
        address[] memory token,
        uint256[] memory quantity,
        bool countTowardPlayersLimit
    ) public {
        LibAccessControl.enforceAppServerOrAppOwner(appIdentifier);
        LibCheck.enforceValidArray(to);
        uint256 len = to.length;
        require(
            token.length == len && quantity.length == len,
            "WithdrawFacet: array lengths mismatched"
        );
        for (uint256 i = 0; i < len; ++i) {
            LibSatBank.withdrawFromAppTo(
                appIdentifier,
                to[i],
                token[i],
                quantity[i],
                countTowardPlayersLimit
            );
        }
    }

    /// @notice Get message digest for a player fund withdraw call
    /// @dev The returned digest must be signed by a registered game server wallet
    /// @dev read: https://www.notion.so/cryptounicorns/Stashing-Out-3-SSS-Method-b6d04cf448174d6ca5fd31f1ee225e5a
    /// @param requestID - UUID for transaction - see generateEmbeddedRequestID
    /// @param appIdentifier - Unique id of an app
    /// @param to - Array of wallets to send funds to
    /// @param tokens - Array of addresses of ERC20 cryptocurrency to distribute
    /// @param quantities - Number of tokens (in wei) to transfer per token
    /// @param blockDeadline - Block number when this transaction expires
    /// @return digest - Unsigned hash of parameter values
    function withdrawPlayerFundsGenerateMessageHash(
        uint256 requestID,
        uint256 appIdentifier,
        address to,
        address[] memory tokens,
        uint256[] memory quantities,
        uint256 blockDeadline
    ) public view returns (bytes32 digest) {
        require(blockDeadline > 0, "blockDeadline cannot be 0");
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "withdrawPlayerFunds(uint256 requestID, uint256 appIdentifier, address[] tokens, uint256[] quantities, uint256 blockDeadline, address signer)"
                ),
                requestID,
                appIdentifier,
                to,
                tokens,
                quantities,
                blockDeadline
            )
        );
        digest = LibServerSideSigning._hashTypedDataV4(structHash);
    }

    /// @notice Get message digest for a player fund withdraw call
    /// @dev The returned digest must be signed by a registered game server wallet
    /// @dev read: https://www.notion.so/cryptounicorns/Stashing-Out-3-SSS-Method-b6d04cf448174d6ca5fd31f1ee225e5a
    /// @param requestID - UUID for transaction - see generateEmbeddedRequestID
    /// @param appIdentifier - Unique id of an app
    /// @param tokens - Array of addresses of ERC20 cryptocurrency to distribute
    /// @param quantities - Number of tokens (in wei) to transfer per token
    /// @param blockDeadline - Block number when this transaction expires
    /// @param signer - Public address of the game server that signed the message
    /// @param signature - encrypted message digest from the game server
    /// @custom:emits TokenDisbursementFulfilled event
    function withdrawPlayerFunds(
        uint256 requestID,
        uint256 appIdentifier,
        address[] memory tokens,
        uint256[] memory quantities,
        uint256 blockDeadline,
        address signer,
        bytes memory signature
    ) public {
        uint256 availableGas = gasleft();
        //  message digest signer must be server or app owner
        LibAccessControl.enforceAddressIsAppServerOrAppOwner(
            appIdentifier,
            signer
        );
        require(
            appIdentifier == LibSatBank.getAppIDfromRequestID(requestID),
            "withdrawPlayerFunds - appIdentifier does not match encoded requestID"
        );

        //  params match SSS, and were signed by the signer
        require(
            SignatureChecker.isValidSignatureNow(
                signer,
                withdrawPlayerFundsGenerateMessageHash(
                    requestID,
                    appIdentifier,
                    msg.sender,
                    tokens,
                    quantities,
                    blockDeadline
                ),
                signature
            ),
            "withdrawPlayerFunds - Payload must be signed by app server"
        );

        require(
            !LibServerSideSigning._checkRequest(requestID),
            "withdrawPlayerFunds - Request has already been fulfilled"
        );

        require(blockDeadline > 0, "blockDeadline cannot be 0");
        require(
            LibEnvironment.getBlockNumber() < blockDeadline,
            string.concat(
                "TTL expired: {block: ",
                Strings.toString(LibEnvironment.getBlockNumber()),
                ", deadline: ",
                Strings.toString(blockDeadline),
                "}"
            )
        );

        uint256 len = tokens.length;
        require(len > 0, "withdrawPlayerFunds - token array is empty");
        require(
            quantities.length == len,
            "withdrawPlayerFunds - mismatched number of token addresses and quantities"
        );

        for (uint256 i = 0; i < len; ++i) {
            LibSatBank.withdrawFromAppTo(
                appIdentifier,
                msg.sender,
                tokens[i],
                quantities[i],
                true
            );
        }

        LibServerSideSigning._completeRequest(requestID);
        emit LibEvents.TokenDisbursementFulfilled(
            requestID,
            appIdentifier,
            msg.sender,
            signer
        );
        LibGasReturner.returnGasToUser(
            "withdrawPlayerFunds",
            (availableGas - gasleft()),
            payable(msg.sender)
        );
    }
}
