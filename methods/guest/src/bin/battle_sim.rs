use std::io::Read;

use risc0_zkvm::guest::env;
use alloy_primitives::U256;
use alloy_sol_types::SolValue;

// Immutable values used in the simulation
struct BattleConfig {
    pub catapult_attack: U256,
    pub catapult_health: U256,
    pub wall_health: U256,
    pub defending_catapults: U256,
}

impl BattleConfig {
    pub fn new() -> Self {
        Self {
            catapult_attack: U256::from(50),
            catapult_health: U256::from(300),
            wall_health: U256::from(100000),
            defending_catapults: U256::from(300),
        }
    }
}

// Struct representing a group of catapults in the battle
struct CatapultGroup {
    total_health: U256,
    attack: U256,
    initial_catapult_health: U256,
    attack_counter: U256,
}

impl CatapultGroup {
    fn new(num_catapults: U256, health: U256, attack: U256) -> Self {
        Self {
            total_health: num_catapults * health,
            attack,
            initial_catapult_health: health,
            attack_counter: U256::from(0),
        }
    }

    fn take_damage(&mut self, damage: U256) {
        if damage > self.total_health {
            self.total_health = U256::from(0);
        } else {
            self.total_health -= damage;
        }
    }

    fn remaining_catapults(&self) -> U256 {
        (self.total_health + self.initial_catapult_health - U256::from(1)) / self.initial_catapult_health
    }

    fn calculate_damage(&self) -> U256 {
        self.remaining_catapults() * self.attack
    }

    fn is_destroyed(&self) -> bool {
        self.total_health.is_zero()
    }
}

fn is_wall_damaged(wall_health: U256, config: &BattleConfig) -> bool {
    wall_health < config.wall_health / U256::from(2)
}

fn phase_one(attacking_catapults: U256, config: &BattleConfig) -> U256 {
    let mut attacking_group = CatapultGroup::new(attacking_catapults, config.catapult_health, config.catapult_attack);
    let mut defending_group = CatapultGroup::new(config.defending_catapults, config.catapult_health, config.catapult_attack);

    let mut wall_health = config.wall_health;

    while !is_wall_damaged(wall_health, config) && !attacking_group.is_destroyed() {
        // Defending catapults attack
        let defending_damage = defending_group.calculate_damage();
        attacking_group.take_damage(defending_damage);

        // Attacking catapults attack
        if attacking_group.attack_counter < U256::from(2) {
            let attacking_damage = attacking_group.calculate_damage();
            defending_group.take_damage(attacking_damage);
        } else {
            let wall_damage = attacking_group.calculate_damage();
            if wall_damage > wall_health {
                wall_health = U256::from(0);
            } else {
                wall_health -= wall_damage;
            }
        }

        attacking_group.attack_counter = (attacking_group.attack_counter + U256::from(1)) % U256::from(10);

        if is_wall_damaged(wall_health, config) {
            break;
        }

        if attacking_group.is_destroyed() {
            break;
        }
    }

    if attacking_group.is_destroyed() {
        U256::from(2) // Defenders win
    } else if is_wall_damaged(wall_health, config) {
        U256::from(1) // Attackers win
    } else {
        U256::from(0) // Draw
    }
}

fn main() {
    // Initialize the configuration
    let config = BattleConfig::new();

    // Read input data from stdin (number of attacking catapults)
    let mut input_bytes = Vec::<u8>::new();
    env::stdin().read_to_end(&mut input_bytes).unwrap();
    
    // Decode the input data (number of attacking catapults)
    let attacking_catapults = U256::abi_decode(&input_bytes, true).unwrap();

    // Run the battle simulation and get the result
    let result = phase_one(attacking_catapults, &config);

    // Commit the result to the journal
    env::commit_slice(result.abi_encode().as_slice());
}
