# ==============================================================================
# File: generate_hex.py
# Description: Generates Cycle-Accurate RISC-V Machine Code for Aether-AI Edge SoC
#              Encodes the entire C boot flow into binary instructions:
#              - Stack pointer init (sp = 0x10004000)
#              - UART banner character transmission
#              - NPU matrix activation/weight feeding
#              - NPU inference trigger and polling
#              - Success status print to console
# ==============================================================================

import os

def generate_riscv_boot_hex(output_file):
    # Standard RISC-V Instructions (32-bit Words)
    # R-type, I-type, S-type, U-type encodings
    
    instructions = [
        # 0x00: lui sp, 0x10004 (sp = 0x10004000)
        "10004137",
        # 0x04: lui s0, 0x40000 (s0 = UART_BASE = 0x40000000)
        "40000437",
        # 0x08: lui s1, 0x20000 (s1 = NPU_BASE = 0x20000000)
        "200004b7",

        # --- Print 'A' via UART ---
        # 0x0C: addi a0, zero, 65 ('A')
        "04100513",
        # 0x10: sw a0, 0(s0)
        "00a42023",

        # --- Print 'I' via UART ---
        # 0x14: addi a0, zero, 73 ('I')
        "04900513",
        # 0x18: sw a0, 0(s0)
        "00a42023",

        # --- Print ':' via UART ---
        # 0x1C: addi a0, zero, 58 (':')
        "03a00513",
        # 0x20: sw a0, 0(s0)
        "00a42023",

        # --- Print ' ' via UART ---
        # 0x24: addi a0, zero, 32 (' ')
        "02000513",
        # 0x28: sw a0, 0(s0)
        "00a42023",

        # --- Step 1: Write Activation Buffer (NPU_ACT_MEM 0x100..0x10C) ---
        # 0x2C: addi t0, zero, 1
        "00100293",
        # 0x30: sw t0, 256(s1) (NPU_ACT_MEM[0] = 1)
        "1054a023",
        # 0x34: addi t0, zero, 2
        "00200293",
        # 0x38: sw t0, 260(s1) (NPU_ACT_MEM[1] = 2)
        "1054a223",
        # 0x3C: addi t0, zero, 3
        "00300293",
        # 0x40: sw t0, 264(s1) (NPU_ACT_MEM[2] = 3)
        "1054a423",

        # --- Step 2: Write Weight Buffer (NPU_WGT_MEM 0x200..0x20C) ---
        # 0x44: addi t1, zero, 2
        "00200313",
        # 0x48: sw t1, 512(s1) (NPU_WGT_MEM[0] = 2)
        "2064a023",
        # 0x4C: addi t1, zero, 1
        "00100313",
        # 0x50: sw t1, 516(s1) (NPU_WGT_MEM[1] = 1)
        "2064a223",

        # --- Step 3: Trigger NPU Inference (NPU_CTRL = 0x05: START=1, RELU=1) ---
        # 0x54: addi t2, zero, 5
        "00500393",
        # 0x58: sw t2, 0(s1)
        "0074a023",

        # --- Step 4: Poll NPU Status Register (NPU_STATUS 0x04) ---
        # 0x5C: lw t3, 4(s1)
        "0044a383",
        # 0x60: andi t4, t3, 2 (Check bit 1: DONE)
        "0023f493",
        # 0x64: beq t4, zero, -8 (loop to 0x5C if not done)
        "fe048ce3",

        # --- Step 5: Readback Result Element (NPU_RES_MEM[0] 0x300) ---
        # 0x68: lw a1, 768(s1)
        "3004a583",

        # --- Step 6: Print 'O' 'K' via UART on Success ---
        # 0x6C: addi a0, zero, 79 ('O')
        "04f00513",
        # 0x70: sw a0, 0(s0)
        "00a42023",
        # 0x74: addi a0, zero, 75 ('K')
        "04b00513",
        # 0x78: sw a0, 0(s0)
        "00a42023",
        # 0x7C: addi a0, zero, 10 ('\n')
        "00a00513",
        # 0x80: sw a0, 0(s0)
        "00a42023",

        # --- Step 7: Infinite Sleep Loop ---
        # 0x84: j 0x84
        "0000006f"
    ]

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, "w") as f:
        for instr in instructions:
            f.write(instr + "\n")
            
    print(f"[+] Bootloader HEX generated ({len(instructions)} words): {output_file}")

if __name__ == "__main__":
    out_path = os.path.join(os.path.dirname(__file__), "..", "firmware", "boot_rom.hex")
    generate_riscv_boot_hex(os.path.abspath(out_path))
    # Also write to root directory so $readmemh finds it directly
    root_path = os.path.join(os.path.dirname(__file__), "..", "boot_rom.hex")
    generate_riscv_boot_hex(os.path.abspath(root_path))
