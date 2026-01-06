use std::sync::Arc;

use anyhow::Result;
use wasmer::{sys::NativeEngineExt, Engine, Instance, Module, Store};
use wasmer_wasix::{runtime::task_manager::tokio::TokioTaskManager, PluggableRuntime, WasiEnv};

fn main() -> Result<()> {
    // Include the precompiled native module (no compilation at runtime!)
    let serialized_bytes = include_bytes!("reva-client-eth.wasmu");

    println!(
        "Loading precompiled module ({} bytes)...",
        serialized_bytes.len()
    );

    // Create a HEADLESS engine - NO COMPILER INCLUDED
    // This is the key to zero JIT overhead
    let engine = Engine::headless();
    let mut store = Store::new(engine);

    // Deserialize the precompiled module - instant, no compilation!
    let module = unsafe {
        Module::deserialize(&store, serialized_bytes)
            .expect("Failed to deserialize precompiled module")
    };

    println!("Module loaded successfully");

    let tokio_runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap();
    let _guard = tokio_runtime.enter();
    let tokio_task_manager = TokioTaskManager::new(tokio_runtime.handle().clone());
    let runtime = Arc::new(PluggableRuntime::new(Arc::new(tokio_task_manager)));

    // Setup WASI environment
    let mut wasi_env = WasiEnv::builder("wasmer-riscv64")
        .args(&std::env::args().collect::<Vec<String>>())
        .runtime(runtime)
        .finalize(&mut store)?;

    // Create imports from WASI
    let import_object = wasi_env.import_object(&mut store, &module)?;

    // Instantiate the module
    let instance = Instance::new(&mut store, &module, &import_object)?;

    // Initialize WASI
    wasi_env.initialize(&mut store, instance.clone())?;

    println!("Starting execution...");

    // Get and call _start function
    let start = instance.exports.get_function("_start")?;

    match start.call(&mut store, &[]) {
        Ok(_) => {
            println!("Program completed successfully");
        }
        Err(e) => {
            // Handle WASI exit gracefully
            if let Some(wasmer_wasix::WasiError::Exit(code)) = e.downcast_ref() {
                std::process::exit(code.raw());
            }
            // Real error
            return Err(e.into());
        }
    }

    Ok(())
}
