#!/bin/bash

/opt/riscv-newlib-medany-gdb/bin/riscv64-unknown-elf-gdb --init-eval-command="target remote localhost:1234" $1

