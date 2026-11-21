// =============================================================================
// Project: Aether-AI Edge SoC
// File:    activation_relu.v
// Description: Rectified Linear Unit (ReLU) and Quantization Post-Processor
//              f(x) = max(0, x), scaled down from 32-bit to 8-bit output
// =============================================================================

`timescale 1ns / 1ps

module activation_relu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable_relu,
    input  wire [3:0]  shift_quant,     // Right shift for quantization (e.g., >> 4)
    input  wire signed [31:0] data_in,
    output reg  [7:0]  data_out
);

    wire signed [31:0] shifted = data_in >>> shift_quant;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'd0;
        end else if (enable_relu) begin
            if (data_in < 32'sd0) begin
                data_out <= 8'd0; // ReLU zeroes negative values
            end else if (shifted > 32'sd255) begin
                data_out <= 8'd255; // Saturation clamp
            end else begin
                data_out <= shifted[7:0];
            end
        end else begin
            // Pass-through without ReLU (Linear activation)
            if (shifted < -32'sd128) begin
                data_out <= 8'h80;
            end else if (shifted > 32'sd127) begin
                data_out <= 8'h7F;
            end else begin
                data_out <= shifted[7:0];
            end
        end
    end

endmodule
