// =============================================================================
// Project: Aether-AI Edge SoC
// File:    pe.v
// Description: Processing Element (PE) for Systolic Matrix Multiplication
//              Computes: P_out = P_in + (A_in * B_in)
//              Datapath: 8-bit signed inputs, 32-bit signed accumulator
// =============================================================================

`timescale 1ns / 1ps

module pe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clr_acc,
    input  wire        en,

    // Systolic Inputs
    input  wire signed [7:0]  act_in,     // Horizontal Activation Stream
    input  wire signed [7:0]  weight_in,  // Vertical Weight Stream

    // Systolic Forwarding Outputs
    output reg  signed [7:0]  act_out,
    output reg  signed [7:0]  weight_out,

    // Accumulated Result Output
    output reg  signed [31:0] p_accum
);

    wire signed [15:0] prod = act_in * weight_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_out    <= 8'sd0;
            weight_out <= 8'sd0;
            p_accum    <= 32'sd0;
        end else if (clr_acc) begin
            act_out    <= 8'sd0;
            weight_out <= 8'sd0;
            p_accum    <= 32'sd0;
        end else if (en) begin
            act_out    <= act_in;
            weight_out <= weight_in;
            p_accum    <= p_accum + {{16{prod[15]}}, prod};
        end
    end

endmodule
