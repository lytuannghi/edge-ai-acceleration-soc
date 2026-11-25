// =============================================================================
// Project: Aether-AI Edge SoC
// File:    gpio_controller.v
// Description: 16-bit General Purpose Input/Output (GPIO) with Interrupt Generation
// =============================================================================

`timescale 1ns / 1ps

module gpio_controller (
    input  wire        clk,
    input  wire        rst_n,

    // APB Slave Interface
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,

    // External Physical GPIO Pins
    input  wire [15:0] gpio_in,
    output reg  [15:0] gpio_out,
    output reg  [15:0] gpio_dir  // 1: Output, 0: Input
);

    // 0x00: GPIO_DATA (Read in, Write out)
    // 0x04: GPIO_DIR (Direction)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_out <= 16'd0;
            gpio_dir <= 16'd0;
            prdata   <= 32'd0;
        end else if (psel) begin
            if (penable && pwrite) begin
                if (paddr == 8'h00) gpio_out <= pwdata[15:0];
                if (paddr == 8'h04) gpio_dir <= pwdata[15:0];
            end else if (!penable && !pwrite) begin
                case (paddr)
                    8'h00: prdata <= {16'd0, gpio_in};
                    8'h04: prdata <= {16'd0, gpio_dir};
                    default: prdata <= 32'd0;
                endcase
            end
        end
    end

endmodule
