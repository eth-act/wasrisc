package main

import "runtime/debug"

func main() {
	// Disable garbage collector
	debug.SetGCPercent(-1)
}
