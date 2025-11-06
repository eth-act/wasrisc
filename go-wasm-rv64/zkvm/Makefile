PREFIX = /opt/riscv-newlib/bin/riscv64-unknown-elf-
W2C2_ROOT=/opt/w2c2/w2c2

CC = $(PREFIX)gcc
AS = $(PREFIX)as
LD = $(PREFIX)ld

# flags:
#  -Wall: there are a lot of unused labels in example.c
# -O2: example.c otherwise takes extremely long to compile
CFLAGS = -march=rv64ima -mabi=lp64 -mcmodel=medany -specs=nosys.specs -I./include -I. -I../example -I../wasi -I$(W2C2_ROOT) -D__bool_true_false_are_defined
LDFLAGS_ZKVM = -T riscv64ima_zisk_zkvm_elf_linker_script.ld -nostartfiles -lm

SRCS_ZKVM = main.c syscalls.c example.c addon.c mathfuncs.c custom_imports.c
OBJS_ZKVM = main.o startup.o syscalls.o example.o addon.o mathfuncs.o wasi.o custom_imports.o

example.zkvm.bin: $(OBJS_ZKVM) riscv64ima_zisk_zkvm_elf_linker_script.ld
	$(CC) $(CFLAGS) $(LDFLAGS_ZKVM) $(LDFLAGS_EXTRA) -o $@ $(OBJS_ZKVM)

example.o: ../example/example.c ../example/example.h
	$(CC) $(CFLAGS) -c -o example.o ../example/example.c

wasi.o: ../wasi/wasi.c
	$(CC) $(CFLAGS) -c -o wasi.o ../wasi/wasi.c

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) *.o example.zkvm.bin qemu_debug.log

debug_zkvm: example.zkvm.bin
	ziskemu -e ./example.zkvm.bin -i ../go.png --max-steps 40000000000
