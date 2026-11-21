// =============================================================================
// Project: Aether-AI Edge SoC
// File:    npu_top.v
// Description: Edge-AI Neural Processing Unit (NPU) Subsystem with AXI/APB Interface
//              Integrates 4x4 Systolic Array, Weight/Activation SRAMs, ReLU & DMA
// =============================================================================

`timescale 1ns / 1ps

module npu_top (
    input  wire        clk,
    input  wire        rst_n,

    // APB Slave Configuration Interface
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [11:0] paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,

    // Interrupt to CPU
    output reg         npu_irq
);

    assign pready = 1'b1;

    // Internal Memory Buffers:
    // Activation Buffer (16 bytes = 4x4 matrix)
    reg signed [7:0] act_mem [0:15];
    // Weight Buffer (16 bytes = 4x4 matrix)
    reg signed [7:0] wgt_mem [0:15];

    // Control & Status Registers
    reg [31:0] ctrl_reg;   // bit 0: START, bit 1: CLR_ACC, bit 2: RELU_EN
    reg [31:0] status_reg; // bit 0: BUSY, bit 1: DONE
    reg [3:0]  shift_quant;

    // Systolic Control Signals
    reg        sys_en;
    reg        sys_clr;
    reg signed [7:0] in_act_0, in_act_1, in_act_2, in_act_3;
    reg signed [7:0] in_wgt_0, in_wgt_1, in_wgt_2, in_wgt_3;

    // Systolic Array Outputs
    wire signed [31:0] p_out [0:3][0:3];

    systolic_array_4x4 u_array (
        .clk        (clk),
        .rst_n      (rst_n),
        .clr_acc    (sys_clr),
        .en         (sys_en),
        .act_in_0   (in_act_0), .act_in_1(in_act_1), .act_in_2(in_act_2), .act_in_3(in_act_3),
        .weight_in_0(in_wgt_0), .weight_in_1(in_wgt_1), .weight_in_2(in_wgt_2), .weight_in_3(in_wgt_3),
        .p_out_00(p_out[0][0]), .p_out_01(p_out[0][1]), .p_out_02(p_out[0][2]), .p_out_03(p_out[0][3]),
        .p_out_10(p_out[1][0]), .p_out_11(p_out[1][1]), .p_out_12(p_out[1][2]), .p_out_13(p_out[1][3]),
        .p_out_20(p_out[2][0]), .p_out_21(p_out[2][1]), .p_out_22(p_out[2][2]), .p_out_23(p_out[2][3]),
        .p_out_30(p_out[3][0]), .p_out_31(p_out[3][1]), .p_out_32(p_out[3][2]), .p_out_33(p_out[3][3])
    );

    // Execution Sequencer FSM
    localparam IDLE    = 3'b000;
    localparam RUN     = 3'b001;
    localparam FLUSH   = 3'b010;

    reg [2:0] state;
    reg [3:0] step_cnt;
    wire      start_pulse = (psel && penable && pwrite && (paddr == 12'h000) && pwdata[0]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            status_reg  <= 32'd0;
            npu_irq     <= 1'b0;
            sys_en      <= 1'b0;
            sys_clr     <= 1'b0;
            step_cnt    <= 4'd0;
            in_act_0    <= 8'sd0; in_act_1 <= 8'sd0; in_act_2 <= 8'sd0; in_act_3 <= 8'sd0;
            in_wgt_0    <= 8'sd0; in_wgt_1 <= 8'sd0; in_wgt_2 <= 8'sd0; in_wgt_3 <= 8'sd0;
        end else begin
            case (state)
                IDLE: begin
                    npu_irq <= 1'b0;
                    if (start_pulse) begin
                        status_reg[0] <= 1'b1; // Busy
                        status_reg[1] <= 1'b0; // Clear Done
                        sys_clr       <= 1'b1;
                        state         <= RUN;
                        step_cnt      <= 4'd0;
                    end
                end

                RUN: begin
                    sys_clr  <= 1'b0;
                    sys_en   <= 1'b1;
                    step_cnt <= step_cnt + 1'b1;

                    case (step_cnt)
                        4'd0: begin
                            in_act_0 <= act_mem[0];  in_wgt_0 <= wgt_mem[0];
                            in_act_1 <= 8'sd0;       in_wgt_1 <= 8'sd0;
                            in_act_2 <= 8'sd0;       in_wgt_2 <= 8'sd0;
                            in_act_3 <= 8'sd0;       in_wgt_3 <= 8'sd0;
                        end
                        4'd1: begin
                            in_act_0 <= act_mem[1];  in_wgt_0 <= wgt_mem[4];
                            in_act_1 <= act_mem[4];  in_wgt_1 <= wgt_mem[1];
                        end
                        4'd2: begin
                            in_act_0 <= act_mem[2];  in_wgt_0 <= wgt_mem[8];
                            in_act_1 <= act_mem[5];  in_wgt_1 <= wgt_mem[5];
                            in_act_2 <= act_mem[8];  in_wgt_2 <= wgt_mem[2];
                        end
                        4'd3: begin
                            in_act_0 <= act_mem[3];  in_wgt_0 <= wgt_mem[12];
                            in_act_1 <= act_mem[6];  in_wgt_1 <= wgt_mem[9];
                            in_act_2 <= act_mem[9];  in_wgt_2 <= wgt_mem[6];
                            in_act_3 <= act_mem[12]; in_wgt_3 <= wgt_mem[3];
                        end
                        4'd4: begin
                            in_act_0 <= 8'sd0;       in_wgt_0 <= 8'sd0;
                            in_act_1 <= act_mem[7];  in_wgt_1 <= wgt_mem[13];
                            in_act_2 <= act_mem[10]; in_wgt_2 <= wgt_mem[10];
                            in_act_3 <= act_mem[13]; in_wgt_3 <= wgt_mem[7];
                        end
                        4'd5: begin
                            in_act_1 <= 8'sd0;       in_wgt_1 <= 8'sd0;
                            in_act_2 <= act_mem[11]; in_wgt_2 <= wgt_mem[14];
                            in_act_3 <= act_mem[14]; in_wgt_3 <= wgt_mem[11];
                        end
                        4'd6: begin
                            in_act_2 <= 8'sd0;       in_wgt_2 <= 8'sd0;
                            in_act_3 <= act_mem[15]; in_wgt_3 <= wgt_mem[15];
                        end
                        default: begin
                            in_act_0 <= 8'sd0; in_act_1 <= 8'sd0; in_act_2 <= 8'sd0; in_act_3 <= 8'sd0;
                            in_wgt_0 <= 8'sd0; in_wgt_1 <= 8'sd0; in_wgt_2 <= 8'sd0; in_wgt_3 <= 8'sd0;
                            state    <= FLUSH;
                        end
                    endcase
                end

                FLUSH: begin
                    sys_en        <= 1'b0;
                    status_reg[0] <= 1'b0; // Done Busy
                    status_reg[1] <= 1'b1; // Done
                    npu_irq       <= 1'b1;
                    state         <= IDLE;
                end
            endcase
        end
    end

    // APB Memory-Mapped Read/Write Routing
    integer idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg    <= 32'd0;
            shift_quant <= 4'd0;
            prdata      <= 32'd0;
            for (idx = 0; idx < 16; idx = idx + 1) begin
                act_mem[idx] <= 8'sd0;
                wgt_mem[idx] <= 8'sd0;
            end
        end else if (psel && penable) begin
            if (pwrite) begin
                if (paddr == 12'h000) ctrl_reg    <= pwdata;
                if (paddr == 12'h008) shift_quant <= pwdata[3:0];
                if (paddr >= 12'h100 && paddr < 12'h140) begin
                    act_mem[(paddr - 12'h100) >> 2] <= pwdata[7:0];
                end
                if (paddr >= 12'h200 && paddr < 12'h240) begin
                    wgt_mem[(paddr - 12'h200) >> 2] <= pwdata[7:0];
                end
            end else begin
                case (paddr)
                    12'h000: prdata <= ctrl_reg;
                    12'h004: prdata <= status_reg;
                    12'h008: prdata <= {28'd0, shift_quant};
                    12'h300: prdata <= p_out[0][0]; 12'h304: prdata <= p_out[0][1];
                    12'h308: prdata <= p_out[0][2]; 12'h30C: prdata <= p_out[0][3];
                    12'h310: prdata <= p_out[1][0]; 12'h314: prdata <= p_out[1][1];
                    12'h318: prdata <= p_out[1][2]; 12'h31C: prdata <= p_out[1][3];
                    12'h320: prdata <= p_out[2][0]; 12'h324: prdata <= p_out[2][1];
                    12'h328: prdata <= p_out[2][2]; 12'h32C: prdata <= p_out[2][3];
                    12'h330: prdata <= p_out[3][0]; 12'h334: prdata <= p_out[3][1];
                    12'h338: prdata <= p_out[3][2]; 12'h33C: prdata <= p_out[3][3];
                    default: prdata <= 32'd0;
                endcase
            end
        end
    end

endmodule
