        #
        # machine-mode timer interrupt.
        #
# 很简单, 其实就是将timer中断通过软中断委托给了s mode
# 方法就是设置sip(sofrware interrupts)
# 如果是在s mode下触发, 那么mret直接返回原处

.globl timervec

.align 4
timervec:
        csrrw a0, mscratch, a0
        sd ra, 0(a0)
        sd sp, 8(a0)
        sd gp, 16(a0)
        sd tp, 24(a0)
        sd t0, 32(a0)
        sd t1, 40(a0)
        sd t2, 48(a0)
        sd s0, 56(a0)
        sd s1, 64(a0)
        # sd a0, 72(a0)
        sd a1, 80(a0)
        sd a2, 88(a0)
        sd a3, 96(a0)
        sd a4, 104(a0)
        sd a5, 112(a0)
        sd a6, 120(a0)
        sd a7, 128(a0)
        sd s2, 136(a0)
        sd s3, 144(a0)
        sd s4, 152(a0)
        sd s5, 160(a0)
        sd s6, 168(a0)
        sd s7, 176(a0)
        sd s8, 184(a0)
        sd s9, 192(a0)
        sd s10, 200(a0)
        sd s11, 208(a0)
        sd t3, 216(a0)
        sd t4, 224(a0)
        sd t5, 232(a0)
        sd t6, 240(a0)
        # 最后保存a0到对应的位置, 这其实是registers的存储位置, 也就是之前从msractch里面取出来的值
        sd a0, 72(a0)


        call retrigger_timer

        # 先取regsiters的存储位置, 恢复其他寄存器
        ld a0, 72(a0)
        ld ra, 0(a0)
        ld sp, 8(a0)
        ld gp, 16(a0)
        # not this, in case we moved CPUs: ld tp, 24(sp)
        ld t0, 32(a0)
        ld t1, 40(a0)
        ld t2, 48(a0)
        ld s0, 56(a0)
        ld s1, 64(a0)
        # ld a0, 72(sp)
        ld a1, 80(a0)
        ld a2, 88(a0)
        ld a3, 96(a0)
        ld a4, 104(a0)
        ld a5, 112(a0)
        ld a6, 120(a0)
        ld a7, 128(a0)
        ld s2, 136(a0)
        ld s3, 144(a0)
        ld s4, 152(a0)
        ld s5, 160(a0)
        ld s6, 168(a0)
        ld s7, 176(a0)
        ld s8, 184(a0)
        ld s9, 192(a0)
        ld s10, 200(a0)
        ld s11, 208(a0)
        ld t3, 216(a0)
        ld t4, 224(a0)
        ld t5, 232(a0)
        ld t6, 240(a0)
        # 最后恢复a0寄存器
        csrrw a0, mscratch, a0

        mret
