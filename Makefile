AS=riscv32-elf-as
CC=riscv32-elf-gcc
LD=$(CC)
OBJCOPY=riscv32-elf-objcopy

ASFLAGS=-march=rv32im -mabi=ilp32
CFLAGS=$(ASFLAGS) -O2
LDFLAGS=$(ASFLAGS) -T riscv.ld -nostdlib -lgcc

COMMON=lib.o trap.o tty.o

.SUFFIXES: .s .S .bin .txt

all: $(COMMON) scheme.bin

.bin.txt:
	xxd -p $*.bin | tr -d "\n" | sed "s/.\{2\}/&\n/g" | sed "s/^/0x/g" >$@

scheme.bin: scheme.o $(COMMON)
	$(LD) -nostdlib -T scheme.ld -o $* $(COMMON) scheme.o
	$(OBJCOPY) --dump-section .text=$@ --dump-section .obarray=obarray $*
	SZ=`ls -l $@ | awk '{print($$5)}'`; \
	N=`expr 9216 - $$SZ`; \
	dd if=/dev/zero bs=$$N count=1 of=$@ oflag=append conv=notrunc
	cat obarray >>$@
	rm -f scheme obarray
	base32 -w 0 $@; echo

.o.bin:
	$(MAKE) $(COMMON)
	$(LD) -o $@ $(COMMON) $< $(LDFLAGS)
	$(OBJCOPY) -O binary $@
	base32 -w 0 $@; echo

.s.o:
	$(AS) $(ASFLAGS) -o $@ $<

.S.o:
	$(CC) $(ASFLAGS) -c -o $@ $<

clean:
	rm -f *.o *.bin *.txt
