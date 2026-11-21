# ==============================================================================
# Project: Aether-AI Edge SoC
# File:    boot.s
# Description: Low-Level Assembly Bootloader & Exception Vector Table
#              Initializes Stack Pointer (SP) and jumps to main() in C
# ==============================================================================

.section .text.init
.globl _start

_start:
    # 1. Initialize Register File to zero
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

    # 2. Setup Stack Pointer to top of System SRAM (0x1000_4000)
    li sp, 0x10004000

    # 3. Setup Global Pointer (Optional)
    li gp, 0x10000000

    # 4. Jump to High-Level C Entrypoint
    jal ra, main

    # 5. Trap loop on termination
_halt:
    wfi
    j _halt
