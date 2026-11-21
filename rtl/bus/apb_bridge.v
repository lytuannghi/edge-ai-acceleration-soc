// =============================================================================
// Project: Aether-AI Edge SoC
// File:    apb_bridge.v
// Description: APB Master Interconnect Bridge
//              Routes to UART, SPI Master, 32-bit Timer, and GPIO
// =============================================================================

`timescale 1ns / 1ps
`include "bus_defines.vh"

module apb_bridge (
    input  wire        clk,
    input  wire        rst_n,

    // High-Level Bus Request from Crossbar
    input  wire        apb_req,
    input  wire        apb_wr,
    input  wire [31:0] apb_addr,
    input  wire [31:0] apb_wdata,
    output reg  [31:0] apb_rdata,
    output reg         apb_ready,

    // UART Slave Interface
    output wire        uart_psel,
    output wire        uart_penable,
    output wire        uart_pwrite,
    output wire [7:0]  uart_paddr,
    output wire [31:0] uart_pwdata,
    input  wire [31:0] uart_prdata,

    // SPI Master Slave Interface
    output wire        spi_psel,
    output wire        spi_penable,
    output wire        spi_pwrite,
    output wire [7:0]  spi_paddr,
    output wire [31:0] spi_pwdata,
    input  wire [31:0] spi_prdata,

    // Timer Slave Interface
    output wire        timer_psel,
    output wire        timer_penable,
    output wire        timer_pwrite,
    output wire [7:0]  timer_paddr,
    output wire [31:0] timer_pwdata,
    input  wire [31:0] timer_prdata,

    // GPIO Slave Interface
    output wire        gpio_psel,
    output wire        gpio_penable,
    output wire        gpio_pwrite,
    output wire [7:0]  gpio_paddr,
    output wire [31:0] gpio_pwdata,
    input  wire [31:0] gpio_prdata
);

    // Peripheral Address Decoders
    wire sel_uart  = (apb_addr[15:12] == 4'h0); // 0x4000_0000
    wire sel_spi   = (apb_addr[15:12] == 4'h1); // 0x4000_1000
    wire sel_timer = (apb_addr[15:12] == 4'h2); // 0x4000_2000
    wire sel_gpio  = (apb_addr[15:12] == 4'h3); // 0x4000_3000

    // APB 2-cycle FSM (SETUP -> ACCESS)
    reg penable_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) penable_reg <= 1'b0;
        else penable_reg <= apb_req && !penable_reg;
    end

    // Signal assignments
    assign uart_psel    = apb_req && sel_uart;
    assign uart_penable = penable_reg && sel_uart;
    assign uart_pwrite  = apb_wr;
    assign uart_paddr   = apb_addr[7:0];
    assign uart_pwdata  = apb_wdata;

    assign spi_psel    = apb_req && sel_spi;
    assign spi_penable = penable_reg && sel_spi;
    assign spi_pwrite  = apb_wr;
    assign spi_paddr   = apb_addr[7:0];
    assign spi_pwdata  = apb_wdata;

    assign timer_psel    = apb_req && sel_timer;
    assign timer_penable = penable_reg && sel_timer;
    assign timer_pwrite  = apb_wr;
    assign timer_paddr   = apb_addr[7:0];
    assign timer_pwdata  = apb_wdata;

    assign gpio_psel    = apb_req && sel_gpio;
    assign gpio_penable = penable_reg && sel_gpio;
    assign gpio_pwrite  = apb_wr;
    assign gpio_paddr   = apb_addr[7:0];
    assign gpio_pwdata  = apb_wdata;

    always @(*) begin
        apb_ready = penable_reg;
        if (sel_uart)       apb_rdata = uart_prdata;
        else if (sel_spi)   apb_rdata = spi_prdata;
        else if (sel_timer) apb_rdata = timer_prdata;
        else if (sel_gpio)  apb_rdata = gpio_prdata;
        else                apb_rdata = 32'd0;
    end

endmodule
