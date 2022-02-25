	mtime		= 0x1000000
	mtimecmp	= 0x1000008

	.text
	.globl	_start
_start:
	li	sp,0x3000
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
	sw	s1,8(sp)
	mv	s1,a0
1:
	lbu	a0,(s1)
	beqz	a0,2f
	call	writechar
	addi	s1,s1,1
	j	1b
2:
	lw	s1,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

	.globl	writenum
writenum:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s1,8(sp)
	sw	s2,4(sp)
	mv	s1,a0
	bgez	s1,1f
	li	a0,'-'
	call	writechar
	neg	s1,s1
1:
	li	s2,1
	li	t1,10
	mv	t2,s1
2:
	blt	t2,t1,3f
	mul	s2,t1,s2
	div	t2,t2,t1
	j	2b
3:
	div	t2,s1,s2
	rem	a0,t2,t1
	addi	a0,a0,'0'
	call	writechar
	li	t1,10
	div	s2,s2,t1
	bgtz	s2,3b
	lw	s2,4(sp)
	lw	s1,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

	.globl	enable_timer
enable_timer:
	li	t0,1<<7
	csrs	mie,t0
	ret

	.globl	set_timer
set_timer:
	lui	t0,%hi(timer_proc)
	addi	t0,t0,%lo(timer_proc)
	sw	a1,(t0)
	li	t0,mtime
	lw	t1,(t0)
	add	t1,t1,a0
	li	t0,mtimecmp
	sw	t1,(t0)
	ret

	.bss
	.globl	timer_proc
timer_proc:
	.skip	4
