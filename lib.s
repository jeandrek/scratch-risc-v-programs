	uart = 0x10000000
	plic = 0xc000000
	.text
	.globl	_start
_start:
	li	sp,0x1800
	li	t1,1
	li	t2,uart+1
	sb	t1,(t2)
	li	t1,0x400
	li	t2,plic+0x2000
	sw	t1,(t2)
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
	call	writechar
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
	call	writechar
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
	div	a1,t1,t3
	rem	a0,a1,t2
	addi	a0,a0,'0'
	call	writechar
	div	t3,t3,t2
	bgtz	t3,3b
	lw	ra,12(sp)
	addi	sp,sp,16
	ret
	.globl	readchar
readchar:
	lla	t5,charin
	lbu	a0,(t5)
	beqz	a0,1f
	sb	x0,(t5)
	ret
1:
	li	t5,uart+5
	lbu	t6,(t5)
	andi	t6,t6,1
	bnez	t6,2f
	wfi
	j	1b
2:
	li	t5,uart+0
	lbu	a0,(t5)
	ret
	.globl	peekchar
peekchar:
	lla	t4,charin
	lbu	a0,(t4)
	bnez	a0,3f
1:
	li	t5,uart+5
	lbu	t6,(t5)
	andi	t6,t6,1
	bnez	t6,2f
	wfi
	j	1b
2:
	li	t5,uart+0
	lbu	a0,(t5)
	sb	a0,(t4)
3:
	ret
	.globl	writechar
writechar:
	li	t5,uart+0
	sb	a0,(t5)
	ret
charin:
	.space	1
