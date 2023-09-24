#include "riscv.h"
#include "task.h"

extern void kernelvec();
extern swtch(struct context*, struct context*);

uint64 systick = 0;

// 设置smode的中断向量表
void setup_kernelvec() {
    w_stvec((uint64)kernelvec);
}

void kerneltrap() {
    // 清空软中断, 避免持续触发
    w_sip(0);
    systick++;

    uint64 sepc = r_sepc();
    uint64 sstatus = r_sstatus();
    uint64 scause = r_scause();

    // 进行调度
    if (mycpu.cur_running_task == &main_task) {
        mycpu.cur_running_task = &init_task;
        swtch(&main_task.task_context, &init_task.task_context);
    } else {
        mycpu.cur_running_task = &main_task;
        swtch(&init_task.task_context, &main_task.task_context);
    }

    w_sepc(sepc);
    w_sstatus(sstatus);
    return;
}
