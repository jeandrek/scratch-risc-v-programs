SECTIONS {
	.text 0 : { *(.text) *(.rodata) *(.data) *(.bss) }
	/DISCARD/ : { *(.comment) }
}
