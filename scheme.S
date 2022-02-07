#### A simple Scheme interpreter
#### With a SICP-esque Cheney's algorithm garbage collector

#define TAG_PAIR	0
#define TAG_FIXNUM	1
#define TAG_PROCEDURE	2
#define TAG_SYMBOL	3

#define REG_FROMSPACE	s9
#define REG_TOSPACE	s10
#define REG_FREE	s11
#define TOP_OF_STACK	0x3000
#define SPACE_SIZE	0x1000

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
	li	REG_FROMSPACE,TOP_OF_STACK + SPACE_SIZE
	mv	REG_FREE,sp
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
	lla	a0,str_msg
	call	writestr
	lla	a0,image_env
	lw	a0,(a0)
	beqz	a0,Lnot_imaged
	lla	t0,image_free
	lw	REG_FREE,(t0)
	j	Lready
Lnot_imaged:
	lla	a0,str_fresh
	call	writestr
	call	make_initial_environment
Lready:
	sw	a0,8(sp)	# Saved for reason of error
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
	sw	a1,12(sp)
	call	writestr
	lw	a0,12(sp)
	beqz	a0,2f
	call	write
2:
	li	a0,'\n'
	call	writechar
	li	sp,TOP_OF_STACK - 16
	j	1b


### Initial environment and primitives

	.globl	make_initial_environment
make_initial_environment:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s1,8(sp)
	sw	s2,4(sp)
	sw	s3,(sp)
	lla	s1,SYM(ok) + SYMBOL_LENGTH
	li	s2,NUM_PRIMITIVES
	li	a1,0
1:
	beqz	s2,2f
	mv	a0,s1
	call	cons
	mv	a1,a0
	addi	s1,s1,SYMBOL_LENGTH
	addi	s2,s2,-1
	j	1b
2:
	mv	s3,a1
	lla	s1,prim_addrs
	li	s2,NUM_PRIMITIVES
	li	a1,0
1:
	beqz	s2,2f
	lw	a0,(s1)
	ori	a0,a0,TAG_PROCEDURE
	call	cons
	mv	a1,a0
	addi	s1,s1,4
	addi	s2,s2,-1
	j	1b
2:
	mv	a0,s3
	call	cons
	li	a1,0
	call	cons
	lw	s3,(sp)
	lw	s2,4(sp)
	lw	s1,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

#define CHECK_PAIR(x)			\
	beqz	x,1f;			\
	andi	t0,x,3;			\
	beqz	t0,2f;			\
1:					\
	mv	a1,x;			\
	lla	a0,str_type_pair;	\
	tail	error;			\
2:

#define CHECK_FIXNUM(x) 		\
	andi	t0,x,3;			\
	li	t1,TAG_FIXNUM;		\
	beq	t0,t1,1f;		\
	mv	a1,x;			\
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

prim_integerp:
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
	ZEROFRAME
	call	gc
	blt	REG_TOSPACE,REG_FROMSPACE,1f
	call	gc
1:
	li	t0,TOP_OF_STACK - 16
	lw	t0,8(t0)
	lla	t1,image_env
	sw	t0,(t1)
	lla	t1,image_free
	sw	REG_FREE,(t1)
	li	a0,0
	li	a1,TOP_OF_STACK + SPACE_SIZE
	call	image
	lla	a0,SYM(ok)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret


### Evaluator

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
	mv	a1,a0
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


## Special forms

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
	sw	ra,12(sp)
	sw	s1,8(sp)
	sw	s2,4(sp)
	sw	zero,(sp)
	lw	a0,4(a0)
	lw	s1,(a0)
	lw	a0,4(a0)
	lw	a0,(a0)
	mv	s2,a1
	call	eval
	mv	a1,a0
	mv	a0,s1
	mv	a2,s2
	lw	s2,4(sp)
	lw	s1,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	set_variable

Leval_begin:
	lw	a0,4(a0)
	tail	eval_sequence

Leval_cond:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s1,8(sp)
	sw	s2,4(sp)
	sw	s3,(sp)
	lw	s1,4(a0)
	mv	s2,a1
1:
	bnez	s1,2f
	lla	a0,SYM(ok)
	lw	s3,(sp)
	lw	s2,4(sp)
	lw	s1,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	ret
2:
	lw	t0,(s1)
	lw	a0,(t0)
	lw	s3,4(t0)
	mv	a1,s2
	call	eval
	li	t0,FALSE
	beq	a0,t0,3f
	mv	a0,s3
	mv	a1,s2
	lw	s3,(sp)
	lw	s2,4(sp)
	lw	s1,8(sp)
	lw	ra,12(sp)
	addi	sp,sp,16
	tail	eval_sequence
3:
	lw	s1,4(s1)
	j	1b

Leval_let:
	# s1 = let bindings
	# s2 = let body
	# s3 = variables
	# s4 = values
	# s5 = expression
	# s6 = environment
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s1,24(sp)
	sw	s2,20(sp)
	sw	s3,16(sp)
	sw	s4,12(sp)
	sw	s5,8(sp)
	sw	s6,4(sp)
	sw	zero,(sp)
	lw	t0,4(a0)
	lw	s1,(t0)
	lw	s2,4(t0)
	li	s3,0
	li	s4,0
	mv	s6,a1
1:
	beqz	s1,2f
	lw	t0,(s1)
	lw	s5,4(t0)
	lw	s5,(s5)
	lw	a0,(t0)
	mv	a1,s3
	call	cons
	mv	s3,a0
	mv	a0,s5
	mv	a1,s6
	call	eval
	mv	a1,s4
	call	cons
	mv	s4,a0
	lw	s1,4(s1)
	j	1b
2:
	mv	a0,s3
	mv	a1,s4
	call	cons
	mv	a1,s6
	call	cons
	mv	a1,a0
	mv	a0,s2
	lw	s6,4(sp)
	lw	s5,8(sp)
	lw	s4,12(sp)
	lw	s3,16(sp)
	lw	s2,20(sp)
	lw	s1,24(sp)
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


### Procedures and environments

	.globl	make_procedure
make_procedure:
	addi	sp,sp,-16
	ZEROFRAME
	sw	ra,12(sp)
	sw	s1,8(sp)
	mv	s1,a2
	call	cons
	mv	a1,a0
	mv	a0,s1
	call	cons
	ori	a0,a0,TAG_PROCEDURE
	lw	s1,8(sp)
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
	mv	a1,a0
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
	mv	a1,a0
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


### Reader and symbols

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
	sw	a0,8(sp)
	call	is_nondigit_symbol_char
	bnez	a0,Lread_symbol
	lw	a0,8(sp)
7:
	li	t1,'('
	beq	a0,t1,Lread_list
	li	t1,'\''
	beq	a0,t1,Lread_quote
	li	t1,'#'
	beq	a0,t1,Lread_hash
Lunexpected_char:
	lla	a0,str_bad_read
	li	a1,0
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
	lw	a0,8(sp)
	li	t1,'A'
	blt	a0,t1,1f
	li	t1,'Z'
	bgt	a0,t1,1f
	addi	a0,a0,32
1:
	addi	sp,sp,-16
	sb	a0,(sp)
	addi	t0,sp,1
2:
	sw	t0,24(sp)
	call	peekchar
	sw	a0,20(sp)
	call	is_nondigit_symbol_char
	bnez	a0,Lconsume
	lw	a0,20(sp)
	li	t1,'0'
	blt	a0,t1,4f
	li	t1,'9'
	bgt	a0,t1,4f
Lconsume:
	call	readchar
	li	t1,'A'
	blt	a0,t1,3f
	li	t1,'Z'
	bgt	a0,t1,3f
	addi	a0,a0,32
3:
	lw	t0,24(sp)
	sb	a0,(t0)
	addi	t0,t0,1
	j	2b
4:
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
	li	t0,'t'
	bne	a0,t0,1f
	li	a0,TRUE
	j	2f
1:
	li	t0,'f'
	bne	a0,t0,Lunexpected_char
	li	a0,FALSE
2:
	lw	ra,12(sp)
	addi	sp,sp,16
	ret

is_nondigit_symbol_char:
	li	t0,'a'
	blt	a0,t0,1f
	li	t0,'z'
	bgt	a0,t0,5f
	j	4f
1:
	li	t0,'A'
	blt	a0,t0,2f
	li	t0,'Z'
	ble	a0,t0,4f
2:
	lla	t0,ext_alph_chars
3:
	lbu	t1,(t0)
	beqz	t1,5f
	beq	a0,t1,4f
	addi	t0,t0,1
	j	3b
4:
	li	a0,1
	ret
5:
	li	a0,0
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


### Printer

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


### Lists

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


### Allocation and garbage collector

	.globl	cons
cons:
	mv	t0,REG_TOSPACE
	li	t1,SPACE_SIZE
	add	t0,t0,t1
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
	li	t1,SPACE_SIZE
	add	t0,t0,t1
	beq	REG_FREE,t0,Lout_of_mem
	lw	ra,12(sp)
	addi	sp,sp,16
	j	1b
Lout_of_mem:
	lla	a0,str_out_of_mem
	li	a1,0
	tail	error

#define GC_ROOT(x)		\
	mv	a0,x;		\
	call	relocate;	\
	mv	x,a0

gc:
	addi	sp,sp,-16
	sw	ra,12(sp)
	lla	a0,str_gc
	call	writestr
	mv	t0,REG_FROMSPACE
	mv	REG_FROMSPACE,REG_TOSPACE
	mv	REG_TOSPACE,t0
	mv	REG_FREE,t0
	GC_ROOT(s1)
	GC_ROOT(s2)
	GC_ROOT(s3)
	GC_ROOT(s4)
	GC_ROOT(s5)
	GC_ROOT(s6)
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

	.bss
image_env:	.skip	4
image_free:	.skip	4
	.section	.rodata
ext_alph_chars:	.string	"!$%&*+-./:<=>?@^_~"
str_msg:	.string	"Scheme interpreter\n"
str_fresh:	.string	"(Not been imaged)\n"
str_prim:	.string	"#[primitive]"
str_proc:	.string "#[procedure "
str_gc:		.string	"GC cycle\n"
str_bad_read:	.string	"Unexpected character"
str_bad_exp:	.string	"Unknown expression type: "
str_unbound:	.string	"Unbound variable: "
str_not_proc:	.string	"Not a procedure: "
str_out_of_mem:	.string	"Out of memory"
str_type_pair:	.string	"Expected a pair: "
str_type_fixnum:.string	"Expected a fixnum: "

prim_addrs:
	.word	prim_eq
	.word	prim_integerp
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
	.word	prim_image

	.section	.data
obarray:
	NAME_SYM(quote, "quote")
	NAME_SYM(lambda, "lambda")
	NAME_SYM(if, "if")
	NAME_SYM(set, "set!")
	NAME_SYM(begin, "begin")
	NAME_SYM(cond, "cond")
	NAME_SYM(let, "let")
	NAME_SYM(define, "define")
	NAME_SYM(ok, "ok")
	MAKE_SYM("eq?")
	MAKE_SYM("integer?")
	MAKE_SYM("=")
	MAKE_SYM("<")
	MAKE_SYM("+")
	MAKE_SYM("-")
	MAKE_SYM("*")
	MAKE_SYM("quotient")
	MAKE_SYM("remainder")
	MAKE_SYM("pair?")
	MAKE_SYM("cons")
	MAKE_SYM("car")
	MAKE_SYM("cdr")
	MAKE_SYM("set-car!")
	MAKE_SYM("set-cdr!")
	MAKE_SYM("list")
	MAKE_SYM("symbol?")
	MAKE_SYM("procedure?")
	MAKE_SYM("read")
	MAKE_SYM("write")
	MAKE_SYM("newline")
	MAKE_SYM("image")
	.skip	1040
