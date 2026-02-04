./examples/scripts/go2wasm.sh

./platform/wasm2c-package.sh /home/kev/work/skunkworks-go-wasm/examples/build-wasm/go/empty.wasm build/c-packages/

./platform/zkvm/scripts/c2zkvm.sh /home/kev/work/skunkworks-go-wasm/build/c-packages build/riscv

ziskemu -e /home/kev/work/skunkworks-go-wasm/build/riscv
