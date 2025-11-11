package main

import (
	"fmt"
	"runtime/debug"
)

func main() {
	// Limit memory in use. Otherwise when a lot memory is used
	// eventually the Go runtime will allocate too chunks at
	// once. The smaller limit will pursue mallocgc to allocate
	// memory granular, allowing to use the available memory
	// more effectively.
	debug.SetMemoryLimit(400 * (1 << 20))

	fmt.Println("Hello world from golang")
	panic("foo")
}
