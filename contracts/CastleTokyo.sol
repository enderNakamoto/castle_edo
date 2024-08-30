// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated contract after running `cargo build`.


contract CastleTokyo {

    // Enum for weather conditions
    enum Weather { Clear, Cloudy, Raining }

    // Struct for the defense army composition
    struct Defense {
        uint256 infantry;
        uint256 cavalry;
        uint256 archers;
        uint256 catapults;
        uint256 ballistae; // Optional, only for defenders
    }

    IRiscZeroVerifier public immutable verifier;
    bytes32 public constant imageId = ImageID.BATTLE_SIM_ID;

    // Constants
    uint256 public constant DEFENSE_MAX = 1000;

    // State variables
    address public daimyo;
    address public weatherSetter;
    uint256 public lastWeatherSetTime;
    uint256 public attackCount;
    mapping(address => uint256) public playerTurns;
    mapping(address => bool) public joinedPlayers;
    Defense public currentDefense;
    Weather public currentWeather;

    // Modifier to restrict actions to only the daimyo
    modifier onlyDaimyo() {
        require(msg.sender == daimyo, "Not the daimyo of the castle");
        _;
    }

    // Modifier to restrict actions to only joined players
    modifier onlyJoinedPlayer() {
        require(joinedPlayers[msg.sender], "You must join the game first");
        _;
    }

    // Modifier to restrict actions to only the designated weather setter
    modifier onlyWeatherSetter() {
        require(msg.sender == weatherSetter, "Not authorized to set weather");
        _;
    }

    constructor(IRiscZeroVerifier _verifier) {
        verifier = _verifier;
        daimyo = msg.sender;
        weatherSetter = msg.sender;
        currentWeather = Weather.Clear; // Default weather is set to Clear
        lastWeatherSetTime = block.timestamp;
    }

    // function set(uint256 x, bytes calldata seal) public {
    //     bytes memory journal = abi.encode(x);
    //     verifier.verify(seal, imageId, sha256(journal));
    //     number = x;
    // }

    // Function to set the defense army composition
    function setDefense(
        uint256 infantry,
        uint256 cavalry,
        uint256 archers,
        uint256 catapults,
        uint256 ballistae // Optional, only for defenders
    ) external onlyDaimyo {
        require(infantry + cavalry + archers + catapults + ballistae <= DEFENSE_MAX, "Total defense exceeds maximum allowed");
        
        currentDefense.infantry = infantry;
        currentDefense.cavalry = cavalry;
        currentDefense.archers = archers;
        currentDefense.catapults = catapults;
        currentDefense.ballistae = ballistae;
    }

    // Function to set the weather condition
    function setWeather(Weather _weather) external onlyWeatherSetter {
        currentWeather = _weather;
        lastWeatherSetTime = block.timestamp;
    }

    // Function to verify an attack
    function verifyAttack(uint256 x, bytes calldata seal) external onlyJoinedPlayer {
    require(playerTurns[msg.sender] > 0, "You need at least one turn to attack");
    require(
        currentDefense.infantry + currentDefense.cavalry + currentDefense.archers + currentDefense.catapults + currentDefense.ballistae > 0,
        "Castle must have a defense set"
    );

    // Verify the off-chain attack
    bytes memory journal = abi.encode(x);
    verifier.verify(seal, imageId, sha256(journal));
    
    // If x is 1, the attacker becomes the daimyo
    if (x == 1) {
        daimyo = msg.sender;
    }

    // Subtract 1 turn from the player
    playerTurns[msg.sender] -= 1;
}

    // Function to allow players to join the game
    function joinGame() external {
        require(!joinedPlayers[msg.sender], "You have already joined the game");

        joinedPlayers[msg.sender] = true;
        playerTurns[msg.sender] = 1; // Each player gets 1 turn upon joining
    }

    // Function to allow joined players to gain an additional turn
    function gainTurn() external onlyJoinedPlayer {
        playerTurns[msg.sender] += 1; // Add an additional turn for the player
    }

    // Function to get the current daimyo
    function getDaimyo() external view returns (address) {
        return daimyo;
    }

    // Function to get the current weather
    function getWeather() external view returns (Weather) {
        return currentWeather;
    }
}
