#include "task.h"

// task的链表
struct list tasks;

struct task init_task;

struct task main_task;

char init_task_stack[4096];

extern void init_task_entry();

struct _cpu mycpu;


// init进程是所有孤儿进程的父进程, 负责回收所有的
//      僵死进程
void setup_init_task() {
    // 将init任务加入到任务列表里
    // list_node_init(&init_task.node);
    // list_init(&tasks);

    init_task.task_stack_start = init_task_entry;
    init_task.task_context.ra = (uint64) init_task_entry;
    init_task.task_context.sp = (uint64) init_task_stack + 4096;
    // list_insert_first(&tasks, &init_task.node);

    // list_insert_first(&tasks, &main_task);
}