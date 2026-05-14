// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {JokersOfNeonProfile} from "../src/JokersOfNeonProfile.sol";

contract JokersOfNeonProfileTest {
    JokersOfNeonProfile internal profile;
    address internal player = address(0xCAFE);

    function setUp() public {
        profile = new JokersOfNeonProfile();
    }

    function testSetAndGetGameData() public {
        uint32[] memory specials = new uint32[](3);
        specials[0] = 7;
        specials[1] = 11;
        specials[2] = 19;

        profile.setGameData(
            JokersOfNeonProfile.GameData({
                id: 10,
                owner: player,
                playerScore: 4200,
                specials: specials,
                cash: 900,
                round: 4,
                isTournament: true,
                level: 8,
                playerName: "neon-joker"
            })
        );

        JokersOfNeonProfile.GameData memory game = profile.getGameData(10);
        _assertEq(game.id, 10);
        _assertEq(game.owner, player);
        _assertEq(game.playerScore, 4200);
        _assertEq(game.cash, 900);
        _assertEq(game.round, 4);
        _assertEq(game.isTournament, true);
        _assertEq(game.level, 8);
        _assertEq(game.playerName, "neon-joker");
        _assertEq(game.specials.length, 3);
        _assertEq(game.specials[0], 7);
        _assertEq(game.specials[2], 19);
    }

    function testSetAndGetRoundsByGameId() public {
        uint32[] memory specials = new uint32[](1);
        specials[0] = 5;

        profile.setGameData(
            JokersOfNeonProfile.GameData({
                id: 21,
                owner: player,
                playerScore: 1200,
                specials: specials,
                cash: 300,
                round: 2,
                isTournament: false,
                level: 3,
                playerName: "round-player"
            })
        );

        uint32[] memory firstRages = new uint32[](2);
        firstRages[0] = 1;
        firstRages[1] = 4;

        uint32[] memory secondRages = new uint32[](1);
        secondRages[0] = 9;

        profile.setRoundData(
            JokersOfNeonProfile.RoundData({
                gameId: 21, roundId: 0, playerAddress: player, currentScore: 100, targetScore: 500, rages: firstRages
            })
        );
        profile.setRoundData(
            JokersOfNeonProfile.RoundData({
                gameId: 21, roundId: 2, playerAddress: player, currentScore: 330, targetScore: 600, rages: secondRages
            })
        );

        JokersOfNeonProfile.RoundData memory exactRound = profile.getRoundData(21, 2);
        _assertEq(exactRound.gameId, 21);
        _assertEq(exactRound.roundId, 2);
        _assertEq(exactRound.currentScore, 330);
        _assertEq(exactRound.rages.length, 1);
        _assertEq(exactRound.rages[0], 9);

        JokersOfNeonProfile.RoundData[] memory rounds = profile.getRoundsByGameId(21);
        _assertEq(rounds.length, 2);
        _assertEq(rounds[0].roundId, 0);
        _assertEq(rounds[1].roundId, 2);
    }

    function testSyncProgressionKeepsBestValues() public {
        profile.syncProgression(player, 2, 10, 5, 8);
        profile.syncProgression(player, 1, 9, 4, 99);
        profile.syncProgression(player, 2, 12, 5, 9);
        profile.syncProgression(player, 3, 11, 6, 1);

        JokersOfNeonProfile.PlayerProgression memory progression = profile.getProgression(player);
        _assertEq(progression.player, player);
        _assertEq(uint256(progression.tier), 3);
        _assertEq(progression.totalRuns, 12);
        _assertEq(progression.maxLevel, 6);
        _assertEq(progression.maxRound, 1);
    }

    function testAddPlayerStatsAccumulatesValues() public {
        profile.addPlayerStats(
            JokersOfNeonProfile.PlayerStats({
                player: player,
                gamesPlayed: 3,
                gamesWon: 1,
                highCardPlayed: 5,
                pairPlayed: 4,
                twoPairPlayed: 3,
                threeOfAKindPlayed: 2,
                fourOfAKindPlayed: 1,
                fiveOfAKindPlayed: 1,
                fullHousePlayed: 2,
                flushPlayed: 3,
                straightPlayed: 4,
                straightFlushPlayed: 1,
                royalFlushPlayed: 0,
                lootBoxesPurchased: 2,
                cardsPurchased: 9,
                specialsPurchased: 7,
                specialsSold: 1,
                powerUpsPurchased: 6,
                levelUpsPurchased: 2,
                modifiersPurchased: 5,
                rerollsPurchased: 8,
                burnPurchased: 3
            })
        );

        profile.addPlayerStats(
            JokersOfNeonProfile.PlayerStats({
                player: player,
                gamesPlayed: 4,
                gamesWon: 2,
                highCardPlayed: 1,
                pairPlayed: 2,
                twoPairPlayed: 3,
                threeOfAKindPlayed: 4,
                fourOfAKindPlayed: 5,
                fiveOfAKindPlayed: 0,
                fullHousePlayed: 1,
                flushPlayed: 2,
                straightPlayed: 3,
                straightFlushPlayed: 1,
                royalFlushPlayed: 1,
                lootBoxesPurchased: 3,
                cardsPurchased: 1,
                specialsPurchased: 2,
                specialsSold: 4,
                powerUpsPurchased: 1,
                levelUpsPurchased: 3,
                modifiersPurchased: 2,
                rerollsPurchased: 1,
                burnPurchased: 5
            })
        );

        JokersOfNeonProfile.PlayerStats memory stats = profile.getPlayerStats(player);
        _assertEq(stats.player, player);
        _assertEq(stats.gamesPlayed, 7);
        _assertEq(stats.gamesWon, 3);
        _assertEq(stats.highCardPlayed, 6);
        _assertEq(stats.pairPlayed, 6);
        _assertEq(stats.twoPairPlayed, 6);
        _assertEq(stats.threeOfAKindPlayed, 6);
        _assertEq(stats.fourOfAKindPlayed, 6);
        _assertEq(stats.fiveOfAKindPlayed, 1);
        _assertEq(stats.fullHousePlayed, 3);
        _assertEq(stats.flushPlayed, 5);
        _assertEq(stats.straightPlayed, 7);
        _assertEq(stats.straightFlushPlayed, 2);
        _assertEq(stats.royalFlushPlayed, 1);
        _assertEq(stats.lootBoxesPurchased, 5);
        _assertEq(stats.cardsPurchased, 10);
        _assertEq(stats.specialsPurchased, 9);
        _assertEq(stats.specialsSold, 5);
        _assertEq(stats.powerUpsPurchased, 7);
        _assertEq(stats.levelUpsPurchased, 5);
        _assertEq(stats.modifiersPurchased, 7);
        _assertEq(stats.rerollsPurchased, 9);
        _assertEq(stats.burnPurchased, 8);
    }

    function testGetGamesByIdRangeFiltersMissingIds() public {
        uint32[] memory empty;

        profile.setGameData(
            JokersOfNeonProfile.GameData({
                id: 1,
                owner: address(0x1),
                playerScore: 10,
                specials: empty,
                cash: 20,
                round: 1,
                isTournament: false,
                level: 1,
                playerName: "one"
            })
        );
        profile.setGameData(
            JokersOfNeonProfile.GameData({
                id: 3,
                owner: address(0x3),
                playerScore: 30,
                specials: empty,
                cash: 40,
                round: 2,
                isTournament: true,
                level: 2,
                playerName: "three"
            })
        );

        JokersOfNeonProfile.GameData[] memory games = profile.getGamesByIdRange(1, 4);
        _assertEq(games.length, 2);
        _assertEq(games[0].id, 1);
        _assertEq(games[1].id, 3);
    }

    function _assertEq(uint256 left, uint256 right) internal pure {
        require(left == right, "assert eq failed");
    }

    function _assertEq(address left, address right) internal pure {
        require(left == right, "assert eq failed");
    }

    function _assertEq(bool left, bool right) internal pure {
        require(left == right, "assert eq failed");
    }

    function _assertEq(string memory left, string memory right) internal pure {
        require(keccak256(bytes(left)) == keccak256(bytes(right)), "assert eq failed");
    }
}
