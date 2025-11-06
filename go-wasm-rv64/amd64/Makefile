CC=gcc
CFLAGS=-g -D AMD64 -I../example -I/opt/w2c2/w2c2 -I. -I/opt/w2c2/wasi

wasi.o: ../wasi/wasi.c
	$(CC) $(CFLAGS) -c -o wasi.o ../wasi/wasi.c

example.amd64.bin: *.c ../example/example.c ../example/example.h wasi.o
	$(CC) $(CFLAGS) -c -o main.o main.c
	$(CC) $(CFLAGS) -c -o custom_imports.o custom_imports.c
	$(CC) $(CFLAGS) -c -o example.o ../example/example.c
	$(CC) -g -o example.amd64.bin main.o custom_imports.o example.o wasi.o -lm

clean:
	rm -f example.wasm example.amd64.bin *.o
