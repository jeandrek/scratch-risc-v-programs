# A simple Scheme interpreter
# With a SICP-esque Cheney's algorithm garbage collector

#define TAG_PAIR	0
#define TAG_FIXNUM	1
#define TAG_PROCEDURE	2
#define TAG_SYMBOL	3

#define REG_FROMSPACE	s1
#define REG_TOSPACE	s2
#define REG_FREE	s3
#define TOP_OF_STACK	0x2000
#define SPACE_SIZE	0x600

#define SYMBOL_LENGTH	16

#define BROKEN_HEART	4
#define TRUE		7
#define FALSE		3

#define NUM_PRIMITIVES	22

# Every stack frame reachable by GC must have no dead values.
#define ZEROFRAME		\
	sw	zero,8(sp);	\
	sw	zero,4(sp);	\
	sw	zero,(sp)

#define SYM(name)		sym_ ## name
#define NAME_SYM(n1, n2)	.align 4; sym_ ## n1 = . + 3; .string n2
#define MAKE_SYM(name)		.align 4; .string name

	.text
	.globl	main
main:
	li	REG_TOSPACE,TOP_OF_STACK
	addi	REG_FROMSPACE,REG_TOSPACE,SPACE_SIZE
	mv	REG_FREE,sp
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
	lla	a0,str_msg
	call	writestr
	lla	a0,image_env
	lw	a0,(a0)
	bnez	a0,Limaged
	lla	a0,str_fresh
	call	writestr
	call	make_initial_environment
Limaged:
	sw	a0,8(sp)
1:
	li	a0,'>'
	call	writechar
	call	read
	lw	a1,8(sp)
	call	eval
	lla	t0,SYM(ok)
	beq	a0,t0,1b
	call	write
	li	a0,'\n'
	call	writechar
	j	1b

error:
	call	writestr
	li	a0,'\n'
	call	writechar
	li	sp,TOP_OF_STACK - 16
	j	1b


# Initial environment and primitives

	.globl	make_initial_environment
make_initial_environment:
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
	lla	a0,SYM(ok) + SYMBOL_LENGTH
	li	t0,NUM_PRIMITIVES
	li	a1,0
1:
	beqz	t0,2f
	sw	t0,8(sp)
	call	cons
	lw	t0,8(sp)
	mv	a1,a0
	lw	a0,(a1)
	addi	a0,a0,SYMBOL_LENGTH
	addi	t0,t0,-1
	j	1b
2:
	sw	a1,8(sp)
	lla	t0,prim_addrs
	li	t1,NUM_PRIMITIVES
	li	a1,0
1:
	beqz	t1,2f
	lw	a0,(t0)
	ori	a0,a0,TAG_PROCEDURE
	sw	t1,4(sp)
	sw	t0,(sp)
	call	cons
	lw	t0,(sp)
	lw	t1,4(sp)
	mv	a1,a0
	addi	t0,t0,4
	addi	t1,t1,-1
	j	1b
2:
	lw	a0,8(sp)
	call	cons
	li	a1,0
	call	cons
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

#define CHECK_PAIR(x)			\
	beqz	x,1f;			\
	andi	t0,x,3;			\
	beqz	t0,2f;			\
1:					\
	lla	a0,str_type_pair;	\
	tail	error;			\
2:

#define CHECK_FIXNUM(x) 		\
	andi	t0,x,3;			\
	li	t1,TAG_FIXNUM;		\
	beq	t0,t1,1f;		\
	lla	a0,str_type_fixnum;	\
	tail	error;			\
1:

#define DYADIC_ARGS		\
	lw	t0,4(a0);	\
	lw	a1,(t0);	\
	lw	a0,(a0)

prim_eq:
	DYADIC_ARGS
Lcmp:
	bne	a0,a1,1f
	li	a0,TRUE
	ret
1:
	li	a0,FALSE
	ret

prim_numberp:
	lw	a0,(a0)
	andi	a0,a0,3
	li	t0,TAG_FIXNUM
	bne	a0,t0,1f
	li	a0,TRUE
	ret
1:
	li	a0,FALSE
	ret

prim_num_eql:
	DYADIC_ARGS
	CHECK_FIXNUM(a0)
	CHECK_FIXNUM(a1)
	j	Lcmp

prim_lt:
	DYADIC_ARGS
	CHECK_FIXNUM(a0)
	CHECK_FIXNUM(a1)
	slt	a0,a0,a1
	slli	a0,a0,2
	addi	a0,a0,FALSE
	ret

prim_add:
	DYADIC_ARGS
	CHECK_FIXNUM(a0)
	CHECK_FIXNUM(a1)
	xori	a1,a1,TAG_FIXNUM
	add	a0,a0,a1
	ret

prim_sub:
	DYADIC_ARGS
	CHECK_FIXNUM(a0)
	CHECK_FIXNUM(a1)
	xori	a1,a1,TAG_FIXNUM
	sub	a0,a0,a1
	ret

prim_mul:
	DYADIC_ARGS
	CHECK_FIXNUM(a0)
	CHECK_FIXNUM(a1)
	xori	a0,a0,TAG_FIXNUM
	srai	a1,a1,2
	mul	a0,a0,a1
	ori	a0,a0,TAG_FIXNUM
	ret

prim_quotient:
	DYADIC_ARGS
	CHECK_FIXNUM(a0)
	CHECK_FIXNUM(a1)
	srai	a0,a0,2
	srai	a1,a1,2
	div	a0,a0,a1
	slli	a0,a0,2
	ori	a0,a0,TAG_FIXNUM
	ret

prim_remainder:
	DYADIC_ARGS
	CHECK_FIXNUM(a0)
	CHECK_FIXNUM(a1)
	srai	a0,a0,2
	srai	a1,a1,2
	rem	a0,a0,a1
	slli	a0,a0,2
	ori	a0,a0,TAG_FIXNUM
	ret

prim_pairp:
	lw	a0,(a0)
	andi	t0,a0,3
	bnez	t0,1f
	beqz	a0,1f
	li	a0,TRUE
	ret
1:
	li	a0,FALSE
	ret

prim_cons:
	lw	t0,4(a0)
	lw	t0,(t0)
	sw	t0,4(a0)
	ret

prim_car:
	lw	a0,(a0)
	CHECK_PAIR(a0)
	lw	a0,(a0)
	ret

prim_cdr:
	lw	a0,(a0)
	CHECK_PAIR(a0)
	lw	a0,4(a0)
	ret

prim_set_car:
	DYADIC_ARGS
	CHECK_PAIR(a0)
	sw	a1,(a0)
	lla	a0,SYM(ok)
	ret

prim_set_cdr:
	DYADIC_ARGS
	CHECK_PAIR(a0)
	sw	a1,4(a0)
	lla	a0,SYM(ok)
	ret

prim_list:
	ret

prim_symbolp:
	lw	a0,(a0)
	andi	t0,a0,3
	li	t1,TAG_SYMBOL
	bne	t0,t1,1f
	li	t0,TRUE
	beq	a0,t0,1f
	li	t0,FALSE
	beq	a0,t0,1f
	li	a0,TRUE
	ret
1:
	li	a0,FALSE
	ret

prim_procedurep:
	lw	a0,(a0)
	andi	t0,a0,3
	li	t1,TAG_PROCEDURE
	bne	t0,t1,1f
	li	a0,TRUE
	ret
1:
	li	a0,FALSE
	ret

prim_read = read

prim_write:
	lw	a0,(a0)
	addi	sp,sp,-16
	sw	ra,12(sp)
	call	write
	lla	a0,SYM(ok)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

prim_newline:
	addi	sp,sp,-16
	sw	ra,12(sp)
	li	a0,'\n'
	call	writechar
	lla	a0,SYM(ok)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

prim_image:
	addi	sp,sp,-16
	sw	ra,12(sp)
	li	t0,TOP_OF_STACK - 16
	lw	t0,8(t0)
	lla	t1,image_env
	sw	t0,(t1)
	li	a0,0
	li	a1,0x2c00
	call	image
	lla	a0,SYM(ok)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret


# Evaluator

	.globl	eval
eval:
	andi	t0,a0,3
	bnez	t0,1f
	beqz	a0,2f
	j	Leval_pair
1:
	li	t1,TAG_FIXNUM
	beq	t0,t1,Leval_self_evaluating
	li	t1,TAG_SYMBOL
	bne	t0,t1,2f
	li	t0,TRUE
	beq	a0,t0,Leval_self_evaluating
	li	t0,FALSE
	beq	a0,t0,Leval_self_evaluating
	j	Leval_variable
2:
	lla	a0,str_bad_exp
	tail	error

Leval_self_evaluating:
	ret

Leval_variable:
	tail	lookup

Leval_pair:
	lw	t0,(a0)
	lla	t1,SYM(quote)
	beq	t0,t1,Leval_quote
	lla	t1,SYM(lambda)
	beq	t0,t1,Leval_lambda
	lla	t1,SYM(if)
	beq	t0,t1,Leval_if
	lla	t1,SYM(set)
	beq	t0,t1,Leval_set
	lla	t1,SYM(begin)
	beq	t0,t1,Leval_begin
	lla	t1,SYM(cond)
	beq	t0,t1,Leval_cond
	lla	t1,SYM(let)
	beq	t0,t1,Leval_let
	lla	t1,SYM(define)
	beq	t0,t1,Leval_define
	addi	sp,sp,-16
	sw	zero,(sp)
	sw	ra,12(sp)
	lw	a0,4(a0)
	sw	a1,8(sp)
	sw	t0,4(sp)
	call	eval_arguments
	sw	a0,(sp)
	lw	a0,4(sp)
	lw	a1,8(sp)
	call	eval
	lw	a1,(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	apply

Leval_quote:
	lw	a0,4(a0)
	lw	a0,(a0)
	ret

Leval_lambda:
	lw	t0,4(a0)
	lw	a0,(t0)
	mv	a2,a1
	lw	a1,4(t0)
	tail	make_procedure

Leval_if:
	addi	sp,sp,-16
	sw	ra,12(sp)
	ZEROFRAME
	lw	t0,4(a0)
	lw	a0,(t0)
	lw	t0,4(t0)
	sw	t0,8(sp)
	sw	a1,4(sp)
	call	eval
	lw	a1,4(sp)
	lw	t0,8(sp)
	li	t1,FALSE
	beq	a0,t1,Leval_alt
	j	Leval_conseq
Leval_alt:
	lw	t0,4(t0)
	bnez	t0,Leval_conseq
	lla	a0,SYM(ok)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret
Leval_conseq:
	lw	a0,(t0)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	eval

Leval_set:
	addi	sp,sp,-16
	sw	zero,(sp)
	sw	ra,12(sp)
	lw	a0,4(a0)
	lw	t0,(a0)
	lw	a0,4(a0)
	lw	a0,(a0)
	sw	t0,8(sp)
	sw	a1,4(sp)
	call	eval
	mv	a1,a0
	lw	a0,8(sp)
	lw	a2,4(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	set_variable

Leval_begin:
	lw	a0,4(a0)
	tail	eval_sequence

Leval_cond:
	addi	sp,sp,-16
	sw	ra,12(sp)
	lw	t0,4(a0)
1:
	bnez	t0,2f
	lla	a0,SYM(ok)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret
2:
	lw	t1,(t0)
	lw	a0,(t1)
	sw	t0,8(sp)
	sw	t1,4(sp)
	sw	a1,(sp)
	call	eval
	lw	a1,(sp)
	li	t0,FALSE
	beq	a0,t0,3f
	lw	a0,4(sp)
	lw	a0,4(a0)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	eval_sequence
3:
	lw	t0,8(sp)
	lw	t0,4(t0)
	j	1b

Leval_let:
	# 24(sp) = let body
	# 20(sp) = let bindings
	# 16(sp) = variables
	# 12(sp) = values
	# 8(sp) = expression
	# 4(sp) = environment
	addi	sp,sp,-32
	sw	zero,(sp)
	sw	ra,28(sp)
	lw	t0,4(a0)
	lw	t1,4(t0)
	sw	t1,24(sp)
	sw	a1,4(sp)
	lw	t0,(t0)
	li	a1,0
	sw	zero,12(sp)
1:
	beqz	t0,2f
	lw	t1,(t0)
	lw	a0,(t1)
	lw	t1,4(t1)
	lw	t1,(t1)
	sw	t1,8(sp)
	lw	t0,4(t0)
	sw	t0,20(sp)
	call	cons
	sw	a0,16(sp)
	lw	a0,8(sp)
	lw	a1,4(sp)
	call	eval
	lw	a1,12(sp)
	call	cons
	sw	a0,12(sp)
	lw	a1,16(sp)
	lw	t0,20(sp)
	j	1b
2:
	mv	a0,a1
	lw	a1,12(sp)
	sw	ra,12(sp)
	call	cons
	lw	a1,4(sp)
	call	cons
	mv	a1,a0
	lw	a0,24(sp)
	lw	ra,28(sp)
	addi	sp,sp,32
	tail	eval_sequence

Leval_define:
	addi	sp,sp,-16
	sw	ra,12(sp)
	ZEROFRAME
	sw	a1,8(sp)
	lw	t0,4(a0)
	lw	t1,(t0)
	andi	t2,t1,3
	bnez	t2,1f
	lw	t2,(t1)
	lw	a0,4(t1)
	lw	a1,4(t0)
	sw	t2,4(sp)
	call	cons
	mv	a1,a0
	lla	a0,SYM(lambda)
	call	cons
	j	2f
1:
	lw	t0,4(t0)
	lw	a0,(t0)
	sw	t1,4(sp)
2:
	lw	a1,8(sp)
	call	eval
	mv	a1,a0
	lw	a0,4(sp)
	lw	a2,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	define_variable

eval_arguments:
	addi	sp,sp,-16
	sw	ra,12(sp)
	mv	t0,a0
	li	t1,0
1:
	beqz	t0,2f
	sw	t0,8(sp)
	sw	t1,4(sp)
	sw	a1,(sp)
	lw	a0,(t0)
	call	eval
	lw	a1,4(sp)
	call	cons
	mv	t1,a0
	lw	t0,8(sp)
	lw	t0,4(t0)
	lw	a1,(sp)
	j	1b
2:
	mv	a0,t1
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	nreverse

eval_sequence:
	mv	t0,a0
	lw	a0,(t0)
	lw	t0,4(t0)
	beqz	t0,eval
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	zero,(sp)
	j	2f
1:
	lw	a0,(t0)
	lw	t0,4(t0)
	beqz	t0,3f
2:
	sw	t0,8(sp)
	sw	a1,4(sp)
	call	eval
	lw	a1,4(sp)
	lw	t0,8(sp)
	j	1b
3:
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	eval


# Procedures and environments

	.globl	make_procedure
make_procedure:
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
	sw	a2,8(sp)
	call	cons
	mv	a1,a0
	lw	a0,8(sp)
	call	cons
	ori	a0,a0,TAG_PROCEDURE
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

	.globl	apply
apply:
	andi	t0,a0,3
	li	t1,TAG_PROCEDURE
	bne	t0,t1,Lnot_proc
	xori	t0,a0,TAG_PROCEDURE
	li	t1,TOP_OF_STACK
	blt	t0,t1,Lapply_primitive
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
	sw	t0,8(sp)
	lw	t0,4(t0)
	lw	a0,(t0)
	call	cons
	lw	t0,8(sp)
	lw	a1,(t0)
	call	cons
	mv	a1,a0
	lw	t0,8(sp)
	lw	t0,4(t0)
	lw	a0,4(t0)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	eval_sequence
Lapply_primitive:
	mv	a0,a1
	jr	(t0)
Lnot_proc:
	lla	a0,str_not_proc
	tail	error

	.globl	lookup
lookup:
	beqz	a1,Lunbound
	lw	t1,(a1)
	lw	t2,(t1)
	lw	t3,4(t1)
1:
	beqz	t2,3f
	lw	t4,(t2)
	beq	t4,a0,2f
	lw	t2,4(t2)
	lw	t3,4(t3)
	j	1b
2:
	lw	a0,(t3)
	ret
3:
	lw	a1,4(a1)
	j	lookup

	.globl	set_variable
set_variable:
	beqz	a2,Lunbound
	lw	t1,(a2)
	lw	t2,(t1)
	lw	t3,4(t1)
1:
	beqz	t2,3f
	lw	t4,(t2)
	beq	t4,a0,2f
	lw	t2,4(t2)
	lw	t3,4(t3)
	j	1b
2:
	sw	a1,(t3)
	lla	a0,SYM(ok)
	ret
3:
	lw	a2,4(a2)
	j	set_variable

Lunbound:
	lla	a0,str_unbound
	tail	error

	.globl	define_variable
define_variable:
	lw	t0,(a2)
	lw	t1,(t0)
	lw	t2,4(t0)
1:
	beqz	t1,3f
	lw	t3,(t1)
	beq	t3,a0,2f
	lw	t1,4(t1)
	lw	t2,4(t2)
	j	1b
2:
	sw	a1,(t2)
	j	4f
3:
	addi	sp,sp,-16
	sw	zero,(sp)
	sw	ra,12(sp)
	lw	t0,(a2)
	sw	a1,8(sp)
	lw	a1,(t0)
	sw	t0,4(sp)
	call	cons
	lw	t0,4(sp)
	sw	a0,(t0)
	lw	a0,8(sp)
	lw	a1,4(t0)
	call	cons
	lw	t0,4(sp)
	sw	a0,4(t0)
	lw	ra,12(sp)
	addi	sp,sp,16
4:
	lla	a0,SYM(ok)
	ret


# Reader and symbols

	.globl	read
read:
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
Lwhitespace:
	call	readchar
	li	t1,' '
	beq	a0,t1,Lwhitespace
	li	t1,'\n'
	beq	a0,t1,Lwhitespace
	li	t1,'0'
	blt	a0,t1,1f
	li	t1,'9'
	li	t2,0
	ble	a0,t1,Lread_num
1:
	li	t1,'+'
	bne	a0,t1,2f
	mv	t0,a0
	call	peekchar
	mv	t1,a0
	mv	a0,t0
	li	t2,'0'
	blt	t1,t2,2f
	li	t2,'9'
	bgt	t1,t2,Lread_symbol
	call	readchar
	li	t2,0
	j	Lread_num
2:
	li	t1,'-'
	bne	a0,t1,3f
	mv	t0,a0
	call	peekchar
	mv	t1,a0
	mv	a0,t0
	li	t2,'0'
	blt	t1,t2,3f
	li	t2,'9'
	bgt	t1,t2,Lread_symbol
	call	readchar
	li	t2,1
	j	Lread_num
3:
	li	t1,'A'
	blt	a0,t1,4f
	li	t1,'Z'
	ble	a0,t1,Lread_symbol
4:
	lla	t1,ext_alph_chars
5:
	lbu	t2,(t1)
	beqz	t2,6f
	beq	a0,t2,Lread_symbol
	addi	t1,t1,1
	j	5b
6:
	li	t1,'('
	beq	a0,t1,Lread_list
	li	t1,'\''
	beq	a0,t1,Lread_quote
	li	t1,'#'
	beq	a0,t1,Lread_hash
Lunexpected_char:
	lla	a0,str_bad_read
	tail	error

Lread_num:
	addi	t0,a0,-'0'
	sw	t0,8(sp)
	sw	t2,4(sp)
1:
	call	peekchar
	li	t1,'0'
	blt	a0,t1,2f
	li	t1,'9'
	bgt	a0,t1,2f
	call	readchar
	lw	t0,8(sp)
	addi	a0,a0,-'0'
	li	t1,10
	mul	t0,t0,t1
	add	t0,t0,a0
	j	1b
2:
	lw	t2,4(sp)
	mv	a0,t0
	beqz	t2,3f
	neg	a0,a0
3:
	slli	a0,a0,2
	ori	a0,a0,TAG_FIXNUM
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

Lread_symbol:
	addi	sp,sp,-16
	sb	a0,(sp)
	addi	t0,sp,1
1:
	sw	t0,24(sp)
	call	peekchar
	li	t1,'A'
	blt	a0,t1,2f
	li	t1,'Z'
	ble	a0,t1,Lconsume
2:
	li	t1,'0'
	blt	a0,t1,3f
	li	t1,'9'
	ble	a0,t1,Lconsume
3:
	lla	t1,ext_alph_chars
4:
	lbu	t2,(t1)
	beqz	t2,5f
	beq	a0,t2,Lconsume
	addi	t1,t1,1
	j	4b
Lconsume:
	call	readchar
	lw	t0,24(sp)
	sb	a0,(t0)
	addi	t0,t0,1
	j	1b
5:
	lw	t0,24(sp)
	sb	zero,(t0)
	mv	a0,sp
	call	intern
	lw	ra,28(sp)
	addi	sp,sp,32
	ret

Lread_list:
	li	t0,0
1:
	sw	t0,8(sp)
	call	peekchar
	li	t1,')'
	beq	a0,t1,2f
	call	read
	lw	a1,8(sp)
	call	cons
	mv	t0,a0
	j	1b
2:
	call	readchar
	lw	a0,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	nreverse

Lread_quote:
	call	read
	li	a1,0
	call	cons
	mv	a1,a0
	lla	a0,SYM(quote)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	cons

Lread_hash:
	call	readchar
	li	t0,'T'
	bne	a0,t0,1f
	li	a0,TRUE
	j	2f
1:
	li	t0,'F'
	bne	a0,t0,Lunexpected_char
	li	a0,FALSE
2:
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

	.globl	intern
intern:
	mv	a1,a0
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
	lla	a0,obarray
1:
	lw	t0,(a0)
	beqz	t0,3f
	sw	a0,8(sp)
	sw	a1,4(sp)
	call	str_eql
	bnez	a0,2f
	lw	a0,8(sp)
	lw	a1,4(sp)
	addi	a0,a0,SYMBOL_LENGTH
	j	1b
2:
	lw	a0,8(sp)
	ori	a0,a0,TAG_SYMBOL
	lw	ra,12(sp)
	addi	sp,sp,16
	ret
3:
	sw	a0,8(sp)
	call	str_cpy
	lw	a0,8(sp)
	ori	a0,a0,TAG_SYMBOL
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

str_eql:
	lbu	t0,(a0)
	lbu	t1,(a1)
	bne	t0,t1,2f
	beqz	t0,1f
	addi	a0,a0,1
	addi	a1,a1,1
	j	str_eql
1:
	li	a0,1
	ret
2:
	li	a0,0
	ret

str_cpy:
	lbu	t0,(a1)
	beqz	t0,1f
	sb	t0,(a0)
	addi	a0,a0,1
	addi	a1,a1,1
	j	str_cpy
1:
	ret


# Printer

	.globl	write
write:
	addi	sp,sp,-16
	sw	ra,12(sp)
	andi	t0,a0,3
	bnez	t0,1f
	beqz	a0,Lwrite_empty_list
	j	Lwrite_pair
1:
	li	t1,TAG_FIXNUM
	beq	t0,t1,Lwrite_fixnum
	li	t1,TAG_PROCEDURE
	beq	t0,t1,Lwrite_procedure
	li	t0,TRUE
	beq	a0,t0,Lwrite_true
	li	t0,FALSE
	beq	a0,t0,Lwrite_false
	j	Lwrite_symbol
Lwrite_empty_list:
	li	a0,'('
	call	writechar
	li	a0,')'
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	writechar
Lwrite_true:
	li	a0,'#'
	call	writechar
	li	a0,'t'
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	writechar
Lwrite_false:
	li	a0,'#'
	call	writechar
	li	a0,'f'
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	writechar
Lwrite_pair:
	lw	t0,(a0)
	sw	a0,8(sp)
	li	a0,'('
	call	writechar
	lw	a0,8(sp)
Lnext_element:
	lw	t0,(a0)
	lw	t1,4(a0)
	mv	a0,t0
	sw	t1,8(sp)
	call	write
	lw	t1,8(sp)
	beqz	t1,Lend_of_list
	li	a0,' '
	call	writechar
	lw	a0,8(sp)
	andi	t0,a0,3
	beqz	t0,Lnext_element
	sw	a0,8(sp)
	li	a0,'.'
	call	writechar
	li	a0,' '
	call	writechar
	lw	a0,8(sp)
	call	write
Lend_of_list:
	li	a0,')'
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	writechar
Lwrite_fixnum:
	srai	a0,a0,2
	addi	sp,sp,16
	tail	writenum
Lwrite_procedure:
	li	t0,TOP_OF_STACK
	blt	a0,t0,Lwrite_primitive
	xori	t0,a0,TAG_PROCEDURE
	sw	t0,8(sp)
	lla	a0,str_proc
	call	writestr
	lw	t0,8(sp)
	lw	t0,4(t0)
	lw	a0,(t0)
	call	write
	li	a0,']'
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	writechar
Lwrite_primitive:
	sw	a0,8(sp)
	lla	a0,str_prim
	addi	sp,sp,16
	tail	writestr
Lwrite_symbol:
	xori	a0,a0,TAG_SYMBOL
	addi	sp,sp,16
	tail	writestr


# Lists

	.globl nreverse
nreverse:
	li	t0,0
1:
	beqz	a0,2f
	lw	t1,4(a0)
	sw	t0,4(a0)
	mv	t0,a0
	mv	a0,t1
	j	1b
2:
	mv	a0,t0
	ret


# Allocation and garbage collector

	.globl	cons
cons:
	mv	t0,REG_TOSPACE
	addi	t0,t0,SPACE_SIZE
	beq	REG_FREE,t0,2f
1:
	mv	t0,REG_FREE
	addi	REG_FREE,REG_FREE,8
	sw	a0,(t0)
	sw	a1,4(t0)
	mv	a0,t0
	ret
2:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	zero,(sp)
	sw	a0,8(sp)
	sw	a1,4(sp)
	call	gc
	lw	a1,4(sp)
	lw	a0,8(sp)
	mv	t0,REG_TOSPACE
	addi	t0,t0,SPACE_SIZE
	beq	REG_FREE,t0,Lout_of_mem
	lw	ra,12(sp)
	addi	sp,sp,16
	j	1b
Lout_of_mem:
	lla	a0,str_out_of_mem
	tail	error

gc:
	addi	sp,sp,-16
	sw	ra,12(sp)
	lla	a0,str_gc
	call	writestr
	mv	t0,REG_FROMSPACE
	mv	REG_FROMSPACE,REG_TOSPACE
	mv	REG_TOSPACE,t0
	mv	REG_FREE,t0
	addi	t1,sp,16
	li	t2,TOP_OF_STACK
Ltraverse_stack:
	beq	t1,t2,Lgc_loop
	lw	a0,(t1)
	blt	a0,t2,1f
	call	relocate
	sw	a0,(t1)
1:
	addi	t1,t1,4
	j	Ltraverse_stack
Lgc_loop:
	beq	t0,REG_FREE,1f
	lw	t1,(t0)
	lw	t2,4(t0)
	mv	a0,t1
	call	relocate
	sw	a0,(t0)
	mv	a0,t2
	call	relocate
	sw	a0,4(t0)
	addi	t0,t0,8
	j	Lgc_loop
1:
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

relocate:
	beqz	a0,1f
	andi	t5,a0,3
	beqz	t5,Lrelocate_pair
	li	t6,TAG_PROCEDURE
	beq	t5,t6,Lrelocate_procedure
1:
	ret
Lrelocate_procedure:
	li	t5,TOP_OF_STACK
	blt	a0,t5,1f
	addi	sp,sp,-16
	sw	ra,12(sp)
	xori	a0,a0,TAG_PROCEDURE
	call	relocate
	ori	a0,a0,TAG_PROCEDURE
	lw	ra,12(sp)
	addi	sp,sp,16
1:
	ret
Lrelocate_pair:
	lw	t5,(a0)
	lw	t6,4(a0)
	li	a1,BROKEN_HEART
	beq	t5,a1,Lfound_broken_heart
	sw	t5,(REG_FREE)
	sw	t6,4(REG_FREE)
	mv	t5,REG_FREE
	addi	REG_FREE,REG_FREE,8
	sw	a1,(a0)
	sw	t5,4(a0)
	mv	a0,t5
	ret
Lfound_broken_heart:
	mv	a0,t6
	ret

	#.bss
image_env:
	.skip	4
	#.section	.rodata
ext_alph_chars:	.string	"!$%&*+-./:<=>?@^_~"
str_msg:	.string	"Scheme interpreter\n"
str_fresh:	.string	"(Not been imaged)\n"
str_prim:	.string	"#[primitive]"
str_proc:	.string "#[procedure "
str_gc:		.string	"GC cycle\n"
str_bad_read:	.string	"Unexpected character"
str_bad_exp:	.string	"Unknown expression type"
str_unbound:	.string	"Unbound variable"
str_not_proc:	.string	"Not a procedure"
str_out_of_mem:	.string	"Out of memory"
str_type_pair:	.string	"Expected a pair"
str_type_fixnum:.string	"Expected a fixnum"

prim_addrs:
	.word	prim_eq
	.word	prim_numberp
	.word	prim_num_eql
	.word	prim_lt
	.word	prim_add
	.word	prim_sub
	.word	prim_mul
	.word	prim_quotient
	.word	prim_remainder
	.word	prim_pairp
	.word	prim_cons
	.word	prim_car
	.word	prim_cdr
	.word	prim_set_car
	.word	prim_set_cdr
	.word	prim_list
	.word	prim_symbolp
	.word	prim_procedurep
	.word	prim_read
	.word	prim_write
	.word	prim_newline

	.section	.data
obarray:
	NAME_SYM(quote, "QUOTE")
	NAME_SYM(lambda, "LAMBDA")
	NAME_SYM(if, "IF")
	NAME_SYM(set, "SET!")
	NAME_SYM(begin, "BEGIN")
	NAME_SYM(cond, "COND")
	NAME_SYM(let, "LET")
	NAME_SYM(define, "DEFINE")
	NAME_SYM(ok, "OK")
	MAKE_SYM("EQ?")
	MAKE_SYM("NUMBER?")
	MAKE_SYM("=")
	MAKE_SYM("<")
	MAKE_SYM("+")
	MAKE_SYM("-")
	MAKE_SYM("*")
	MAKE_SYM("QUOTIENT")
	MAKE_SYM("REMAINDER")
	MAKE_SYM("PAIR?")
	MAKE_SYM("CONS")
	MAKE_SYM("CAR")
	MAKE_SYM("CDR")
	MAKE_SYM("SET-CAR!")
	MAKE_SYM("SET-CDR!")
	MAKE_SYM("LIST")
	MAKE_SYM("SYMBOL?")
	MAKE_SYM("PROCEDURE?")
	MAKE_SYM("READ")
	MAKE_SYM("WRITE")
	MAKE_SYM("NEWLINE")
	MAKE_SYM("IMAGE")
	.skip	544
