TOOL_PREFIX = riscv64-linux-gnu-

BASE_ADDRESS = 0x80000000

CC = ${TOOL_PREFIX}gcc
OBJCPOY = ${TOOL_PREFIX}objcopy
OBJDUMP = ${TOOL_PREFIX}objdump
LD = ${TOOL_PREFIX}ld

CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I.
CFLAGS += -fno-stack-protector

SRC_LINKER = ./linker.ld
TARGET_NAME = ./kernel

OBJS = \
	entry.o \
	centry.o \
	main.o \
	kernel_vec.o \

entry.o: entry.s
	${CC} entry.s -O0 -c -o entry.o ${CFLAGS}

centry.o: centry.c
	${CC} centry.c -O0 -c -o centry.o ${CFLAGS}

kernel_vec.o: kernel_vec.s
	${CC} kernel_vec.s -O0 -c -o kernel_vec.o ${CFLAGS}

main.o: main.c
	${CC} main.c -O0 -c -o main.o ${CFLAGS}

build: entry.o centry.o kernel_vec.o main.o
	${LD} ${OBJS} -o ${TARGET_NAME} -T${SRC_LINKER}
	${OBJDUMP} -S ${TARGET_NAME} > kernel.asm

clean:
	rm -f kernel.asm kernel *.o *.d

run: build
	qemu-system-riscv64 -machine virt -bios none -kernel kernel -smp 1 -m 128M -nographic -S -gdb tcp::26000