package main

import (
	"fmt"
	"runtime/debug"
)

//go:wasmimport testmodule input-data-len
//go:noescape
func inputDataLen() uint32

//go:wasmimport testmodule testfunc
//go:noescape
func testfunc(a, b uint32) uint32

//go:wasmimport testmodule testfunc2
//go:noescape
func testfunc2(a, b uint32) uint32

func main() {
	// Limit memory in use. Otherwise when a lot memory is used
	// eventually the Go runtime will allocate too chunks at
	// once. The smaller limit will pursue mallocgc to allocate
	// memory granular, allowing to use the available memory
	// more effectively.
	debug.SetMemoryLimit(400 * (1 << 20))

	fmt.Println("Hello world from golang")
	n := inputDataLen()
	fmt.Printf("Output from inputDataLen %d\n", n)
	x := testfunc(1, 2)
	fmt.Printf("Output from testFunc %d\n", x)
	y := testfunc2(1, 2)
	fmt.Printf("Output from testFunc2 %d\n", y)
}
