	plic = 0xc000000
	.text
	.globl	trap
trap:
	addi	sp,sp,-16
	sw	t1,12(sp)
	sw	t2,8(sp)
	csrr	t1,mcause
	li	t2,1<<31
	and	t2,t1,t2
	beqz	t2,Lexception
	li	t2,1<<31 | 11
	bne	t1,t2,Linternal_interrupt
	li	t2,plic + 0x200004
	lw	t1,(t2)
	sw	t1,(t2)
	lw	t1,12(sp)
	lw	t2,8(sp)
Linternal_interrupt:
	addi	sp,sp,16
	mret
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
2:
	wfi
	j	2b

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
