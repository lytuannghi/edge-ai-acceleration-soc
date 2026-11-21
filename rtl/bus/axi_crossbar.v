// =============================================================================
// Project: Aether-AI Edge SoC
// File:    axi_crossbar.v
// Description: Multi-Master Multi-Slave Interconnect Crossbar
//              Decodes addresses to ROM, SRAM, AI NPU, and APB Peripherals
// =============================================================================

`timescale 1ns / 1ps
`include "bus_defines.vh"

module axi_crossbar (
    input  wire        clk,
    input  wire        rst_n,

    // CPU Master Bus
    input  wire        cpu_req,
    input  wire        cpu_wr,
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    input  wire [3:0]  cpu_wstrb,
    output reg  [31:0] cpu_rdata,
    output reg         cpu_ready,

    // Slave 0: Boot ROM
    output wire        rom_cs,
    output wire [12:0] rom_addr,
    input  wire [31:0] rom_rdata,

    // Slave 1: System SRAM
    output wire        sram_cs,
    output wire        sram_wr,
    output wire [3:0]  sram_wstrb,
    output wire [13:0] sram_addr,
    output wire [31:0] sram_wdata,
    input  wire [31:0] sram_rdata,

    // Slave 2: AI NPU
    output wire        npu_psel,
    output wire        npu_penable,
    output wire        npu_pwrite,
    output wire [11:0] npu_paddr,
    output wire [31:0] npu_pwdata,
    input  wire [31:0] npu_prdata,
    input  wire        npu_pready,

    // Slave 3: APB Peripherals Bridge
    output wire        apb_req,
    output wire        apb_wr,
    output wire [31:0] apb_addr,
    output wire [31:0] apb_wdata,
    input  wire [31:0] apb_rdata,
    input  wire        apb_ready
);

    // Address Decoding
    wire sel_rom  = (cpu_addr >= 32'h00000000 && cpu_addr < 32'h00002000);
    wire sel_sram = (cpu_addr >= 32'h10000000 && cpu_addr < 32'h10004000);
    wire sel_npu  = (cpu_addr >= 32'h20000000 && cpu_addr < 32'h20001000);
    wire sel_apb  = (cpu_addr >= 32'h40000000 && cpu_addr < 32'h50000000);

    assign rom_cs     = cpu_req && sel_rom;
    assign rom_addr   = cpu_addr[12:0];

    assign sram_cs    = cpu_req && sel_sram;
    assign sram_wr    = cpu_wr;
    assign sram_wstrb = cpu_wstrb;
    assign sram_addr  = cpu_addr[13:0];
    assign sram_wdata = cpu_wdata;

    // APB-style generation for NPU
    reg npu_en_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) npu_en_reg <= 1'b0;
        else npu_en_reg <= cpu_req && sel_npu && !npu_en_reg;
    end
    assign npu_psel    = cpu_req && sel_npu;
    assign npu_penable = npu_en_reg;
    assign npu_pwrite  = cpu_wr;
    assign npu_paddr   = cpu_addr[11:0];
    assign npu_pwdata  = cpu_wdata;

    assign apb_req   = cpu_req && sel_apb;
    assign apb_wr    = cpu_wr;
    assign apb_addr  = cpu_addr;
    assign apb_wdata = cpu_wdata;

    // Response Routing
    always @(*) begin
        if (sel_rom) begin
            cpu_rdata = rom_rdata;
            cpu_ready = 1'b1;
        end else if (sel_sram) begin
            cpu_rdata = sram_rdata;
            cpu_ready = 1'b1;
        end else if (sel_npu) begin
            cpu_rdata = npu_prdata;
            cpu_ready = npu_pready && npu_penable;
        end else if (sel_apb) begin
            cpu_rdata = apb_rdata;
            cpu_ready = apb_ready;
        end else begin
            cpu_rdata = 32'd0;
            cpu_ready = 1'b1;
        end
    end

endmodule
