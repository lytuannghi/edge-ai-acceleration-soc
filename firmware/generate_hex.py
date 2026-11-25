#!/usr/bin/env python3
"""
RV32IM Firmware Generator for Aether-AI Edge SoC.
Computes RV32M MUL/DIV/REM tests, configures UART baud and streams "AI:OK\n",
drives NPU 4x4 GEMM + hardware ReLU/quantization, and sets GPIO outputs.
"""

import os


def encode_r(funct7, rs2, rs1, funct3, rd, opcode=0x33):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_i(rd, rs1, funct3, imm12, opcode=0x13):
    return ((imm12 & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_s(rs2, rs1, imm12, funct3=0x2):
    return (((imm12 >> 5) & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((imm12 & 0x1F) << 7) | 0x23


def encode_b(funct3, rs1, rs2, offset_bytes):
    imm = offset_bytes & 0x1FFF
    b12 = (imm >> 12) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    b11 = (imm >> 11) & 1
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | 0x63


def encode_u(rd, imm20, opcode=0x37):
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_j(rd, offset_bytes=0):
    imm = offset_bytes & 0x1FFFFF
    j20 = (imm >> 20) & 1
    j10_1 = (imm >> 1) & 0x3FF
    j11 = (imm >> 11) & 1
    j19_12 = (imm >> 12) & 0xFF
    return (j20 << 31) | (j10_1 << 21) | (j11 << 20) | (j19_12 << 12) | (rd << 7) | 0x6F


def emit_uart_putc(instrs, uart_reg, ch, tmp_r=10, stat_r=11):
    # Wait while UART_STATUS[0] (tx_busy) == 1
    poll_idx = len(instrs)
    instrs.append(encode_i(stat_r, uart_reg, 0x2, 4, opcode=0x03))      # lw stat, 4(uart)
    instrs.append(encode_i(stat_r, stat_r, 0x7, 1))                     # andi stat, stat, 1
    instrs.append(encode_b(0x1, stat_r, 0, (poll_idx - len(instrs)) * 4))  # bne stat, x0, poll
    instrs.append(encode_i(tmp_r, 0, 0x0, ord(ch)))
    instrs.append(encode_s(tmp_r, uart_reg, 0))


def generate_riscv_boot_hex():
    instrs = []
    # x2(sp)=0x10004000, x8(s0)=UART(0x40000000), x9(s1)=NPU(0x20000000), x18(s2)=SRAM(0x10000000)
    instrs.append(encode_u(2, 0x10004))
    instrs.append(encode_u(8, 0x40000))
    instrs.append(encode_u(9, 0x20000))
    instrs.append(encode_u(18, 0x10000))

    # Set UART_BAUD_DIV (0x08) = 4 for fast deterministic TB decode (80 ns/bit)
    instrs.append(encode_i(10, 0, 0x0, 4))
    instrs.append(encode_s(10, 8, 8))

    # Send "AI:" via UART
    for ch in "AI:":
        emit_uart_putc(instrs, 8, ch)

    # RV32M ALU checks: 6*7=42 -> SRAM[4], -99/7=-14 -> SRAM[5], 100/7=14 -> SRAM[6], 100%7=2 -> SRAM[7]
    instrs.append(encode_i(5, 0, 0x0, 6))
    instrs.append(encode_i(6, 0, 0x0, 7))
    instrs.append(encode_r(0x01, 6, 5, 0x0, 7))   # MUL x7 = 42
    instrs.append(encode_s(7, 18, 16))            # SRAM[4] (offset 0x10) = 42

    instrs.append(encode_i(5, 0, 0x0, -99))
    instrs.append(encode_r(0x01, 6, 5, 0x4, 7))   # DIV x7 = -14
    instrs.append(encode_s(7, 18, 20))            # SRAM[5] (offset 0x14) = -14

    instrs.append(encode_i(5, 0, 0x0, 100))
    instrs.append(encode_r(0x01, 6, 5, 0x5, 7))   # DIVU x7 = 14
    instrs.append(encode_s(7, 18, 24))            # SRAM[6] (offset 0x18) = 14
    instrs.append(encode_r(0x01, 6, 5, 0x6, 7))   # REM x7 = 2
    instrs.append(encode_s(7, 18, 28))            # SRAM[7] (offset 0x1C) = 2

    # NPU Activations: [1, 2, 3], Weights: [2, 1] -> p_out[0][0] = 1*2 + 2*1 = 4
    instrs.append(encode_i(5, 0, 0x0, 1))
    instrs.append(encode_s(5, 9, 0x100))
    instrs.append(encode_i(5, 0, 0x0, 2))
    instrs.append(encode_s(5, 9, 0x104))
    instrs.append(encode_i(5, 0, 0x0, 3))
    instrs.append(encode_s(5, 9, 0x108))

    # NPU Weights column 0: W[0][0]=2 (0x200), W[1][0]=1 (0x210) -> C[0][0] = 1*2 + 2*1 = 4
    instrs.append(encode_i(6, 0, 0x0, 2))
    instrs.append(encode_s(6, 9, 0x200))
    instrs.append(encode_i(6, 0, 0x0, 1))
    instrs.append(encode_s(6, 9, 0x210))

    # Trigger NPU (CTRL = 0x05: START=1, RELU_EN=1)
    instrs.append(encode_i(7, 0, 0x0, 5))
    instrs.append(encode_s(7, 9, 0))

    # Poll NPU STATUS (0x04) bit 1 (DONE)
    npu_poll = len(instrs)
    instrs.append(encode_i(12, 9, 0x2, 4, opcode=0x03))
    instrs.append(encode_i(12, 12, 0x7, 2))
    instrs.append(encode_b(0x0, 12, 0, (npu_poll - len(instrs)) * 4))

    # Read raw MAC NPU_RES[0][0] (0x300) and packed ReLU NPU_RELU_ROW0 (0x340) into SRAM
    instrs.append(encode_i(11, 9, 0x2, 0x300, opcode=0x03))
    instrs.append(encode_s(11, 18, 32))           # SRAM[8] = 4 (raw MAC)
    instrs.append(encode_i(11, 9, 0x2, 0x340, opcode=0x03))
    instrs.append(encode_s(11, 18, 36))           # SRAM[9] = packed relu_out row 0

    # Configure GPIO Controller (0x40003000): dir=0xFF, out=0xA5
    instrs.append(encode_u(19, 0x40003))
    instrs.append(encode_i(5, 0, 0x0, 0xFF))
    instrs.append(encode_s(5, 19, 4))
    instrs.append(encode_i(5, 0, 0x0, 0xA5))
    instrs.append(encode_s(5, 19, 0))

    # Print " OK\n" via UART
    for ch in " OK\n":
        emit_uart_putc(instrs, 8, ch)

    # Completion marker SRAM[0] = 0x42
    instrs.append(encode_i(5, 0, 0x0, 0x42))
    instrs.append(encode_s(5, 18, 0))

    # Halt loop
    instrs.append(encode_j(0, 0))

    hex_lines = [f"{w:08x}" for w in instrs]
    while len(hex_lines) < 2048:
        hex_lines.append("00000013")
    fw_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(fw_dir)
    for out_path in (os.path.join(fw_dir, "boot_rom.hex"), os.path.join(repo_root, "boot_rom.hex")):
        with open(out_path, "w", encoding="utf-8") as f:
            f.write("\n".join(hex_lines) + "\n")
    print(f"[+] Edge-AI Bootloader HEX generated ({len(instrs)} active words).")


if __name__ == "__main__":
    generate_riscv_boot_hex()
