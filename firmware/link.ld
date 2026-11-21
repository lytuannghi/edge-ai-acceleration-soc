/* Linker Script for Aether-AI Edge SoC */
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    ROM  (rx)  : ORIGIN = 0x00000000, LENGTH = 8K
    SRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 16K
}

SECTIONS
{
    .text : {
        . = ALIGN(4);
        *(.text.init)
        *(.text*)
        . = ALIGN(4);
    } > ROM

    .rodata : {
        . = ALIGN(4);
        *(.rodata*)
        . = ALIGN(4);
    } > ROM

    .data : {
        . = ALIGN(4);
        *(.data*)
        . = ALIGN(4);
    } > SRAM AT > ROM

    .bss : {
        . = ALIGN(4);
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
    } > SRAM
}
