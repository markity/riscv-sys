    .section .text
    .global _entry
_entry:
    la sp, kernel_stack
    la a0, 4096
    add sp, sp, a0
    j centry
