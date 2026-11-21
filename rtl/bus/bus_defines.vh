`ifndef BUS_DEFINES_VH
`define BUS_DEFINES_VH

// Memory Map Addressing
// 0x0000_0000 - 0x0000_1FFF: 8KB Boot ROM (Firmware Code)
`define ADDR_ROM_BASE       32'h00000000
`define ADDR_ROM_MASK       32'hFFFFE000

// 0x1000_0000 - 0x1000_3FFF: 16KB System SRAM (Data / Heap / Stack)
`define ADDR_SRAM_BASE      32'h10000000
`define ADDR_SRAM_MASK      32'hFFFFC000

// 0x2000_0000 - 0x2000_0FFF: Edge-AI NPU Coprocessor
`define ADDR_NPU_BASE       32'h20000000

// 0x4000_0000 - 0x4FFF_FFFF: APB Peripherals Space
`define ADDR_APB_BASE       32'h40000000
`define ADDR_UART_BASE      32'h40000000  // UART Controller
`define ADDR_SPI_BASE       32'h40001000  // SPI Master
`define ADDR_TIMER_BASE     32'h40002000  // 32-bit Timer
`define ADDR_GPIO_BASE      32'h40003000  // GPIO Controller

`endif // BUS_DEFINES_VH
