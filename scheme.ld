SECTIONS {
	.text 0 : { *(.text) *(.rodata) *(.data) *(.bss) }
	.obarray 0x2400 : { *(.obarray) }
	/DISCARD/ : { *(.comment) }
}
