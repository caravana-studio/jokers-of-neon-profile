// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// New deployment: operational progress is computed in the backend. This contract
/// mirrors versioned snapshots and immutable game results; it never awards XP twice.
contract JokersOfNeonDurableProfile is Ownable {
    error InvalidInput();
    error OperationConflict();
    error StaleVersion();
    error ResultConflict();

    struct Progress {
        uint8 tier;
        uint32 totalRuns;
        uint32 maxLevel;
        uint32 maxRound;
        uint64 totalXp;
        uint64 seasonXp;
        uint32 currentStreak;
        uint32 longestStreak;
        uint32 protectors;
        bool seasonPass;
    }

    struct Result {
        uint64 gameId;
        address player;
        uint32 level;
        uint32 round;
        uint64 score;
        uint64 finishedAt;
    }
    mapping(bytes32 => bytes32) public operationReceipts;
    mapping(address => mapping(uint32 => uint64)) public versions;
    mapping(address => mapping(uint32 => Progress)) private _progress;
    mapping(uint64 => Result) private _results;
    event ProgressPublished(bytes32 indexed operationId, address indexed player, uint32 indexed season, uint64 version);
    event ResultPublished(bytes32 indexed operationId, uint64 indexed gameId, address indexed player);
    constructor(address publisher) Ownable(publisher) {}

    function publishProgress(
        bytes32 operationId,
        address player,
        uint32 season,
        uint64 version,
        Progress calldata snapshot
    ) external onlyOwner {
        if (player == address(0) || season == 0 || version == 0 || snapshot.tier > 22) {
            revert InvalidInput();
        }
        if (!_record(operationId, keccak256(abi.encode(msg.sig, player, season, version, snapshot)))) return;
        if (version <= versions[player][season]) revert StaleVersion();
        versions[player][season] = version;
        _progress[player][season] = snapshot;
        emit ProgressPublished(operationId, player, season, version);
    }

    function publishResult(bytes32 operationId, Result calldata result) external onlyOwner {
        if (
            result.gameId == 0 || result.gameId > uint64(type(int64).max) || result.player == address(0)
                || result.finishedAt == 0
        ) revert InvalidInput();
        if (!_record(operationId, keccak256(abi.encode(msg.sig, result)))) return;
        Result storage previous = _results[result.gameId];
        if (previous.player != address(0) && keccak256(abi.encode(previous)) != keccak256(abi.encode(result))) {
            revert ResultConflict();
        }
        _results[result.gameId] = result;
        emit ResultPublished(operationId, result.gameId, result.player);
    }

    function getProgress(address player, uint32 season) external view returns (Progress memory) {
        return _progress[player][season];
    }

    function getResult(uint64 gameId) external view returns (Result memory) {
        return _results[gameId];
    }

    function _record(bytes32 operationId, bytes32 payloadHash) private returns (bool) {
        if (operationId == bytes32(0)) revert InvalidInput();
        bytes32 previous = operationReceipts[operationId];
        if (previous != bytes32(0)) {
            if (previous != payloadHash) revert OperationConflict();
            return false;
        }
        operationReceipts[operationId] = payloadHash;
        return true;
    }
}
