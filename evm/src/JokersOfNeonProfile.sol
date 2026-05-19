// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract JokersOfNeonProfile is Ownable {
    error ZeroAddress();
    error GameNotFound(uint32 gameId);
    error RoundNotFound(uint32 gameId, uint32 roundId);
    error InvalidGameRange(uint32 minGameId, uint32 maxGameId);

    struct PlayerStats {
        address player;
        uint32 gamesPlayed;
        uint32 gamesWon;
        uint32 highCardPlayed;
        uint32 pairPlayed;
        uint32 twoPairPlayed;
        uint32 threeOfAKindPlayed;
        uint32 fourOfAKindPlayed;
        uint32 fiveOfAKindPlayed;
        uint32 fullHousePlayed;
        uint32 flushPlayed;
        uint32 straightPlayed;
        uint32 straightFlushPlayed;
        uint32 royalFlushPlayed;
        uint32 lootBoxesPurchased;
        uint32 cardsPurchased;
        uint32 specialsPurchased;
        uint32 specialsSold;
        uint32 powerUpsPurchased;
        uint32 levelUpsPurchased;
        uint32 modifiersPurchased;
        uint32 rerollsPurchased;
        uint32 burnPurchased;
    }

    struct GameData {
        uint32 id;
        address owner;
        uint32 playerScore;
        uint32[] specials;
        uint32 cash;
        uint32 round;
        bool isTournament;
        uint32 level;
        string playerName;
    }

    struct RoundData {
        uint32 gameId;
        uint32 roundId;
        address playerAddress;
        uint32 currentScore;
        uint32 targetScore;
        uint32[] rages;
    }

    struct PlayerProgression {
        address player;
        uint8 tier;
        uint32 totalRuns;
        uint32 maxLevel;
        uint32 maxRound;
    }

    mapping(uint32 => GameData) private _games;
    mapping(uint32 => bool) private _gameExists;

    mapping(uint32 => mapping(uint32 => RoundData)) private _rounds;
    mapping(uint32 => mapping(uint32 => bool)) private _roundExists;
    mapping(uint32 => uint32) private _maxRoundIdByGame;

    mapping(address => PlayerProgression) private _progressions;
    mapping(address => PlayerStats) private _playerStats;

    event GameDataSet(uint32 indexed gameId, address indexed player, uint32 score, uint32 round);
    event RoundDataSet(uint32 indexed gameId, uint32 indexed roundId, address indexed player, uint32 currentScore);
    event PlayerStatsAdded(address indexed player, uint32 gamesPlayed, uint32 gamesWon);
    event ProgressionSynced(address indexed player, uint8 tier, uint32 totalRuns, uint32 maxLevel, uint32 maxRound);

    constructor() Ownable(msg.sender) {}

    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        super.transferOwnership(newOwner);
    }

    function setGameData(GameData calldata gameData) external onlyOwner {
        if (gameData.owner == address(0)) revert ZeroAddress();

        GameData storage game = _games[gameData.id];
        game.id = gameData.id;
        game.owner = gameData.owner;
        game.playerScore = gameData.playerScore;
        game.cash = gameData.cash;
        game.round = gameData.round;
        game.isTournament = gameData.isTournament;
        game.level = gameData.level;
        game.playerName = gameData.playerName;

        _replaceUint32Array(game.specials, gameData.specials);
        _gameExists[gameData.id] = true;

        emit GameDataSet(gameData.id, gameData.owner, gameData.playerScore, gameData.round);
    }

    function getGameData(uint32 gameId) external view returns (GameData memory) {
        if (!_gameExists[gameId]) revert GameNotFound(gameId);
        return _games[gameId];
    }

    function setRoundData(RoundData calldata roundData) external onlyOwner {
        if (!_gameExists[roundData.gameId]) revert GameNotFound(roundData.gameId);
        if (roundData.playerAddress == address(0)) revert ZeroAddress();

        RoundData storage round = _rounds[roundData.gameId][roundData.roundId];
        round.gameId = roundData.gameId;
        round.roundId = roundData.roundId;
        round.playerAddress = roundData.playerAddress;
        round.currentScore = roundData.currentScore;
        round.targetScore = roundData.targetScore;

        _replaceUint32Array(round.rages, roundData.rages);
        _roundExists[roundData.gameId][roundData.roundId] = true;

        if (roundData.roundId > _maxRoundIdByGame[roundData.gameId]) {
            _maxRoundIdByGame[roundData.gameId] = roundData.roundId;
        }

        emit RoundDataSet(roundData.gameId, roundData.roundId, roundData.playerAddress, roundData.currentScore);
    }

    function getRoundData(uint32 gameId, uint32 roundId) external view returns (RoundData memory) {
        if (!_roundExists[gameId][roundId]) revert RoundNotFound(gameId, roundId);
        return _rounds[gameId][roundId];
    }

    function getRoundsByGameId(uint32 gameId) external view returns (RoundData[] memory rounds) {
        if (!_gameExists[gameId]) revert GameNotFound(gameId);

        uint32 maxRoundId = _maxRoundIdByGame[gameId];
        uint256 count;

        for (uint32 roundId; roundId <= maxRoundId;) {
            if (_roundExists[gameId][roundId]) {
                ++count;
            }

            if (roundId == maxRoundId) break;
            unchecked {
                ++roundId;
            }
        }

        rounds = new RoundData[](count);
        uint256 index;

        for (uint32 roundId; roundId <= maxRoundId;) {
            if (_roundExists[gameId][roundId]) {
                rounds[index] = _rounds[gameId][roundId];
                ++index;
            }

            if (roundId == maxRoundId) break;
            unchecked {
                ++roundId;
            }
        }
    }

    function addPlayerStats(PlayerStats calldata playerStats) external onlyOwner {
        if (playerStats.player == address(0)) revert ZeroAddress();

        PlayerStats storage currentPlayerStats = _playerStats[playerStats.player];
        currentPlayerStats.player = playerStats.player;
        currentPlayerStats.gamesPlayed += playerStats.gamesPlayed;
        currentPlayerStats.gamesWon += playerStats.gamesWon;
        currentPlayerStats.highCardPlayed += playerStats.highCardPlayed;
        currentPlayerStats.pairPlayed += playerStats.pairPlayed;
        currentPlayerStats.twoPairPlayed += playerStats.twoPairPlayed;
        currentPlayerStats.threeOfAKindPlayed += playerStats.threeOfAKindPlayed;
        currentPlayerStats.fourOfAKindPlayed += playerStats.fourOfAKindPlayed;
        currentPlayerStats.fiveOfAKindPlayed += playerStats.fiveOfAKindPlayed;
        currentPlayerStats.fullHousePlayed += playerStats.fullHousePlayed;
        currentPlayerStats.flushPlayed += playerStats.flushPlayed;
        currentPlayerStats.straightPlayed += playerStats.straightPlayed;
        currentPlayerStats.straightFlushPlayed += playerStats.straightFlushPlayed;
        currentPlayerStats.royalFlushPlayed += playerStats.royalFlushPlayed;
        currentPlayerStats.lootBoxesPurchased += playerStats.lootBoxesPurchased;
        currentPlayerStats.cardsPurchased += playerStats.cardsPurchased;
        currentPlayerStats.specialsPurchased += playerStats.specialsPurchased;
        currentPlayerStats.specialsSold += playerStats.specialsSold;
        currentPlayerStats.powerUpsPurchased += playerStats.powerUpsPurchased;
        currentPlayerStats.levelUpsPurchased += playerStats.levelUpsPurchased;
        currentPlayerStats.modifiersPurchased += playerStats.modifiersPurchased;
        currentPlayerStats.rerollsPurchased += playerStats.rerollsPurchased;
        currentPlayerStats.burnPurchased += playerStats.burnPurchased;

        emit PlayerStatsAdded(playerStats.player, currentPlayerStats.gamesPlayed, currentPlayerStats.gamesWon);
    }

    function getPlayerStats(address player) external view returns (PlayerStats memory) {
        return _playerStats[player];
    }

    function syncProgression(address player, uint8 tier, uint32 totalRuns, uint32 maxLevel, uint32 maxRound)
        external
        onlyOwner
    {
        if (player == address(0)) revert ZeroAddress();

        PlayerProgression storage existing = _progressions[player];

        uint8 newTier = tier > existing.tier ? tier : existing.tier;
        uint32 newTotalRuns = totalRuns > existing.totalRuns ? totalRuns : existing.totalRuns;
        uint32 newMaxLevel = maxLevel > existing.maxLevel ? maxLevel : existing.maxLevel;
        uint32 newMaxRound;

        if (maxLevel > existing.maxLevel) {
            newMaxRound = maxRound;
        } else if (maxLevel == existing.maxLevel && maxRound > existing.maxRound) {
            newMaxRound = maxRound;
        } else {
            newMaxRound = existing.maxRound;
        }

        existing.player = player;
        existing.tier = newTier;
        existing.totalRuns = newTotalRuns;
        existing.maxLevel = newMaxLevel;
        existing.maxRound = newMaxRound;

        emit ProgressionSynced(player, newTier, newTotalRuns, newMaxLevel, newMaxRound);
    }

    function getProgression(address player) external view returns (PlayerProgression memory) {
        return _progressions[player];
    }

    function getGamesByIdRange(uint32 minGameId, uint32 maxGameId) external view returns (GameData[] memory games) {
        if (maxGameId < minGameId) revert InvalidGameRange(minGameId, maxGameId);

        uint256 count;

        for (uint32 gameId = minGameId; gameId <= maxGameId;) {
            if (_gameExists[gameId]) {
                ++count;
            }

            if (gameId == maxGameId) break;
            unchecked {
                ++gameId;
            }
        }

        games = new GameData[](count);
        uint256 index;

        for (uint32 gameId = minGameId; gameId <= maxGameId;) {
            if (_gameExists[gameId]) {
                games[index] = _games[gameId];
                ++index;
            }

            if (gameId == maxGameId) break;
            unchecked {
                ++gameId;
            }
        }
    }

    function gameExists(uint32 gameId) external view returns (bool) {
        return _gameExists[gameId];
    }

    function roundExists(uint32 gameId, uint32 roundId) external view returns (bool) {
        return _roundExists[gameId][roundId];
    }

    function maxRoundIdByGame(uint32 gameId) external view returns (uint32) {
        return _maxRoundIdByGame[gameId];
    }

    function _replaceUint32Array(uint32[] storage target, uint32[] calldata source) internal {
        while (target.length > 0) {
            target.pop();
        }

        uint256 length = source.length;
        for (uint256 i; i < length;) {
            target.push(source[i]);
            unchecked {
                ++i;
            }
        }
    }
}
