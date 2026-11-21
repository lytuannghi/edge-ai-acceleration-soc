// =============================================================================
// Project: Aether-AI Edge SoC (Model: AA-SOC32)
// File:    edge_ai_soc_top.v
// Description: Top-Level ASIC Silicon Chip Integration
//              Subsystems:
//              1. RV32IM 32-bit RISC-V Processor Core
//              2. Edge-AI Neural Processing Unit (4x4 Systolic Array + ReLU)
//              3. AMBA AXI4 / APB Crossbar Interconnect Fabric
//              4. 8KB Boot ROM & 16KB System Scratchpad SRAM
//              5. Peripherals: UART, SPI Master, 32-bit Timer, 16-bit GPIO
//              6. 64-Pin I/O Pad Ring with ESD Protection & Dual Power Ring
// =============================================================================

`timescale 1ns / 1ps

module edge_ai_soc_top (
    // External Physical Chip Pins
    input  wire        pad_clk,
    input  wire        pad_rst_n,
    input  wire        pad_uart_rx,
    output wire        pad_uart_tx,
    output wire        pad_spi_sck,
    output wire        pad_spi_mosi,
    input  wire        pad_spi_miso,
    output wire        pad_spi_cs_n,
    inout  wire [15:0] pad_gpio
);

    // Internal Core Wires
    wire        clk;
    wire        rst_n;
    wire        uart_rx;
    wire        uart_tx;
    wire        spi_sck;
    wire        spi_mosi;
    wire        spi_miso;
    wire        spi_cs_n;
    wire [15:0] gpio_in;
    wire [15:0] gpio_out;
    wire [15:0] gpio_dir;

    // -------------------------------------------------------------------------
    // 1. Pad Ring Subsystem
    // -------------------------------------------------------------------------
    chip_padring u_padring (
        .pad_clk      (pad_clk),
        .pad_rst_n    (pad_rst_n),
        .pad_uart_rx  (pad_uart_rx),
        .pad_uart_tx  (pad_uart_tx),
        .pad_spi_sck  (pad_spi_sck),
        .pad_spi_mosi (pad_spi_mosi),
        .pad_spi_miso (pad_spi_miso),
        .pad_spi_cs_n (pad_spi_cs_n),
        .pad_gpio     (pad_gpio),

        .core_clk     (clk),
        .core_rst_n   (rst_n),
        .core_uart_rx (uart_rx),
        .core_uart_tx (uart_tx),
        .core_spi_sck (spi_sck),
        .core_spi_mosi(spi_mosi),
        .core_spi_miso(spi_miso),
        .core_spi_cs_n(spi_cs_n),
        .core_gpio_in (gpio_in),
        .core_gpio_out(gpio_out),
        .core_gpio_dir(gpio_dir)
    );

    // -------------------------------------------------------------------------
    // 2. CPU Instruction and Data Buses
    // -------------------------------------------------------------------------
    wire [31:0] instr_addr;
    wire [31:0] instr_data;
    wire        data_req;
    wire        data_wr;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [3:0]  data_wstrb;
    wire [31:0] data_rdata;
    wire        data_ready;
    wire [31:0] curr_pc;

    riscv_core u_cpu (
        .clk       (clk),
        .rst_n     (rst_n),
        .instr_addr(instr_addr),
        .instr_data(instr_data),
        .data_req  (data_req),
        .data_wr   (data_wr),
        .data_addr (data_addr),
        .data_wdata(data_wdata),
        .data_wstrb(data_wstrb),
        .data_rdata(data_rdata),
        .data_ready(data_ready),
        .curr_pc   (curr_pc)
    );

    // -------------------------------------------------------------------------
    // 3. System Interconnect Crossbar
    // -------------------------------------------------------------------------
    wire        rom_cs;
    wire [12:0] rom_addr;
    wire [31:0] rom_rdata;

    wire        sram_cs;
    wire        sram_wr;
    wire [3:0]  sram_wstrb;
    wire [13:0] sram_addr;
    wire [31:0] sram_wdata;
    wire [31:0] sram_rdata;

    wire        npu_psel;
    wire        npu_penable;
    wire        npu_pwrite;
    wire [11:0] npu_paddr;
    wire [31:0] npu_pwdata;
    wire [31:0] npu_prdata;
    wire        npu_pready;

    wire        apb_req;
    wire        apb_wr;
    wire [31:0] apb_addr;
    wire [31:0] apb_wdata;
    wire [31:0] apb_rdata;
    wire        apb_ready;

    axi_crossbar u_crossbar (
        .clk       (clk),
        .rst_n     (rst_n),
        .cpu_req   (data_req),
        .cpu_wr    (data_wr),
        .cpu_addr  (data_addr),
        .cpu_wdata (data_wdata),
        .cpu_wstrb (data_wstrb),
        .cpu_rdata (data_rdata),
        .cpu_ready (data_ready),

        .rom_cs    (rom_cs),
        .rom_addr  (rom_addr),
        .rom_rdata (rom_rdata),

        .sram_cs   (sram_cs),
        .sram_wr   (sram_wr),
        .sram_wstrb(sram_wstrb),
        .sram_addr (sram_addr),
        .sram_wdata(sram_wdata),
        .sram_rdata(sram_rdata),

        .npu_psel   (npu_psel),
        .npu_penable(npu_penable),
        .npu_pwrite (npu_pwrite),
        .npu_paddr  (npu_paddr),
        .npu_pwdata (npu_pwdata),
        .npu_prdata (npu_prdata),
        .npu_pready (npu_pready),

        .apb_req  (apb_req),
        .apb_wr   (apb_wr),
        .apb_addr (apb_addr),
        .apb_wdata(apb_wdata),
        .apb_rdata(apb_rdata),
        .apb_ready(apb_ready)
    );

    // -------------------------------------------------------------------------
    // 4. Memory Subsystem (Boot ROM & SRAM)
    // -------------------------------------------------------------------------
    boot_rom u_rom (
        .clk  (clk),
        .cs   (1'b1), // Active fetch
        .addr (instr_addr[12:0]),
        .rdata(instr_data)
    );

    system_sram u_sram (
        .clk    (clk),
        .cs     (sram_cs),
        .wr_en  (sram_wr),
        .byte_en(sram_wstrb),
        .addr   (sram_addr),
        .wdata  (sram_wdata),
        .rdata  (sram_rdata)
    );

    // -------------------------------------------------------------------------
    // 5. Edge-AI Neural Processing Unit (NPU)
    // -------------------------------------------------------------------------
    wire npu_irq;

    npu_top u_npu (
        .clk    (clk),
        .rst_n  (rst_n),
        .psel   (npu_psel),
        .penable(npu_penable),
        .pwrite (npu_pwrite),
        .paddr  (npu_paddr),
        .pwdata (npu_pwdata),
        .prdata (npu_prdata),
        .pready (npu_pready),
        .npu_irq(npu_irq)
    );

    // -------------------------------------------------------------------------
    // 6. APB Peripherals Subsystem
    // -------------------------------------------------------------------------
    wire        uart_psel,   uart_penable,  uart_pwrite;
    wire [7:0]  uart_paddr;
    wire [31:0] uart_pwdata, uart_prdata;

    wire        spi_psel,    spi_penable,   spi_pwrite;
    wire [7:0]  spi_paddr;
    wire [31:0] spi_pwdata,  spi_prdata;

    wire        timer_psel,  timer_penable, timer_pwrite;
    wire [7:0]  timer_paddr;
    wire [31:0] timer_pwdata,timer_prdata;

    wire        gpio_psel,   gpio_penable,  gpio_pwrite;
    wire [7:0]  gpio_paddr;
    wire [31:0] gpio_pwdata, gpio_prdata;

    apb_bridge u_apb (
        .clk       (clk),
        .rst_n     (rst_n),
        .apb_req   (apb_req),
        .apb_wr    (apb_wr),
        .apb_addr  (apb_addr),
        .apb_wdata (apb_wdata),
        .apb_rdata (apb_rdata),
        .apb_ready (apb_ready),

        .uart_psel   (uart_psel),
        .uart_penable(uart_penable),
        .uart_pwrite (uart_pwrite),
        .uart_paddr  (uart_paddr),
        .uart_pwdata (uart_pwdata),
        .uart_prdata (uart_prdata),

        .spi_psel   (spi_psel),
        .spi_penable(spi_penable),
        .spi_pwrite (spi_pwrite),
        .spi_paddr  (spi_paddr),
        .spi_pwdata (spi_pwdata),
        .spi_prdata (spi_prdata),

        .timer_psel   (timer_psel),
        .timer_penable(timer_penable),
        .timer_pwrite (timer_pwrite),
        .timer_paddr  (timer_paddr),
        .timer_pwdata (timer_pwdata),
        .timer_prdata (timer_prdata),

        .gpio_psel   (gpio_psel),
        .gpio_penable(gpio_penable),
        .gpio_pwrite (gpio_pwrite),
        .gpio_paddr  (gpio_paddr),
        .gpio_pwdata (gpio_pwdata),
        .gpio_prdata (gpio_prdata)
    );

    // Peripheral Controllers Instantiation
    uart_controller u_uart (
        .clk     (clk),
        .rst_n   (rst_n),
        .psel    (uart_psel),
        .penable (uart_penable),
        .pwrite  (uart_pwrite),
        .paddr   (uart_paddr),
        .pwdata  (uart_pwdata),
        .prdata  (uart_prdata),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx),
        .uart_irq()
    );

    spi_master u_spi (
        .clk     (clk),
        .rst_n   (rst_n),
        .psel    (spi_psel),
        .penable (spi_penable),
        .pwrite  (spi_pwrite),
        .paddr   (spi_paddr),
        .pwdata  (spi_pwdata),
        .prdata  (spi_prdata),
        .spi_sck (spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n)
    );

    timer_32bit u_timer (
        .clk      (clk),
        .rst_n    (rst_n),
        .psel     (timer_psel),
        .penable  (timer_penable),
        .pwrite   (timer_pwrite),
        .paddr    (timer_paddr),
        .pwdata   (timer_pwdata),
        .prdata   (timer_prdata),
        .timer_irq()
    );

    gpio_controller u_gpio (
        .clk     (clk),
        .rst_n   (rst_n),
        .psel    (gpio_psel),
        .penable (gpio_penable),
        .pwrite  (gpio_pwrite),
        .paddr   (gpio_paddr),
        .pwdata  (gpio_pwdata),
        .prdata  (gpio_prdata),
        .gpio_in (gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir)
    );

endmodule
