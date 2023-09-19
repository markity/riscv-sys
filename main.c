#include "riscv.h"

// smode 入口

/* TODO: 如果此处无限循环后sip = 2, 此时timer, external, software中断都是打开的
然而还没有设置stvec, 那么会发生什么?

什么也不会发生, sip此时为2, 也不会管中断啥事
*/
void main() {
    while(1);
}