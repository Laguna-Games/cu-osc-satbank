// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibStructs} from "./LibStructs.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {LibEvents} from "./LibEvents.sol";
import {LibApp} from "./LibApp.sol";
import {LibCheck} from "./LibCheck.sol";
import {LibQueue} from "./LibQueue.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";
import "../../lib/@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibSatBank {
    bytes32 private constant SATBANK_STORAGE_POSITION =
        keccak256("CryptoUnicorns.SatBank.Storage");

    using LibQueue for LibQueue.QueueStorage;

    struct SatBankStorage {
        address[] tokenRegistry;
        mapping(address => uint256) tokenIndex;
        // appID to token to balances
        mapping(uint256 => mapping(address => uint256)) appBalance;
        mapping(address => uint256) satbankBalance;
        mapping(uint256 => mapping(address => uint256)) txDisbursementLimit;
        mapping(uint256 => mapping(address => uint256)) dailyDisbursementLimit;
        mapping(uint256 => mapping(address => mapping(address => LibQueue.QueueStorage))) userTxQueue;
    }

    uint256 internal constant MAX_VALUE_224_BITS =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function depositToApp(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        enforceTokenIsAllowed(token);
        LibCheck.enforceValidAmount(quantity);
        LibApp.enforceAppDepositsEnabled(appIdentifier);

        SatBankStorage storage sbs = satBankStorage();
        address satBankAddress = address(this);
        IERC20 erc20Token = IERC20(token);
        uint256 oldBalance = sbs.appBalance[appIdentifier][token];
        bool status = erc20Token.transferFrom(
            msg.sender,
            satBankAddress,
            quantity
        );
        require(status == true, "LibSatBank: Transfer Failed");
        sbs.appBalance[appIdentifier][token] += quantity;
        uint256 newBalance = sbs.appBalance[appIdentifier][token];
        emit LibEvents.AppFundsDeposited(
            appIdentifier,
            token,
            msg.sender,
            oldBalance,
            newBalance
        );
    }

    function withdrawFromApp(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        enforceTokenIsAllowed(token);
        LibCheck.enforceValidAmount(quantity);
        LibApp.enforceAppWithdrawsAllowed(appIdentifier);

        SatBankStorage storage sbs = satBankStorage();
        IERC20 erc20Token = IERC20(token);
        enforceAppTokenQuantity(appIdentifier, token, quantity);

        uint256 oldBalance = sbs.appBalance[appIdentifier][token];
        sbs.appBalance[appIdentifier][token] -= quantity;
        uint256 newBalance = sbs.appBalance[appIdentifier][token];

        bool status = erc20Token.transfer(msg.sender, quantity);
        require(status == true, "LibSatBank: Transfer Failed");
        emit LibEvents.AppFundsWithdrawn(
            appIdentifier,
            token,
            msg.sender,
            oldBalance,
            newBalance
        );
    }

    function withdrawFromAppTo(
        uint256 appIdentifier,
        address to,
        address token,
        uint256 quantity,
        bool countTowardPlayersLimit
    ) internal {
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        enforceTokenIsAllowed(token);
        LibCheck.enforceValidAmount(quantity);
        LibApp.enforceAppWithdrawsAllowed(appIdentifier);

        SatBankStorage storage sbs = satBankStorage();
        IERC20 erc20Token = IERC20(token);
        enforceAppTokenQuantity(appIdentifier, token, quantity);

        uint256 oldBalance = sbs.appBalance[appIdentifier][token];
        sbs.appBalance[appIdentifier][token] -= quantity;
        uint256 newBalance = sbs.appBalance[appIdentifier][token];

        if (countTowardPlayersLimit) {
            LibSatBank.addTxQueue(appIdentifier, to, token, quantity);
        }

        bool status = erc20Token.transfer(to, quantity);
        require(status == true, "LibSatBank: withdrawFromAppTo Failed");
        emit LibEvents.AppFundsWithdrawn(
            appIdentifier,
            token,
            to,
            oldBalance,
            newBalance
        );
    }

    function addTokenRegistry(address token) internal {
        LibCheck.enforceValidAddress(token);
        enforceTokenIsNotRegistered(token);
        SatBankStorage storage sbs = satBankStorage();
        sbs.tokenRegistry.push(token);
        sbs.tokenIndex[token] = sbs.tokenRegistry.length;
        emit LibEvents.AddedTokenRegistry(token);
    }

    function removeTokenRegistry(address token) internal {
        enforceTokenIsRegistered(token);
        SatBankStorage storage sbs = satBankStorage();
        uint256 index = sbs.tokenIndex[token];
        uint256 toDeleteIndex = index - 1;
        uint256 lastIndex = sbs.tokenRegistry.length - 1;
        address lastToken = sbs.tokenRegistry[lastIndex];
        sbs.tokenRegistry[toDeleteIndex] = lastToken;
        sbs.tokenIndex[lastToken] = index;
        sbs.tokenRegistry.pop();
        delete sbs.tokenIndex[token];
        emit LibEvents.RemovedTokenRegistry(token);
    }

    function setTxDisbursementLimit(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        LibCheck.enforceValidAmount(quantity);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.txDisbursementLimit[appIdentifier][token];
        sbs.txDisbursementLimit[appIdentifier][token] = quantity;
        emit LibEvents.TxDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.txDisbursementLimit[appIdentifier][token]
        );
    }

    function resetDisbursementLimit(
        uint256 appIdentifier,
        address token
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.txDisbursementLimit[appIdentifier][token];
        sbs.txDisbursementLimit[appIdentifier][token] = 0;
        emit LibEvents.TxDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.txDisbursementLimit[appIdentifier][token]
        );
    }

    function setMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        LibCheck.enforceValidAmount(quantity);
        enforceValidDailyLimit(appIdentifier, token, quantity);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.dailyDisbursementLimit[appIdentifier][token];
        sbs.dailyDisbursementLimit[appIdentifier][token] = quantity;
        emit LibEvents.DailyDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.dailyDisbursementLimit[appIdentifier][token]
        );
    }

    function resetMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token
    ) internal {
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        SatBankStorage storage sbs = satBankStorage();
        uint256 oldLimit = sbs.dailyDisbursementLimit[appIdentifier][token];
        sbs.dailyDisbursementLimit[appIdentifier][token] = 0;
        emit LibEvents.DailyDisbursementLimitChanged(
            token,
            oldLimit,
            sbs.dailyDisbursementLimit[appIdentifier][token]
        );
    }

    function tokenDeductionFromApp(
        uint256 requestID,
        address token,
        uint256 quantity
    ) internal returns (uint256 appID) {
        // extract appID from requestID
        uint256 appIdentifier = getAppIDfromRequestID(requestID);
        // check if valid appID
        LibAccessControl.enforceValidAppOwner(appIdentifier);
        LibApp.enforceAppIsInitialized(appIdentifier);
        LibCheck.enforceValidAddress(token);
        enforceTokenIsAllowed(token);
        LibCheck.enforceValidAmount(quantity);
        LibApp.enforceAppWithdrawsAllowed(appIdentifier);
        // check if app has necessary balance to carry out this transaction
        enforceAppTokenQuantity(appIdentifier, token, quantity);
        // deduct tokens from app
        satBankStorage().appBalance[appIdentifier][token] -= quantity;
        return appIdentifier;
    }

    function addTxQueue(
        uint256 appIdentifier,
        address receiver,
        address token,
        uint256 quantity
    ) internal {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][receiver];
        uint256 queueLen = queue.length();
        uint256 timenow = block.timestamp;

        if (sbs.txDisbursementLimit[appIdentifier][token] > 0) {
            require(
                quantity <= sbs.txDisbursementLimit[appIdentifier][token],
                "Tx Limit Reached"
            );
        }

        uint dequeueCount = 0;
        uint256 totalQueueQuantity = 0;

        if (queue.isInitialized() == false) {
            queue.initialize();
        } else {
            for (uint256 i = 0; i < queueLen; i++) {
                uint256 j = queueLen - 1 - i;
                (uint256 queueTime, uint256 queueQuantity) = queue.at(j);
                if (timenow - queueTime <= 86400) {
                    totalQueueQuantity += queueQuantity;
                } else {
                    dequeueCount = queueLen - i;
                    break;
                }
            }
            if (dequeueCount > 0) {
                for (uint256 i = 0; i < dequeueCount; i++) {
                    queue.dequeue();
                }
            }
        }

        if (sbs.dailyDisbursementLimit[appIdentifier][token] > 0) {
            require(
                (totalQueueQuantity + quantity) <=
                    sbs.dailyDisbursementLimit[appIdentifier][token],
                "Daily Limit Reached"
            );
        }

        queue.enqueue(timenow, quantity);
    }

    function getTxQueueLength(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256 length) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.length();
    }

    function getFirstTxInQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256, uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.peek();
    }

    function getLastTxInQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256, uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.peekLast();
    }

    function getTxDataAtQueueIndex(
        uint256 appIdentifier,
        address token,
        address user,
        uint256 index
    ) internal view returns (uint256, uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.at(index);
    }

    function getTxQueue(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256[] memory, uint256[] memory) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];

        uint256 queueLen = queue.length();
        uint256[] memory timearray = new uint256[](queueLen);
        uint256[] memory quantityarray = new uint256[](queueLen);

        for (uint256 i = 0; i < queueLen; i++) {
            (uint256 time, uint256 quantity) = queue.at(i);
            timearray[i] = time;
            quantityarray[i] = quantity;
        }

        return (timearray, quantityarray);
    }

    function getTxQueueFirstIdx(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.getTxQueueFirstIdx();
    }

    function getTxQueueLastIdx(
        uint256 appIdentifier,
        address token,
        address user
    ) internal view returns (uint256) {
        LibSatBank.SatBankStorage storage sbs = LibSatBank.satBankStorage();
        LibQueue.QueueStorage storage queue = sbs.userTxQueue[appIdentifier][
            token
        ][user];
        return queue.getTxQueueLastIdx();
    }

    function getTokenRegistry() internal view returns (address[] memory) {
        return satBankStorage().tokenRegistry;
    }

    function getAppBalance(
        uint256 appIdentifier,
        address token
    ) internal view returns (uint256) {
        return satBankStorage().appBalance[appIdentifier][token];
    }

    function getSatBankBalance(address token) internal view returns (uint256) {
        return satBankStorage().satbankBalance[token];
    }

    function getTxDisbursementLimit(
        uint256 appIdentifier,
        address token
    ) internal view returns (uint256 quantity) {
        return satBankStorage().txDisbursementLimit[appIdentifier][token];
    }

    function getMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token
    ) internal view returns (uint256 quantity) {
        return satBankStorage().dailyDisbursementLimit[appIdentifier][token];
    }

    function generateEmbeddedRequestID(
        uint256 serverRequestID,
        uint32 appID
    ) internal pure returns (uint256) {
        require(
            serverRequestID <= MAX_VALUE_224_BITS,
            "serverRequestID exceeds max value to be stored in 224 bits"
        );
        uint256 maskedAppID = uint256(appID) << 224; // Shift appID to the left by 224 bits to fit into the high-order bits of a uint256
        uint256 embeddedRequestID = serverRequestID ^ maskedAppID; // XOR the maskedAppID with the requestID
        return embeddedRequestID;
    }

    function getAppIDfromRequestID(
        uint256 embeddedRequestID
    ) internal pure returns (uint32) {
        uint256 maskedAppID = embeddedRequestID >> 224; // Shift embeddedRequestID to the right by 224 bits to extract the appID
        uint32 appID = uint32(maskedAppID); // Convert the masked appID back to a uint32
        return appID;
    }

    function getServerRequestID(
        uint256 embeddedRequestID
    ) internal pure returns (uint256) {
        uint256 serverRequestID = embeddedRequestID & ((1 << 224) - 1); // Mask the embeddedRequestID to extract the original requestID
        return serverRequestID;
    }

    function enforceAppTokenQuantity(
        uint256 appIdentifier,
        address token,
        uint256 amount
    ) private view {
        uint256 oldBalance = satBankStorage().appBalance[appIdentifier][token];
        require(
            oldBalance >= amount,
            "Insufficient amount of tokens in app reserve"
        );
    }

    function enforceBankTokenQuantity(
        address token,
        uint256 amount
    ) private view {
        uint256 oldBalance = satBankStorage().satbankBalance[token];
        require(
            oldBalance >= amount,
            "Insufficient amount of tokens in bank reserve"
        );
    }

    function enforceTokenIsNotRegistered(address token) private view {
        require(
            (satBankStorage().tokenIndex[token] == 0) &&
                (token != LibResourceLocator.rbwToken()) &&
                (token != LibResourceLocator.unimToken()) &&
                (token != LibResourceLocator.wethToken()),
            "Token already exists"
        );
    }

    function enforceTokenIsRegistered(address token) internal view {
        require(
            satBankStorage().tokenIndex[token] != 0,
            "Token is not registered in satbank"
        );
    }

    function enforceTokenIsAllowed(address token) internal view {
        require(
            (satBankStorage().tokenIndex[token] != 0) ||
                (token == LibResourceLocator.rbwToken()) ||
                (token == LibResourceLocator.unimToken()) ||
                (token == LibResourceLocator.wethToken()),
            "Token is not allowed in satbank"
        );
    }

    function enforceRBWToken(address token) internal view {
        require(
            token == LibResourceLocator.rbwToken(),
            "Token address should be CU address"
        );
    }

    function enforceValidDailyLimit(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) private view {
        require(
            quantity >=
                satBankStorage().txDisbursementLimit[appIdentifier][token],
            "Daily disbursement limit must be higher than transaction disbursement limit"
        );
    }

    function satBankStorage()
        internal
        pure
        returns (SatBankStorage storage sbs)
    {
        bytes32 position = SATBANK_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sbs.slot := position
        }
    }
}
