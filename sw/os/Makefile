PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
ARCH = rv32i
ABI = ilp32
CC = $(PREFIX)gcc
CFLAGS = -fPIC --std=gnu99 -Os -MD -Wall -march=$(ARCH) -mabi=$(ABI) \
	-ffreestanding
LDFLAGS = -fPIC
LDSCRIPT = ../common/riscv-os.ld

OBJS = kernel.o kruntime.o uart.o sh.o xfer.o

kernel: kernel.elf kernel.bin

kernel.o:
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o
	$(CC) $(CFLAGS) -c kruntime.c -o kruntime.o
	$(CC) $(CFLAGS) -c uart.c -o uart.o
	$(CC) $(CFLAGS) -c sh.c -o sh.o
	$(CC) $(CFLAGS) -c xfer.c -o xfer.o

kernel.elf: $(OBJS)
	$(CC) $(LDFLAGS) -Wl,-T$(LDSCRIPT),-Map,kernel.map -o kernel.elf $(OBJS)
	$(PREFIX)objdump -S --disassemble kernel.elf > kernel.dasm

kernel.bin:
	$(PREFIX)strip kernel.elf
	$(PREFIX)objcopy -O binary kernel.elf kernel.bin

clean:
	rm -f kernel.elf kernel.bin kernel.asm kernel.dasm kernel.map sh.asm *.o *.d

.PHONY: kernel clean

