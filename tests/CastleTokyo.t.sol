// Copyright 2024 RISC Zero, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.20;

import {RiscZeroCheats} from "risc0/test/RiscZeroCheats.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {CastleTokyo} from "../contracts/CastleTokyo.sol";
import {Elf} from "./Elf.sol"; // auto-generated contract after running `cargo build`.

contract EvenNumberTest is RiscZeroCheats, Test {

    CastleTokyo public castleTokyo;
    address daimyo = address(1);
    address player1 = address(2);
    address player2 = address(3);
    address weatherSetter = address(1);

    function setUp() public {
        vm.startPrank(daimyo);
        IRiscZeroVerifier verifier = deployRiscZeroVerifier();
        castleTokyo = new CastleTokyo(verifier);
        vm.stopPrank();
    }

    function test_InitialDaimyo() public {
        assertEq(castleTokyo.daimyo(), daimyo);
    }

    function test_DefaultWeatherIsClear() public {
        assertEq(uint(castleTokyo.currentWeather()), 0); // 0 corresponds to Weather.Clear
    }

    function testSetDefense() public {
        vm.startPrank(daimyo);
        castleTokyo.setDefense(100, 200, 300, 50, 20);
        (
            uint256 infantry, 
            uint256 cavalry, 
            uint256 archers, 
            uint256 catapults, 
            uint256 ballistae
        ) = castleTokyo.currentDefense();
        assertEq(infantry, 100);
        assertEq(cavalry, 200);
        assertEq(archers, 300);
        assertEq(catapults, 50);
        assertEq(ballistae, 20);
        vm.stopPrank();
    }

    function testSetDefenseRevertNotDaimyo() public {
        vm.startPrank(player1);
        vm.expectRevert("Not the daimyo of the castle");
        castleTokyo.setDefense(100, 200, 300, 50, 20);
        vm.stopPrank();
    }

    function testSetDefenseRevertExceedsMax() public {
        vm.startPrank(daimyo);
        vm.expectRevert("Total defense exceeds maximum allowed");
        castleTokyo.setDefense(500, 600, 200, 300, 100);
        vm.stopPrank();
    }

    function testJoinGame() public {
        vm.prank(player1);
        castleTokyo.joinGame();

        assertTrue(castleTokyo.joinedPlayers(player1));
        assertEq(castleTokyo.playerTurns(player1), 1);
    }

    function testJoinGameRevertAlreadyJoined() public {
        vm.startPrank(player1);
        castleTokyo.joinGame();

        vm.expectRevert("You have already joined the game");
        castleTokyo.joinGame();
        vm.stopPrank();
    }

    function testGainTurn() public {
        vm.prank(player1);
        castleTokyo.joinGame();

        vm.prank(player1);
        castleTokyo.gainTurn();
        assertEq(castleTokyo.playerTurns(player1), 2);
    }

    function testGainTurnRevertNotJoined() public {
        vm.prank(player1);
        vm.expectRevert("You must join the game first");
        castleTokyo.gainTurn();
    }

    function testSetWeather() public {
        vm.startPrank(weatherSetter);
        castleTokyo.setWeather(CastleTokyo.Weather.Cloudy);
        assertEq(uint(castleTokyo.currentWeather()), 1); // 1 corresponds to Weather.Cloudy
        assertEq(castleTokyo.lastWeatherSetTime(), block.timestamp);
        vm.stopPrank();
    }

    function testSetWeatherRevertNotWeatherSetter() public {
        vm.startPrank(player1);
        vm.expectRevert("Not authorized to set weather");
        castleTokyo.setWeather(CastleTokyo.Weather.Raining);
        vm.stopPrank();
    }

    function testVerifyAttack() public {
        vm.startPrank(daimyo);
        castleTokyo.setDefense(100, 200, 300, 50, 20);
        vm.stopPrank();

        vm.prank(player1);
        castleTokyo.joinGame();

        vm.prank(player1);
        castleTokyo.verifyAttack();

        assertEq(castleTokyo.playerTurns(player1), 0);
    }

    function testVerifyAttackRevertNoTurns() public {
        vm.startPrank(daimyo);
        castleTokyo.setDefense(100, 200, 300, 50, 20);
        vm.stopPrank();

        vm.prank(player1);
        castleTokyo.joinGame();

        vm.prank(player1);
        castleTokyo.verifyAttack();

        vm.prank(player1);
        vm.expectRevert("You need at least one turn to attack");
        castleTokyo.verifyAttack();
    }

    function testVerifyAttackRevertNoDefense() public {
        vm.prank(player1);
        castleTokyo.joinGame();

        vm.prank(player1);
        vm.expectRevert("Daimyo must have a defense set");
        castleTokyo.verifyAttack();
    }
}
