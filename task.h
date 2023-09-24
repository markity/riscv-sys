#include "types.h"
#include "list.h"

// Saved registers for kernel context switches.
struct context {
  uint64 ra;
  uint64 sp;

  // callee-saved
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

struct task {
    // 栈的开始位置
    void *task_stack_start;
    struct context task_context;
    struct list_node node;
};

struct _cpu {
    int noff;
    int intena;
    struct context scheduler_context;
    struct task *cur_running_task;
};

extern struct list tasks;
extern struct task init_task;
extern struct task main_task;
extern struct _cpu mycpu;