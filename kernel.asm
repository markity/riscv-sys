
./kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    .section .text
    .global _entry
_entry:
    la sp, kernel_stack
    80000000:	00000117          	auipc	sp,0x0
    80000004:	13013103          	ld	sp,304(sp) # 80000130 <_GLOBAL_OFFSET_TABLE_+0x10>
    la a0, 4096
    80000008:	6505                	lui	a0,0x1
    add sp, sp, a0
    8000000a:	912a                	add	sp,sp,a0
    j centry
    8000000c:	0660006f          	j	80000072 <centry>

0000000080000010 <setup_timer>:
一旦对比数值==递增数值, 那么触发中断, 我们的内核10分之1秒触发一次中断
timer中断是没法委托给smode的, 所以需要通过软中断设置给smode
触发中断后, 需要重置对比值, 这样之后能够持续触发
*/

void setup_timer() {
    80000010:	1141                	addi	sp,sp,-16
    80000012:	e422                	sd	s0,8(sp)
    80000014:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000016:	f14027f3          	csrr	a5,mhartid
    int id = r_mhartid();


    // ask the CLINT for a timer interrupt.
    int interval = 1000000; // cycles; about 1/10th second in qemu.
    *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000001a:	0037979b          	slliw	a5,a5,0x3
    8000001e:	02004737          	lui	a4,0x2004
    80000022:	97ba                	add	a5,a5,a4
    80000024:	0200c737          	lui	a4,0x200c
    80000028:	ff873683          	ld	a3,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000002c:	000f4737          	lui	a4,0xf4
    80000030:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000034:	96ba                	add	a3,a3,a4
    80000036:	e394                	sd	a3,0(a5)
    // scratch[0..2] : space for timervec to save registers.
    // scratch[3] : address of CLINT MTIMECMP register.
    // scratch[4] : desired interval (in cycles) between timer interrupts.
    // scratch是供自己使用, 可以用来暂时存储数据
    uint64 *scratch = &timer_scratch[0];
    scratch[3] = CLINT_MTIMECMP(id);
    80000038:	00000697          	auipc	a3,0x0
    8000003c:	11868693          	addi	a3,a3,280 # 80000150 <timer_scratch>
    80000040:	ee9c                	sd	a5,24(a3)
    scratch[4] = interval;
    80000042:	f298                	sd	a4,32(a3)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000044:	34069073          	csrw	mscratch,a3
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000048:	00000797          	auipc	a5,0x0
    8000004c:	0f07b783          	ld	a5,240(a5) # 80000138 <_GLOBAL_OFFSET_TABLE_+0x18>
    80000050:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000054:	300027f3          	csrr	a5,mstatus
     In particular, medeleg[11] and sedeleg[11:9] are all hardwired to zero.
    */
    w_mtvec((uint64)timervec);

    // enable machine-mode interrupts.
    w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000058:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000005c:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000060:	304027f3          	csrr	a5,mie

    // enable machine-mode timer interrupts.
    w_mie(r_mie() | MIE_MTIE);
    80000064:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000068:	30479073          	csrw	mie,a5
}
    8000006c:	6422                	ld	s0,8(sp)
    8000006e:	0141                	addi	sp,sp,16
    80000070:	8082                	ret

0000000080000072 <centry>:
void centry() {
    80000072:	1141                	addi	sp,sp,-16
    80000074:	e406                	sd	ra,8(sp)
    80000076:	e022                	sd	s0,0(sp)
    80000078:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000007a:	300027f3          	csrr	a5,mstatus
    x &= ~MSTATUS_MPP_MASK;
    8000007e:	7779                	lui	a4,0xffffe
    80000080:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <kernel_stack+0xffffffff7fffe687>
    80000084:	8ff9                	and	a5,a5,a4
    x |= MSTATUS_MPP_S;
    80000086:	6705                	lui	a4,0x1
    80000088:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000008c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000008e:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000092:	00000797          	auipc	a5,0x0
    80000096:	0967b783          	ld	a5,150(a5) # 80000128 <_GLOBAL_OFFSET_TABLE_+0x8>
    8000009a:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000009e:	4781                	li	a5,0
    800000a0:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000a4:	67c1                	lui	a5,0x10
    800000a6:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000a8:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000ac:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000b0:	104027f3          	csrr	a5,sie
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000b4:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000b8:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000bc:	57fd                	li	a5,-1
    800000be:	83a9                	srli	a5,a5,0xa
    800000c0:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000c4:	47bd                	li	a5,15
    800000c6:	3a079073          	csrw	pmpcfg0,a5
    setup_timer();
    800000ca:	00000097          	auipc	ra,0x0
    800000ce:	f46080e7          	jalr	-186(ra) # 80000010 <setup_timer>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d2:	f14027f3          	csrr	a5,mhartid
    w_tp(id);
    800000d6:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000d8:	823e                	mv	tp,a5
    asm volatile ("mret");
    800000da:	30200073          	mret
}
    800000de:	60a2                	ld	ra,8(sp)
    800000e0:	6402                	ld	s0,0(sp)
    800000e2:	0141                	addi	sp,sp,16
    800000e4:	8082                	ret

00000000800000e6 <main>:
#include "riscv.h"

// smode 入口
void main() {
    800000e6:	1141                	addi	sp,sp,-16
    800000e8:	e422                	sd	s0,8(sp)
    800000ea:	0800                	addi	s0,sp,16
    while(1);
    800000ec:	a001                	j	800000ec <main+0x6>
	...

00000000800000f0 <timervec>:

.globl timervec

.align 4
timervec:
        csrrw a0, mscratch, a0
    800000f0:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    800000f4:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    800000f6:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    800000f8:	e914                	sd	a3,16(a0)

        # schedule the next timer interrupt
        # by adding interval to mtimecmp.
        ld a1, 24(a0) # CLINT_MTIMECMP(hart)
    800000fa:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval
    800000fc:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)
    800000fe:	6194                	ld	a3,0(a1)
        add a3, a3, a2
    80000100:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)
    80000102:	e194                	sd	a3,0(a1)

        # raise a supervisor software interrupt.
	li a1, 2
    80000104:	4589                	li	a1,2
        csrw sip, a1
    80000106:	14459073          	csrw	sip,a1

        ld a3, 16(a0)
    8000010a:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    8000010c:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    8000010e:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80000110:	34051573          	csrrw	a0,mscratch,a0

        mret
    80000114:	30200073          	mret
    80000118:	00000013          	nop
    8000011c:	00000013          	nop
