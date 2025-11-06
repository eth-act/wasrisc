.PHONY: all compile run

all:
	make -C go-wasm-rv64 all

compile:
	make -C go-wasm-rv64 compile

run:
	make -C go-wasm-rv64 run
