// =============================================================================
// Project: Aether-AI Edge SoC
// File:    timer_32bit.v
// Description: 32-bit Real-Time Hardware Countdown Timer with Periodic Interrupt
// =============================================================================

`timescale 1ns / 1ps

module timer_32bit (
    input  wire        clk,
    input  wire        rst_n,

    // APB Slave Interface
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,

    output reg         timer_irq
);

    // 0x00: COUNTER (Current value)
    // 0x04: RELOAD (Reload value)
    // 0x08: CTRL (bit 0: EN, bit 1: AUTO_RELOAD)
    reg [31:0] counter;
    reg [31:0] reload;
    reg [1:0]  ctrl;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= 32'd0;
            reload    <= 32'd0;
            ctrl      <= 2'b00;
            timer_irq <= 1'b0;
            prdata    <= 32'd0;
        end else begin
            timer_irq <= 1'b0;
            if (ctrl[0]) begin // Timer Enabled
                if (counter == 32'd0) begin
                    timer_irq <= 1'b1;
                    counter   <= ctrl[1] ? reload : 32'd0;
                end else begin
                    counter <= counter - 1'b1;
                end
            end

            // APB Read / Write
            if (psel && penable) begin
                if (pwrite) begin
                    if (paddr == 8'h00) counter <= pwdata;
                    if (paddr == 8'h04) reload  <= pwdata;
                    if (paddr == 8'h08) ctrl    <= pwdata[1:0];
                end else begin
                    case (paddr)
                        8'h00: prdata <= counter;
                        8'h04: prdata <= reload;
                        8'h08: prdata <= {30'd0, ctrl};
                        default: prdata <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
