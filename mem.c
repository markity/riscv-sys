#include "riscv.h"


struct _mem {
    struct mem_node *first_free_node;
} kmem;

struct mem_node {
    struct mem_node *next;
};

// pa 必须被 PGSIZE整除
void kfree(void *pa) {
    if ( ((uint64)pa % PGSIZE) != 0 ) {
        // pending
        while(1);
    }


    struct mem_node *node = (struct mem_node*) pa;
    node->next = kmem.first_free_node;
    kmem.first_free_node = node;
}

// 初始化所有内存空间, 4k为一块
void init_memrange(void* start, void *end) {
    uint64 start_ptr = PGROUNDUP((uint64)start);
    uint64 end_ptr = PGROUNDDOWN((uint64)end);

    // 确保最后一个page空间指向的是NULL
    // 保证区分到边界
    *(uint64 *)end_ptr = 0;


    for (; start_ptr <= end_ptr; start_ptr += PGSIZE) {
        kfree((void*)start_ptr);
    }
}

void* kallocpage() {
    struct mem_node* page_list = kmem.first_free_node;
    if (page_list) {
        kmem.first_free_node = kmem.first_free_node->next;
        return (void*)page_list;
    }
    
    return (void*)0;
}