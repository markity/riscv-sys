#include "riscv.h"

extern void kernelvec();

uint64 systick = 0;

// 设置smode的中断向量表
void setup_kernelvec() {
    w_stvec((uint64)kernelvec);
    intr_on();
}

void kerneltrap() {
    // 清空软中断, 避免持续触发
    w_sip(0);
    systick++;
}
