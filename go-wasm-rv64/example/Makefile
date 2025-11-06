example.wasm: example.go
	GOOS=wasip1 GOARCH=wasm go build -o example.wasm .

example.c: example.wasm
	/opt/w2c2/w2c2/build/w2c2 example.wasm example.c

clean:
	rm -f example.wasm example.c example.h
