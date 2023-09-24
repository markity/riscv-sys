#include "riscv.h"
#include "list.h"
#include "task.h"

// smode 入口

/* TODO: 如果此处无限循环后sip = 2, 此时timer, external, software中断都是打开的
然而还没有设置stvec, 那么会发生什么?

什么也不会发生, sip此时为2, 也不会管中断啥事
*/

extern void setup_kernelvec();
extern void uart_init();
extern void uartputc_sync(int c);
extern void setup_init_task();

extern char end[];

int noff = 0;
int intena = 0;

void
push_off(void)
{
    int old = intr_get();

    intr_off();
    if(noff == 0)
        intena = old;
    noff += 1;
}

void
pop_off(void)
{
  noff -= 1;
  if(noff == 0 && intena)
    intr_on();
}

extern void swtch(struct context *store_current_here, struct context *to);

void init_task_entry() {
    intr_on();

    while(1) {}
}

void main() {
    /* TODO: 如果此处无限循环后sip = 2, 此时timer, external, software中断都是打开的
    然而还没有设置stvec, 那么会发生什么?

    什么也不会发生, 此时sie, smode interrupt enable为关闭的, 并不响应中断
    */
    // while(1);

    setup_kernelvec();


    setup_init_task();

main_task.task_context.ra = 1;
    mycpu.cur_running_task = &main_task;

    intr_on();

    while(1) {}


    // // scheduler, 循环调度所有任务
    // // 只有init任务切换到下一个任务的时候, 才可能发生tasks的变动, 因此可以放心拿next来切
    // struct task * task_to_run = list_node_parent(&init_task.node, struct task, node);
    // while(1) {
    //     mycpu.cur_running_task = task_to_run;

    //     intr_on();

    //     swtch(&mycpu.scheduler_context, &task_to_run->task_context);

    //     // 回到这里时, 中断已经关闭了
    //     struct list_node *cur_node = &task_to_run->node;
    //     struct list_node *next_node = list_node_next(cur_node);
    //     task_to_run = list_node_parent(next_node, struct task, node);
    // }
    
}
