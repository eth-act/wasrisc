use ere_dockerized::{DockerizedzkVM, SerializedProgram, zkVMKind};
use ere_zkvm_interface::{
    CommonError,
    compiler::Compiler,
    zkvm::{Input, ProverResource, zkVM},
};
use std::{fs, path::Path};

use serde::{Deserialize, Serialize};

/// Zisk program that contains ELF of compiled guest.
#[derive(Clone, Serialize, Deserialize)]
pub struct ZiskProgram {
    pub(crate) elf: Vec<u8>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let program_path = Path::new("/home/marcin/projects/lita/EF/wasrisc/stateless.zisk.O0.elf");
    let program = fs::read(&program_path)
        .map_err(|err| CommonError::read_file("program", &program_path, err))?;
    let zisk_program = ZiskProgram { elf: program };

    let bytes = bincode::serde::encode_to_vec(&zisk_program, bincode::config::legacy())?;
    let program = SerializedProgram(bytes);

    // Create zkVM instance (builds Docker images if needed)
    // It spawns a container that runs a gRPC server handling zkVM operations
    let zkvm = DockerizedzkVM::new(zkVMKind::Zisk, program, ProverResource::Cpu)?;

    // Prepare input
    let input = Input::new();

    // Execute
    let (public_values, report) = zkvm.execute(&input)?;
    println!("Public values: {:?}", public_values);
    // assert_eq!(public_values, expected_output);
    println!("Execution cycles: {}", report.total_num_cycles);

    // // Prove
    // let (public_values, proof, report) = zkvm.prove(&input, ProofKind::default())?;
    // assert_eq!(public_values, expected_output);
    // println!("Proving time: {:?}", report.proving_time);

    // // Verify
    // let public_values = zkvm.verify(&proof)?;
    // assert_eq!(public_values, expected_output);
    // println!("Proof verified successfully!");

    Ok(())
}
