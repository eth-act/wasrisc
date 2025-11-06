.PHONY: all build compile compile-rv64 run

all: build compile run

build:
	make -C example example.c

compile-amd64: build
	make -C amd64 example.amd64.bin

compile-rv64: build
	make -C zkvm example.zkvm.bin

compile: compile-rv64

run: compile
	make -C zkvm debug_zkvm

clean:
	make -C example clean
	make -C amd64 clean
	make -C zkvm clean
