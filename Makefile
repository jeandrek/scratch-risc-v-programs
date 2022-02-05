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
