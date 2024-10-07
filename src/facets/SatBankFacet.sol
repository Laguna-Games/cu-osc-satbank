// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibSatBank} from "../libraries/LibSatBank.sol";
import {DropperFacet} from "./DropperFacet.sol";
import {DiamondReentrancyGuard} from "../../lib/web3/contracts/diamond/security/DiamondReentrancyGuard.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";

/// @title SatBank Facet
/// @author Shiva Shanmuganathan
/// @notice This contract enables us to deposit, withdraw and view the balances of satellite bank.
/// @dev SatBankFacet contract is attached to the Diamond as a Facet
contract SatBankFacet is DiamondReentrancyGuard, DropperFacet {
    /// @notice Generates claim message hash
    /// @dev This method overrides claimMessageHash from DropperFacet
    /// @param dropId - Unique id for the drop
    /// @param requestID - Unique id for the claim
    /// @param claimant - Address of the claimant
    /// @param blockDeadline - This block number marks the deadline for claiming the drop
    /// @param amount - The amount of ERC20 tokens to be claimed using the drop
    /// @return messageHash - Claim message hash
    function claimMessageHash(
        uint256 dropId,
        uint256 requestID,
        address claimant,
        uint256 blockDeadline,
        uint256 amount
    ) public view override returns (bytes32 messageHash) {
        return
            super.claimMessageHash(
                dropId,
                requestID,
                claimant,
                blockDeadline,
                amount
            );
    }

    /// @notice Users can use a signed message hash to claim the drop
    /// @dev This method overrides claim from DropperFacet.
    /// @param dropId - Unique id for the drop
    /// @param requestID - Unique id for the claim
    /// @param blockDeadline - This block number marks the deadline for claiming the drop
    /// @param amount - The amount of ERC20 tokens to be claimed from the drop
    /// @param signer - The address of the authorized signer
    /// @param signature - Signed claim message hash
    /// @custom:emits Claimed
    function claim(
        uint256 dropId,
        uint256 requestID,
        uint256 blockDeadline,
        uint256 amount,
        address signer,
        bytes memory signature
    ) public override {
        // get token address from dropId
        address token = super.getDrop(dropId).tokenAddress;

        // check request validity, app balance, and deduct tokens from app
        LibSatBank.tokenDeductionFromApp(requestID, token, amount);

        // extract appID from requestID
        uint256 appIdentifier = LibSatBank.getAppIDfromRequestID(requestID);

        // check if signer is valid by checking with app servers
        require(
            LibAccessControl.checkAppServer(appIdentifier, signer),
            "Signer not registered as app server"
        );

        // make the claim
        super.claim(
            dropId,
            requestID,
            blockDeadline,
            amount,
            signer,
            signature
        );

        // add to transaction queue
        LibSatBank.addTxQueue(appIdentifier, msg.sender, token, amount);
    }

    /// @notice Register tokens with the Satellite bank
    /// @param token - ERC20 token to add to token registry
    /// @custom:emits AddedTokenRegistry
    function addTokenRegistry(address token) external {
        LibContractOwner.enforceIsContractOwner();
        LibSatBank.addTokenRegistry(token);
    }

    /// @notice Removed registered tokens from the Satellite bank
    /// @param token - ERC20 token to remove from token registry
    /// @custom:emits RemovedTokenRegistry
    function removeTokenRegistry(address token) external {
        LibContractOwner.enforceIsContractOwner();
        LibSatBank.removeTokenRegistry(token);
    }

    /// @notice Set a limit on the number of <token> that can be withdrawn from app balance in a single transaction.
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - The max number of <token> allowed per disbursment
    /// @custom:emits TxDisbursementLimitChanged
    function setTxDisbursementLimit(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibSatBank.setTxDisbursementLimit(appIdentifier, token, quantity);
    }

    /// @notice Remove any disbursement limits for a <token>
    /// @param token - The address of an ERC20 cryptocurrency
    /// @custom:emits TxDisbursementLimitChanged
    function resetDisbursementLimit(
        uint256 appIdentifier,
        address token
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibSatBank.resetDisbursementLimit(appIdentifier, token);
    }

    /// @notice Set a limit on the number of <token> that a single wallet can withdraw from app balance in a rolling one day period (86400 seconds)
    /// @param token - The address of an ERC20 cryptocurrency
    /// @param quantity - The max number of <token> allowed per day
    /// @custom:emits DailyDisbursementLimitChanged
    function setMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token,
        uint256 quantity
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibSatBank.setMaxDisbursementPerDay(appIdentifier, token, quantity);
    }

    /// @notice Remove any disbursement daily limits for a <token>
    /// @param token - The address of an ERC20 cryptocurrency
    /// @custom:emits DailyDisbursementLimitChanged
    function resetMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibSatBank.resetMaxDisbursementPerDay(appIdentifier, token);
    }

    /// @notice Return tokens registered with the Satellite bank
    /// @return tokens - List of ERC20 cryptocurrency addresses
    function getTokenRegistry()
        external
        view
        returns (address[] memory tokens)
    {
        return LibSatBank.getTokenRegistry();
    }

    /// @notice Return token balance of satellite bank
    /// @param token - The address of an ERC20 cryptocurrency
    /// @return quantity - The amount of tokens in balance
    function getSatBankBalance(
        address token
    ) external view returns (uint256 quantity) {
        return LibSatBank.getSatBankBalance(token);
    }

    /// @notice Get the token disbursement limit for app
    /// @param token - The address of an ERC20 cryptocurrency
    /// @return quantity - The max number of <token> allowed per disbursement
    function getTxDisbursementLimit(
        uint256 appIdentifier,
        address token
    ) external view returns (uint256 quantity) {
        return LibSatBank.getTxDisbursementLimit(appIdentifier, token);
    }

    /// @notice Get the token disbursement limit for app in a one day period
    /// @param token - The address of an ERC20 cryptocurrency
    /// @return quantity - The max number of <token> allowed per day
    function getMaxDisbursementPerDay(
        uint256 appIdentifier,
        address token
    ) external view returns (uint256 quantity) {
        return LibSatBank.getMaxDisbursementPerDay(appIdentifier, token);
    }

    /// @notice Generate embeddedRequestID by embedding appID into requestID
    /// @param serverRequestID - Unique request id from server
    /// @param appID - Unique id of an app
    /// @return embeddedRequestID - requestID with appID embedded
    function generateEmbeddedRequestID(
        uint256 serverRequestID,
        uint32 appID
    ) external pure returns (uint256 embeddedRequestID) {
        return LibSatBank.generateEmbeddedRequestID(serverRequestID, appID);
    }

    /// @notice Retrieve serverRequestID from embeddedRequestID
    /// @param embeddedRequestID - requestID with appID embedded
    /// @return serverRequestID - Unique request id from server
    function getServerRequestID(
        uint256 embeddedRequestID
    ) external pure returns (uint256 serverRequestID) {
        return LibSatBank.getServerRequestID(embeddedRequestID);
    }

    function getHoldsPoolToken(
        address terminusAddress,
        uint256 poolId,
        uint256 amount
    ) external view returns (bool status) {
        return _holdsPoolToken(terminusAddress, poolId, amount);
    }
}
