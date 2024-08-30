![alt text](images/castle.png)

## Overview

Castle Tokyo (also known as Castle Edo) is a proof-of-concept game designed to integrate Risc0's zkVM for offchain computation with Acurast Oracles to retrieve real-time weather data for Tokyo, which influences the outcome of battles.

This project was developed during a hackathon with the primary focus on laying the groundwork for future fully on-chain games rather than creating a UX-friendly experience. While some objectives have been achieved, significant work and integration are still required to reach the full potential of this concept. The ultimate goal is to establish a game framework that leverages zk technology for privacy and scalability, while using oracles to obtain random numbers (VRF) or other intriguing data—such as weather in our case—to enhance the game's dynamics.

## Rules of the Game 

In Castle Tokyo, there can only be one daimyo, the lord who rules the castle. To take control, other players must assemble their armies and launch attacks to dislodge the current daimyo. Each player receives a "turn" when they join the game, with one "turn" allowing for a single attempted attack. If the attack is successful, the attacker becomes the new daimyo.

Players have the option to purchase additional "turns," with the proceeds going to the current daimyo, creating an incentive to maintain control of the castle. This dynamic encourages strategic play, as holding the castle can be lucrative.

Both attacking and defending armies must adhere to specific rules and limitations, requiring players to act strategically. Additionally, the real-time weather in Tokyo plays a crucial role in the effectiveness of certain units. This means that choosing the right moment to attack, when the weather is most advantageous, can be the key to victory—mirroring the strategic importance of weather in real-world battles.

## Technical Details 

![alt text](images/architecture.png.png)

There are various parts to the game: 
* The Smart Contract 
* Weather Oracle 
* ZkVM 
  * Guest Code Hosted in Bonsai (or could be a private cluster)
  * Host Code (App that sends inputs to the Guest Code) - Simulated through tests in POC 
* Frontend ( Not implemented here) 

Lets go over each of them one at a time: 

## The Smart Contract

The CastleTokyo smart contract is designed to simulate a strategic game where players can join, set up defenses, and attempt to attack and take over a castle. The contract includes various roles, such as the "daimyo" (the lord of the castle), and involves mechanics like setting the weather, configuring defense units, and verifying attacks. Below is a detailed explanation of the main functions and features of the contract:

### Main Components:

#### Roles:

* Daimyo: The lord of the castle, who initially controls the defense and other key functionalities of the castle.
* Weather Setter (Acurast Oracle): An authorized address responsible for setting the weather conditions in the game.
* Joined Players: Players who have joined the game and can perform actions like attacking.


#### State Variables:

* daimyo: The address of the current daimyo.
* weatherSetter: The address authorized to set the weather.
* lastWeatherSetTime: The timestamp of when the weather was last set.
* attackCount: Tracks the number of attacks that have occurred.
* playerTurns: A mapping of player addresses to their remaining turns.
* joinedPlayers: A mapping to track which players have joined the game.
* currentDefense: A struct holding the current defense composition of the castle.
* currentWeather: An enum representing the current weather condition.
* Defense 

### Functions

1. setDefense
The setDefense function allows the current daimyo (the lord of the castle) to establish the castle's defensive capabilities by specifying the number of different military units, including infantry, cavalry, archers, catapults, and ballistae. This function ensures that the total number of defense units does not exceed a predefined maximum (DEFENSE_MAX). Only the daimyo can call this function, which is enforced by the onlyDaimyo modifier.

2. setWeather
The setWeather function is responsible for updating the weather conditions within the game. It is called by the Acurast oracle every 12 hours, which retrieves weather data from the OpenWeather API. The function takes an enum value representing the current weather state (Clear, Cloudy, or Raining) and records the timestamp when the weather was last set. The use of the onlyWeatherSetter modifier ensures that only the Acurast oracle, designated as the authorized weather setter, can call this function, maintaining the integrity and accuracy of the weather data within the game.

3. joinGame
The joinGame function allows a player to enter the game. Upon joining, the player is marked as a participant and is granted one turn, which they can use to perform actions like attacking the castle. The function ensures that a player can only join the game once by checking if they have already joined. This prevents duplicate entries and ensures fair gameplay.

4. gainTurn
The gainTurn function currently allows players who have already joined the game to gain additional turns for free. Each turn provides the player with an opportunity to take actions within the game, such as attempting to attack the castle. While the function is free for all players at the moment, there are plans to eventually require players to pay to acquire additional turns, adding an economic layer to the game's strategy. The function ensures that only players who have joined the game can gain turns, reinforcing the game's participation structure.

5. verifyAttack
The verifyAttack function is central to the gameplay, allowing players to attempt an attack on the castle. The function first checks that the player has at least one turn available and that the daimyo has set up a defense. The attack is then verified using an off-chain process, where a verifier checks the validity of the attack based on provided parameters (x and seal). If the attack is successful and x equals 1, the attacking player becomes the new daimyo. Regardless of the outcome, one turn is deducted from the player who called the function. This function enforces strategic gameplay, where players must manage their turns and carefully plan their attacks.
