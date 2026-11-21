// =============================================================================
// Project: Aether-AI Edge SoC
// File:    boot_rom.v
// Description: 8KB Boot ROM (2048 x 32-bit words) with Zero-Latency Read
// =============================================================================

`timescale 1ns / 1ps

module boot_rom (
    input  wire        clk,
    input  wire        cs,
    input  wire [12:0] addr, // Byte address [12:2] for word index
    output wire [31:0] rdata
);

    reg [31:0] mem [0:2047];

    initial begin
        $readmemh("boot_rom.hex", mem);
    end

    // Combinational Read for single-cycle instruction decode
    assign rdata = cs ? mem[addr[12:2]] : 32'd0;

endmodule
