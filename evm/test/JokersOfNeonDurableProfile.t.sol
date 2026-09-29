// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {JokersOfNeonDurableProfile as Profile} from "../src/JokersOfNeonDurableProfile.sol";

contract JokersOfNeonDurableProfileTest {
    Profile profile;

    function setUp() public {
        profile = new Profile(address(this));
    }

    function testLargeIdAndDuplicateResult() public {
        Profile.Result memory result = Profile.Result(9007199254740993, address(0xCAFE), 5, 3, 100, 1700000000);
        profile.publishResult(bytes32(uint256(1)), result);
        profile.publishResult(bytes32(uint256(1)), result);
        require(profile.getResult(result.gameId).gameId == result.gameId, "ID truncated");
        result.score++;
        (bool success,) = address(profile).call(abi.encodeCall(profile.publishResult, (bytes32(uint256(1)), result)));
        require(!success, "conflicting operation accepted");
        (success,) = address(profile).call(abi.encodeCall(profile.publishResult, (bytes32(uint256(2)), result)));
        require(!success, "immutable result overwritten");
    }

    function testProgressVersionsAndRetry() public {
        Profile.Progress memory p = Profile.Progress(2, 5, 4, 3, 100, 50, 4, 8, 2, true);
        profile.publishProgress(bytes32(uint256(1)), address(0xCAFE), 4, 2, p);
        profile.publishProgress(bytes32(uint256(1)), address(0xCAFE), 4, 2, p);
        (bool success,) =
            address(profile)
                .call(abi.encodeCall(profile.publishProgress, (bytes32(uint256(2)), address(0xCAFE), 4, 1, p)));
        require(!success, "stale version accepted");
        require(profile.getProgress(address(0xCAFE), 4).seasonXp == 50, "XP duplicated");
        require(profile.operationReceipts(bytes32(uint256(2))) == bytes32(0), "failed receipt persisted");
    }

    function testUnauthorizedPublisher() public {
        Profile other = new Profile(address(0xBEEF));
        Profile.Result memory result = Profile.Result(1, address(1), 1, 1, 1, 1);
        (bool success,) = address(other).call(abi.encodeCall(other.publishResult, (bytes32(uint256(1)), result)));
        require(!success, "unauthorized publisher");
    }
}
