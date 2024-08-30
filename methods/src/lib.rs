include!(concat!(env!("OUT_DIR"), "/methods.rs"));

#[cfg(test)]
mod tests {
    use alloy_primitives::U256;
    use alloy_sol_types::SolValue;
    use risc0_zkvm::{default_executor, ExecutorEnv};

    #[test]
    fn attackers_win() {
        let attacking_catapults = U256::from(500); // Attackers should win with a strong force

        let env = ExecutorEnv::builder()
            .write_slice(&attacking_catapults.abi_encode())
            .build()
            .unwrap();

        // Execute the simulation
        let session_info = default_executor().execute(env, super::BATTLE_SIM_ELF).unwrap();

        let result = U256::abi_decode(&session_info.journal.bytes, true).unwrap();
        assert_eq!(result, U256::from(1)); // Expecting attackers to win, result should be 1
    }

    #[test]
    fn defenders_win() {
        let attacking_catapults = U256::from(100); // Defenders should win with a weaker attacking force

        let env = ExecutorEnv::builder()
            .write_slice(&attacking_catapults.abi_encode())
            .build()
            .unwrap();

        // Execute the simulation
        let session_info = default_executor().execute(env, super::BATTLE_SIM_ELF).unwrap();

        let result = U256::abi_decode(&session_info.journal.bytes, true).unwrap();
        assert_eq!(result, U256::from(2)); // Expecting defenders to win, result should be 2
    }
}
