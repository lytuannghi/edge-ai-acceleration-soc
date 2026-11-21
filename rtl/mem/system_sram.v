// =============================================================================
// Project: Aether-AI Edge SoC
// File:    system_sram.v
// Description: 16KB High-Speed Single-Cycle SRAM (4096 x 32-bit words)
//              Byte-level write enables for SW, SH, SB support
// =============================================================================

`timescale 1ns / 1ps

module system_sram (
    input  wire        clk,
    input  wire        cs,
    input  wire        wr_en,
    input  wire [3:0]  byte_en,
    input  wire [13:0] addr, // Byte address [13:2] for word index
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    reg [31:0] sram_array [0:4095];
    wire [11:0] word_idx = addr[13:2];

    always @(posedge clk) begin
        if (cs) begin
            if (wr_en) begin
                if (byte_en[0]) sram_array[word_idx][7:0]   <= wdata[7:0];
                if (byte_en[1]) sram_array[word_idx][15:8]  <= wdata[15:8];
                if (byte_en[2]) sram_array[word_idx][23:16] <= wdata[23:16];
                if (byte_en[3]) sram_array[word_idx][31:24] <= wdata[31:24];
            end
            rdata <= sram_array[word_idx];
        end
    end

endmodule
