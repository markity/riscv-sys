.global main

# 这个文件的目的是, 进入s mode, 把sp放栈顶, 之前可能已经用过部分栈了

.global smain
smain:
    la sp, kernel_stack
    la a0, 4096
    add sp, sp, a0
    j main
