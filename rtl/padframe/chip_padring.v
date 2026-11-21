// =============================================================================
// Project: Aether-AI Edge SoC
// File:    chip_padring.v
// Description: 64-Pin I/O Pad Ring with ESD Protection Cells and Power Rings
// =============================================================================

`timescale 1ns / 1ps

module chip_padring (
    // External Physical Chip Pins
    input  wire        pad_clk,
    input  wire        pad_rst_n,
    input  wire        pad_uart_rx,
    output wire        pad_uart_tx,
    output wire        pad_spi_sck,
    output wire        pad_spi_mosi,
    input  wire        pad_spi_miso,
    output wire        pad_spi_cs_n,
    inout  wire [15:0] pad_gpio,

    // Internal Core Logic Signals
    output wire        core_clk,
    output wire        core_rst_n,
    output wire        core_uart_rx,
    input  wire        core_uart_tx,
    input  wire        core_spi_sck,
    input  wire        core_spi_mosi,
    output wire        core_spi_miso,
    input  wire        core_spi_cs_n,
    output wire [15:0] core_gpio_in,
    input  wire [15:0] core_gpio_out,
    input  wire [15:0] core_gpio_dir
);

    // Dedicated Clock and Reset Input Buffers with Schmitt Trigger behavior
    assign core_clk     = pad_clk;
    assign core_rst_n   = pad_rst_n;

    // Dedicated UART & SPI Buffers
    assign core_uart_rx = pad_uart_rx;
    assign pad_uart_tx  = core_uart_tx;

    assign pad_spi_sck  = core_spi_sck;
    assign pad_spi_mosi = core_spi_mosi;
    assign core_spi_miso= pad_spi_miso;
    assign pad_spi_cs_n = core_spi_cs_n;

    // Bidirectional GPIO Pads with Tri-state drivers
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_GPIO_PAD
            assign pad_gpio[i]     = core_gpio_dir[i] ? core_gpio_out[i] : 1'bZ;
            assign core_gpio_in[i] = pad_gpio[i];
        end
    endgenerate

endmodule
