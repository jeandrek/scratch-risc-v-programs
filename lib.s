	.text
	.globl	_start
_start:
	li	sp,0x1800
	call	ttyinit
	li	t1,1<<11
	csrs	mie, t1
	lla	t1,trap
	csrw	mtvec,t1
	csrsi	mstatus,8
	call	main
	ebreak

	.globl	writestr
writestr:
	addi	sp,sp,-16
	sw	ra,12(sp)
	mv	t1,a0
1:
	lbu	a0,(t1)
	beqz	a0,2f
	sw	t1,8(sp)
	call	writechar
	lw	t1,8(sp)
	addi	t1,t1,1
	j	1b
2:
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

	.globl	writenum
writenum:
	addi	sp,sp,-16
	sw	ra,12(sp)
	mv	t1,a0
	bgez	t1,1f
	li	a0,'-'
	sw	t1,8(sp)
	call	writechar
	lw	t1,8(sp)
	neg	t1,t1
1:
	li	t2,10
	li	t3,1
2:
	mul	t4,t2,t3
	bgt	t4,t1,3f
	mv	t3,t4
	j	2b
3:
	div	t4,t1,t3
	rem	a0,t4,t2
	addi	a0,a0,'0'
	sw	t1,8(sp)
	sw	t3,4(sp)
	call	writechar
	lw	t3,4(sp)
	lw	t1,8(sp)
	li	t2,10
	div	t3,t3,t2
	bgtz	t3,3b
	lw	ra,12(sp)
	addi	sp,sp,16
	ret
