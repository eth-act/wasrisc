package main

import (
	"fmt"
	"runtime/debug"
)

//go:wasmimport testmodule shutdown
//go:noescape
func shutdown()

func main() {
	// Limit memory in use. Otherwise when a lot memory is used
	// eventually the Go runtime will allocate too chunks at
	// once. The smaller limit will pursue mallocgc to allocate
	// memory granular, allowing to use the available memory
	// more effectively.
	debug.SetMemoryLimit(400 * (1 << 20))

	fmt.Println("Hello world from golang")

	// During exit a fatal runtime error occurs in WAMR when
	// compiled with --bounds-check=0. An early shutdown provides
	// a reliable workaround.
	shutdown()

	panic("foo")

}
