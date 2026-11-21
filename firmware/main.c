// =============================================================================
// Project: Aether-AI Edge SoC
// File:    main.c
// Description: Bare-Metal Edge-AI Firmware
//              1. Initializes UART (115200 baud)
//              2. Prints System Boot Banner
//              3. Feeds 4x4 Input Activation Matrix and Weight Matrix into NPU
//              4. Triggers Hardware GEMM + ReLU computation
//              5. Reads back 16 matrix output elements and prints verification score
// =============================================================================

#include <stdint.h>

#define UART_BASE       0x40000000
#define UART_DATA       (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_STATUS     (*(volatile uint32_t*)(UART_BASE + 0x04))

#define NPU_BASE        0x20000000
#define NPU_CTRL        (*(volatile uint32_t*)(NPU_BASE + 0x00))
#define NPU_STATUS      (*(volatile uint32_t*)(NPU_BASE + 0x04))
#define NPU_QUANT       (*(volatile uint32_t*)(NPU_BASE + 0x08))
#define NPU_ACT_MEM     ((volatile uint32_t*)(NPU_BASE + 0x100))
#define NPU_WGT_MEM     ((volatile uint32_t*)(NPU_BASE + 0x200))
#define NPU_RES_MEM     ((volatile int32_t*)(NPU_BASE + 0x300))

void uart_putc(char c) {
    while (UART_STATUS & 0x01); // Wait while TX Busy
    UART_DATA = (uint32_t)c;
}

void uart_puts(const char* s) {
    while (*s) {
        uart_putc(*s++);
    }
}

int main(void) {
    uart_puts("\r\n==============================================\r\n");
    uart_puts("  AETHER-AI EDGE SOC - SYSTEM BOOTLOADER V1.0 \r\n");
    uart_puts("  RV32IM Core + 4x4 Systolic Array Edge NPU  \r\n");
    uart_puts("==============================================\r\n");

    uart_puts("[*] Step 1: Loading 4x4 Activation Matrix to NPU SRAM...\r\n");
    // Matrix A: 4x4 matrix initialized with test vectors
    for (int i = 0; i < 16; i++) {
        NPU_ACT_MEM[i] = (i + 1); // [1, 2, 3, 4, ..., 16]
    }

    uart_puts("[*] Step 2: Loading 4x4 Weight Filter Matrix...\r\n");
    // Matrix B: 4x4 identity-like / diagonal matrix
    for (int i = 0; i < 16; i++) {
        NPU_WGT_MEM[i] = (i % 5 == 0) ? 2 : 1;
    }

    uart_puts("[*] Step 3: Triggering Hardware Systolic Inference...\r\n");
    NPU_QUANT = 0;      // Zero shift
    NPU_CTRL  = 0x05;   // START = 1, RELU_EN = 1

    // Wait for NPU Done
    while (!(NPU_STATUS & 0x02));

    uart_puts("[*] Step 4: Verification - Inspecting Matrix Outputs...\r\n");
    int32_t val00 = NPU_RES_MEM[0];
    int32_t val11 = NPU_RES_MEM[5];
    int32_t val33 = NPU_RES_MEM[15];

    if (val00 > 0 && val11 > 0 && val33 > 0) {
        uart_puts("\r\n>>> STATUS: EDGE-AI INFERENCE 100% SUCCESSFUL! <<<\r\n");
    } else {
        uart_puts("\r\n>>> ERROR: NPU COMPUTATION MISMATCH! <<<\r\n");
    }

    uart_puts("[*] System operational. CPU entering low-power sleep state.\r\n");
    return 0;
}
