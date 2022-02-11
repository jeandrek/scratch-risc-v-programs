	plic = 0xc000000
	.text
	.globl	trap
	.extern	timer_proc
trap:
	sw	s0,-92(sp)
	mv	s0,sp
	addi	sp,sp,-128
	sw	x1,-120(s0)
	sw	x3,-112(s0)
	sw	x4,-108(s0)
	sw	x5,-104(s0)
	sw	x6,-100(s0)
	sw	x7,-96(s0)
	sw	x9,-88(s0)
	sw	x10,-84(s0)
	sw	x11,-80(s0)
	sw	x12,-76(s0)
	sw	x13,-72(s0)
	sw	x14,-68(s0)
	sw	x15,-64(s0)
	sw	x16,-60(s0)
	sw	x17,-56(s0)
	sw	x18,-52(s0)
	sw	x19,-48(s0)
	sw	x20,-44(s0)
	sw	x21,-40(s0)
	sw	x22,-36(s0)
	sw	x23,-32(s0)
	sw	x24,-28(s0)
	sw	x25,-24(s0)
	sw	x26,-20(s0)
	sw	x27,-16(s0)
	sw	x28,-12(s0)
	sw	x29,-8(s0)
	sw	x30,-4(s0)
	sw	x31,(s0)
	csrr	t1,mcause
	li	t2,1<<31
	and	t2,t1,t2
	beqz	t2,Lexception
	li	t2,1<<31 | 11
	beq	t1,t2,Lexternal_interrupt
	li	t2,1<<31 | 7
	beq	t1,t2,Ltimer_interrupt
Lexternal_interrupt:
	li	t2,plic + 0x200004
	lw	t1,(t2)
	sw	t1,(t2)
	j	return_from_trap
Ltimer_interrupt:
	lla	t0,timer_proc
	lw	t0,(t0)
	jalr	(t0)
	j	return_from_trap
Lexception:
	lla	a0,str_exception
	call	writestr
	lla	a0,str_exception_tab
	csrr	t1,mcause
	sll	t1,t1,2
	add	a0,a0,t1
	lw	a0,(a0)
	call	writestr
	csrr	a0,mtval
	call	writenum
1:
	wfi
	j	1b

return_from_trap:
	lw	x1,-120(s0)
	lw	x3,-112(s0)
	lw	x4,-108(s0)
	lw	x5,-104(s0)
	lw	x6,-100(s0)
	lw	x7,-96(s0)
	lw	x9,-88(s0)
	lw	x10,-84(s0)
	lw	x11,-80(s0)
	lw	x12,-76(s0)
	lw	x13,-72(s0)
	lw	x14,-68(s0)
	lw	x15,-64(s0)
	lw	x16,-60(s0)
	lw	x17,-56(s0)
	lw	x18,-52(s0)
	lw	x19,-48(s0)
	lw	x20,-44(s0)
	lw	x21,-40(s0)
	lw	x22,-36(s0)
	lw	x23,-32(s0)
	lw	x24,-28(s0)
	lw	x25,-24(s0)
	lw	x26,-20(s0)
	lw	x27,-16(s0)
	lw	x28,-12(s0)
	lw	x29,-8(s0)
	lw	x30,-4(s0)
	lw	x31,(s0)
	lw	s0,-92(s0)
	addi	sp,sp,128
	mret

	.section .rodata
str_exception:
	.string	"Exception: "
str_exception_tab:
	.word	0
	.word	str_ex_1
	.word	str_ex_2
	.word	str_ex_3
	.word	0
	.word	str_ex_5
	.word	0
	.word	str_ex_7
str_ex_1:	.string	"instruction access fault: "
str_ex_2:	.string	"illegal instruction: "
str_ex_3:	.string	"breakpoint: "
str_ex_5:	.string	"load access fault: "
str_ex_7:	.string	"store access fault: "
