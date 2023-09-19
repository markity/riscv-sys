#include "riscv.h"

extern void main();
extern void timervec();
extern void setup_timer();

char kernel_stack[4096];

uint64 systick = 0;

// 用于进入timer时临时存储所有寄存器
uint64 timer_scratch[31];

// entry.s -> centry.c

void centry() {
    // 将mpp(machine previous mode)设置称smode, 以便于之后mret返回到smode
    unsigned long x = r_mstatus();
    x &= ~MSTATUS_MPP_MASK;
    x |= MSTATUS_MPP_S;
    w_mstatus(x);

    // 将mepc(machine exception pc)设置成main, main是smode的程序入口, mret将会返回到这个位置
    w_mepc((uint64)main);

    // 关闭smode的虚拟地址, 访问的即为真实地址
    w_satp(0);

    // 理论上riscv架构的所有异常和中断都是mmode处理的, 然后mmode可以通过代码转递给smode
    // 但是这样效率很低, 因此可以通过代理直接绕过mmode, 让smode直接代理某些异常
    // TODO: 这种代码方式如何是实现?
    // 将所有 machine exception 代理给smode
    w_medeleg(0xffff);
    // 将所有 machine interrupt 代理给smode
    w_mideleg(0xffff);
    // 启动中断, external, timer, soft(和linux的软中断不同, 这个指的是软件)
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

    /*
    A supervisor-level software interrupt is triggered on the current
     hart by writing 1 to its supervisor software interrupt-pending (SSIP)
      bit in the sip register. A pending supervisor-level software 
      interrupt can be cleared by writing 0 to the SSIP bit in sip.
       Supervisor-level software interrupts are disabled when the SSIE bit in the sie register is clear.

    A user-level software interrupt is triggered on the current hart by
     writing 1 to its user software interrupt-pending (USIP) bit in the sip register.
      A pending user-level software interrupt can be cleared by writing 0 to the USIP bit in sip.
       User-level software interrupts are disabled when the USIE bit in the sie register is clear.
    */

   // ecall 也是软中断, 异常也是软中断, 包括存取memory不对其, 都会触发软中断
   // TODO: 如果关闭了SSIE, 然后执行了错误的指令, what will happen?

    // configure Physical Memory Protection to give supervisor mode
    // access to all of physical memory.
    // 这个是pmp内存保护机制, mmode可以访问全部的物理内存, 对于umode和smode可以用pmp寄存器保护物理内存
    // pmp相关的有两类寄存器, 8位地址寄存器和配置寄存器
    // 分别触发instruction access-fault exception, load access-fault exception, store access-fault exception。
    // TODO: 不深纠, 跳过了, 以后再来研究
    w_pmpaddr0(0x3fffffffffffffull);
    w_pmpcfg0(0xf);

    // 执行后, 外部timer将会产生中断, 这个中断不会被委托, 直接进入mmode的中断处理
    // 如果在后面的一小段时间内产生中断, 此时是mmode, 在mret之前会给sip置位, 这会产生一个bug
    // 下面有一个耗时的代码片段, 可以自行测试
    // 测试方法, 在timervec和下面的w_tp处打断点, 发现会触发timervec后会回到w_tp处
    // TODO: 修复这个bug, 已经修复, 见retrigger_timer
    setup_timer();


    long p;
    for (long i = 0; i < 1000000000L; i++) {
        p += 1;
    }


    int id = r_mhartid();
    w_tp(id);

    asm volatile ("mret");
}

/* riscv timer运作方式
CLINT_MTIECMP 是对比数值, CLINT_TIMER是递增数值, 随着时间一直加
一旦对比数值==递增数值, 那么触发中断, 我们的内核10分之1秒触发一次中断
timer中断是没法委托给smode的, 所以需要通过软中断设置给smode
触发中断后, 需要重置对比值, 这样之后能够持续触发
*/

void setup_timer() {
    // each CPU has a separate source of timer interrupts.
    int id = r_mhartid();


    // ask the CLINT for a timer interrupt.
    int interval = 1000000; // cycles; about 1/10th second in qemu.
    *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;


    // prepare information in scratch[] for timervec.
    // scratch[0..2] : space for timervec to save registers.
    // scratch[3] : address of CLINT MTIMECMP register.
    // scratch[4] : desired interval (in cycles) between timer interrupts.
    // scratch是供自己使用, 可以用来暂时存储数据
    uint64 *scratch = &timer_scratch[0];
    scratch[3] = CLINT_MTIMECMP(id);
    scratch[4] = interval;
    w_mscratch((uint64)scratch);

    // 设置mmode的中断向量表, 但是mmode只有timer是开着的, 所以只做timer的中断处理

    /*
    Some exceptions cannot occur at less privileged modes, 
    and corresponding x edeleg bits should be hardwired to zero.
     In particular, medeleg[11] and sedeleg[11:9] are all hardwired to zero.
    */
    w_mtvec((uint64)timervec);

    // enable machine-mode interrupts.
    w_mstatus(r_mstatus() | MSTATUS_MIE);

    // enable machine-mode timer interrupts.
    w_mie(r_mie() | MIE_MTIE);
}

void retrigger_timer() {
    int id = r_mhartid();
    int interval = 1000000; // cycles; about 1/10th second in qemu.

    systick ++;

    // 触发smode的软中断
    w_sip(2);
    // 重新设置timer
    *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;

    unsigned long x = r_mstatus();
    if ((x & MSTATUS_MPP_MASK) == MSTATUS_MPP_M) {
        unsigned long x = r_mstatus();
        x &= ~MSTATUS_MPP_MASK;
        x |= MSTATUS_MPP_S;
        w_mstatus(x);

        // 将mepc(machine exception pc)设置成main, main是smode的程序入口, mret将会返回到这个位置
        w_mepc((uint64)main);
    }
}