package main

func main() {
	// During exit a fatal runtime error occurs in WAMR when
	// compiled with --bounds-check=0. An early shutdown provides
	// a reliable workaround.
	shutdown()
}
