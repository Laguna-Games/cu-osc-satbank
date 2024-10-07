// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @title LibQueue
/// @author Shiva Shanmuganathan
/// @dev Implementation of the queue data structure, providing a library with struct definition for queue storage in consuming contracts.
/// @notice This library provides functionalities to manage a queue data structure, allowing contracts to enqueue and dequeue items.
library LibQueue {
    struct QueueStorage {
        mapping(uint256 => TxData) data;
        uint256 first;
        uint256 last;
    }

    struct TxData {
        uint256 time;
        uint256 quantity;
    }

    /// @dev Initializes the queue by setting the first and last indices.
    /// @param queue The queue to initialize.
    function initialize(QueueStorage storage queue) internal {
        queue.first = 1;
        queue.last = 0;
    }

    /// @dev Checks if the queue has been initialized.
    /// @param queue The queue to check.
    /// @return isQueueInitialized True if the queue is initialized, false otherwise.
    function isInitialized(QueueStorage storage queue) internal view returns (bool isQueueInitialized) {
        return queue.first != 0;
    }

    /// @dev Checks if the queue is initialized and raises an error if not.
    /// @param queue The queue to check for initialization.
    function enforceQueueInitialized(QueueStorage storage queue) internal view {
        require(isInitialized(queue), 'LibQueue: Queue is not initialized.');
    }

    /// @dev Function to check if the queue is not empty.
    /// @param queue The queue to check.
    function enforceNonEmptyQueue(QueueStorage storage queue) internal view {
        require(!isEmpty(queue), 'LibQueue: Queue is empty.');
    }

    /// @dev Returns the length of the queue.
    /// @param queue The queue to get the length of.
    /// @return queueLength The length of the queue.
    function length(QueueStorage storage queue) internal view returns (uint256 queueLength) {
        if (queue.last < queue.first) {
            return 0;
        }
        return queue.last - queue.first + 1;
    }

    /// @dev Checks if the queue is empty.
    /// @param queue The queue to check.
    /// @return isQueueEmpty True if the queue is empty, false otherwise.
    function isEmpty(QueueStorage storage queue) internal view returns (bool isQueueEmpty) {
        return length(queue) == 0;
    }

    /// @dev Enqueues a new item into the queue.
    /// @param queue The queue to enqueue the item into.
    /// @param time The timestamp of the item.
    /// @param quantity The quantity associated with the item.
    function enqueue(QueueStorage storage queue, uint256 time, uint256 quantity) internal {
        enforceQueueInitialized(queue);
        queue.data[++queue.last] = TxData(time, quantity);
    }

    /// @dev Dequeues an item from the front of the queue.
    /// @param queue The queue to dequeue an item from.
    /// @return time The timestamp of the dequeued item.
    /// @return quantity The quantity associated with the dequeued item.
    function dequeue(QueueStorage storage queue) internal returns (uint256 time, uint256 quantity) {
        enforceQueueInitialized(queue);
        enforceNonEmptyQueue(queue);
        TxData memory txData = queue.data[queue.first];
        time = txData.time;
        quantity = txData.quantity;
        delete queue.data[queue.first];
        queue.first = queue.first + 1;
    }

    /// @dev Returns the item at the front of the queue without dequeuing it.
    /// @param queue The queue to get the front item from.
    /// @return time The timestamp of the front item.
    /// @return quantity The quantity associated with the front item.
    function peek(QueueStorage storage queue) internal view returns (uint256 time, uint256 quantity) {
        enforceNonEmptyQueue(queue);
        TxData memory txData = queue.data[queue.first];
        time = txData.time;
        quantity = txData.quantity;
    }

    /// @dev Returns the item at the end of the queue without dequeuing it.
    /// @param queue The queue to get the last item from.
    /// @return time The timestamp of the last item.
    /// @return quantity The quantity associated with the last item.
    function peekLast(QueueStorage storage queue) internal view returns (uint256 time, uint256 quantity) {
        enforceNonEmptyQueue(queue);
        TxData memory txData = queue.data[queue.last];
        time = txData.time;
        quantity = txData.quantity;
    }

    /// @dev Returns the item at the given index in the queue.
    /// @param queue The queue to get the item from.
    /// @param idx The index of the item to retrieve.
    /// @return time The timestamp of the item at the given index.
    /// @return quantity The quantity associated with the item at the given index.
    function at(QueueStorage storage queue, uint256 idx) internal view returns (uint256 time, uint256 quantity) {
        idx = idx + queue.first;
        TxData memory txData = queue.data[idx];
        time = txData.time;
        quantity = txData.quantity;
        return (time, quantity);
    }

    function getTxQueueFirstIdx(QueueStorage storage queue) internal view returns (uint256 idx) {
        return queue.first;
    }

    function getTxQueueLastIdx(QueueStorage storage queue) internal view returns (uint256 idx) {
        return queue.last;
    }
}
