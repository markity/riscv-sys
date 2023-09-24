TOOL_PREFIX = riscv64-linux-gnu-

BASE_ADDRESS = 0x80000000

CC = ${TOOL_PREFIX}gcc
OBJCPOY = ${TOOL_PREFIX}objcopy
OBJDUMP = ${TOOL_PREFIX}objdump
LD = ${TOOL_PREFIX}ld

CFLAGS = -Wall -O -fno-omit-frame-pointer -ggdb
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -I.
CFLAGS += -fno-stack-protector

QEMU_FLAGS = -serial mon:stdio -machine virt -bios none -kernel kernel -smp 1 -m 128M -S -gdb tcp::26000
# QEMU_FLAGS += -device virtio-gpu-device

SRC_LINKER = ./linker.ld
TARGET_NAME = ./kernel

OBJS = \
	entry.o \
	centry.o \
	main.o \
	kernel_vec.o \
	trap.o \
	cmain.o \
	uart.o \
	mem.o \
	task.o \
	swtch.o \

entry.o: entry.s
	${CC} entry.s -O0 -c -o entry.o ${CFLAGS}

centry.o: centry.c
	${CC} centry.c -O0 -c -o centry.o ${CFLAGS}

kernel_vec.o: kernel_vec.s
	${CC} kernel_vec.s -O0 -c -o kernel_vec.o ${CFLAGS}

main.o: main.s
	${CC} main.s -O0 -c -o main.o ${CFLAGS}

trap.o: trap.c
	${CC} trap.c -O0 -c -o trap.o ${CFLAGS}

smain.o: cmain.c
	${CC} cmain.c -O0 -c -o cmain.o ${CFLAGS}

uart.o: uart.c
	${CC} uart.c -O0 -c -o uart.o ${CFLAGS}

mem.o: mem.c
	${CC} mem.c -O0 -c -o mem.o ${CFLAGS}

task.o: task.c
	${CC} task.c -O0 -c -o task.o ${CFLAGS}

swtch.o: swtch.s
	${CC} swtch.s -O0 -c -o swtch.o ${CFLAGS}

build: ${OBJS}
	${LD} ${OBJS} -o ${TARGET_NAME} -T${SRC_LINKER}
	${OBJDUMP} -S ${TARGET_NAME} > kernel.asm

clean:
	rm -f kernel.asm kernel *.o *.d

run: build
	qemu-system-riscv64 ${QEMU_FLAGS}