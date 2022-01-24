AS=riscv32-elf-as
CC=riscv32-elf-gcc
LD=riscv32-elf-ld
OBJCOPY=riscv32-elf-objcopy

LDFLAGS=-T riscv.ld
ASFLAGS=-march=rv32imfd
CFLAGS=$(ASFLAGS) -O2

.SUFFIXES: .s .S .bin .txt

all: lib.o calc.txt

.bin.txt:
	xxd -p $*.bin | tr -d "\n" | sed "s/.\{2\}/&\n/g" | sed "s/^/0x/g" >$@

scheme.bin: scheme.o lib.o
	$(LD) -T scheme.ld -o $* lib.o scheme.o
	$(OBJCOPY) --dump-section .text=$@ --dump-section .obarray=obarray $*
	SZ=`ls -l $@ | awk '{print($$5)}'`; \
	N=`expr 9216 - $$SZ`; \
	dd if=/dev/zero bs=$$N count=1 of=$@ oflag=append conv=notrunc
	cat obarray >>$@
	rm -f scheme obarray

.o.bin:
	$(LD) $(LDFLAGS) -o $@ lib.o $<
	$(OBJCOPY) -O binary $@

.s.o:
	$(AS) $(ASFLAGS) -o $@ $<

.S.o:
	$(CC) $(ASFLAGS) -c -o $@ $<
