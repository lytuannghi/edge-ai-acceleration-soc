// =============================================================================
// Project: Aether-AI Edge SoC
// File:    systolic_array_4x4.v
// Description: 4x4 Systolic Array of 16 Processing Elements for INT8 GEMM
// =============================================================================

`timescale 1ns / 1ps

module systolic_array_4x4 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clr_acc,
    input  wire        en,

    // Activations (Row inputs 0..3)
    input  wire signed [7:0] act_in_0,
    input  wire signed [7:0] act_in_1,
    input  wire signed [7:0] act_in_2,
    input  wire signed [7:0] act_in_3,

    // Weights (Column inputs 0..3)
    input  wire signed [7:0] weight_in_0,
    input  wire signed [7:0] weight_in_1,
    input  wire signed [7:0] weight_in_2,
    input  wire signed [7:0] weight_in_3,

    // 16 Matrix Output Elements (4x4)
    output wire signed [31:0] p_out_00, output wire signed [31:0] p_out_01, output wire signed [31:0] p_out_02, output wire signed [31:0] p_out_03,
    output wire signed [31:0] p_out_10, output wire signed [31:0] p_out_11, output wire signed [31:0] p_out_12, output wire signed [31:0] p_out_13,
    output wire signed [31:0] p_out_20, output wire signed [31:0] p_out_21, output wire signed [31:0] p_out_22, output wire signed [31:0] p_out_23,
    output wire signed [31:0] p_out_30, output wire signed [31:0] p_out_31, output wire signed [31:0] p_out_32, output wire signed [31:0] p_out_33
);

    // Horizontal Activation Forwarding Buses [Row][Col]
    wire signed [7:0] act_wire [0:3][0:4];
    // Vertical Weight Forwarding Buses [Row][Col]
    wire signed [7:0] wgt_wire [0:4][0:3];

    // Assign Initial Inputs
    assign act_wire[0][0] = act_in_0;
    assign act_wire[1][0] = act_in_1;
    assign act_wire[2][0] = act_in_2;
    assign act_wire[3][0] = act_in_3;

    assign wgt_wire[0][0] = weight_in_0;
    assign wgt_wire[0][1] = weight_in_1;
    assign wgt_wire[0][2] = weight_in_2;
    assign wgt_wire[0][3] = weight_in_3;

    // Connect Accumulators to Array Outputs
    wire signed [31:0] p_mat [0:3][0:3];
    assign p_out_00 = p_mat[0][0]; assign p_out_01 = p_mat[0][1]; assign p_out_02 = p_mat[0][2]; assign p_out_03 = p_mat[0][3];
    assign p_out_10 = p_mat[1][0]; assign p_out_11 = p_mat[1][1]; assign p_out_12 = p_mat[1][2]; assign p_out_13 = p_mat[1][3];
    assign p_out_20 = p_mat[2][0]; assign p_out_21 = p_mat[2][1]; assign p_out_22 = p_mat[2][2]; assign p_out_23 = p_mat[2][3];
    assign p_out_30 = p_mat[3][0]; assign p_out_31 = p_mat[3][1]; assign p_out_32 = p_mat[3][2]; assign p_out_33 = p_mat[3][3];

    // Instantiate 16 Processing Elements
    genvar r, c;
    generate
        for (r = 0; r < 4; r = r + 1) begin : GEN_ROW
            for (c = 0; c < 4; c = c + 1) begin : GEN_COL
                pe u_pe_inst (
                    .clk       (clk),
                    .rst_n     (rst_n),
                    .clr_acc   (clr_acc),
                    .en        (en),
                    .act_in    (act_wire[r][c]),
                    .weight_in (wgt_wire[r][c]),
                    .act_out   (act_wire[r][c+1]),
                    .weight_out(wgt_wire[r+1][c]),
                    .p_accum   (p_mat[r][c])
                );
            end
        end
    endgenerate

endmodule
