use wasmtime::*;
use wasmtime_wasi::WasiCtx;

fn main() -> anyhow::Result<()> {
    let wasm_bytes = include_bytes!("stateless.cwasm");

    let engine = Engine::default();
    let module = unsafe { Module::deserialize(&engine, wasm_bytes)? };

    // Create linker first
    let mut linker = Linker::new(&engine);
    wasmtime_wasi::p1::add_to_linker_sync(&mut linker, |s| s)?;

    // Create WASI context with build_p1()
    let wasi = WasiCtx::builder().inherit_stdio().inherit_args().build_p1();

    let mut store = Store::new(&engine, wasi);

    // Instantiate the module
    let instance = linker.instantiate(&mut store, &module)?;

    // Call _start
    let start = instance.get_typed_func::<(), ()>(&mut store, "_start")?;
    match start.call(&mut store, ()) {
        Ok(_) => {}
        Err(e) => {
            // Check if this is a WASI exit trap
            if let Some(exit_code) = e.downcast_ref::<wasmtime_wasi::I32Exit>() {
                std::process::exit(exit_code.0);
            }
            // If it's not an exit, it's a real error
            return Err(e);
        }
    }

    Ok(())
}
