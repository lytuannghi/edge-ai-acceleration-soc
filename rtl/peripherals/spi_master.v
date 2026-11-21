// =============================================================================
// Project: Aether-AI Edge SoC
// File:    spi_master.v
// Description: 4-Wire SPI Master Controller for Camera / Sensor Ingestion
// =============================================================================

`timescale 1ns / 1ps

module spi_master (
    input  wire        clk,
    input  wire        rst_n,

    // APB Slave Interface
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,

    // Physical SPI Pins
    output reg         spi_sck,
    output reg         spi_mosi,
    input  wire        spi_miso,
    output reg         spi_cs_n
);

    // Register 0x00: DATA (TX write, RX read)
    // Register 0x04: STATUS (bit 0: BUSY)
    reg [7:0] tx_buf;
    reg [7:0] rx_buf;
    reg       busy;
    reg [2:0] state;
    reg [2:0] bit_cnt;
    reg [3:0] clk_div;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_sck   <= 1'b0;
            spi_mosi  <= 1'b0;
            spi_cs_n  <= 1'b1;
            busy      <= 1'b0;
            state     <= 3'd0;
            bit_cnt   <= 3'd0;
            clk_div   <= 4'd0;
            tx_buf    <= 8'd0;
            rx_buf    <= 8'd0;
            prdata    <= 32'd0;
        end else begin
            if (psel && penable && pwrite && (paddr == 8'h00) && !busy) begin
                tx_buf   <= pwdata[7:0];
                busy     <= 1'b1;
                spi_cs_n <= 1'b0;
                bit_cnt  <= 3'd7;
                state    <= 3'd1;
            end else if (psel && penable && !pwrite) begin
                if (paddr == 8'h00) prdata <= {24'd0, rx_buf};
                else if (paddr == 8'h04) prdata <= {31'd0, busy};
            end

            // SPI Bit Transfer Engine
            case (state)
                3'd1: begin // Setup MOSI
                    spi_mosi <= tx_buf[bit_cnt];
                    spi_sck  <= 1'b0;
                    state    <= 3'd2;
                end
                3'd2: begin // Clock High and Sample MISO
                    spi_sck            <= 1'b1;
                    rx_buf[bit_cnt]    <= spi_miso;
                    if (bit_cnt == 3'd0) state <= 3'd3;
                    else begin
                        bit_cnt <= bit_cnt - 1'b1;
                        state   <= 3'd1;
                    end
                end
                3'd3: begin // Transaction Finish
                    spi_sck  <= 1'b0;
                    spi_cs_n <= 1'b1;
                    busy     <= 1'b0;
                    state    <= 3'd0;
                end
            endcase
        end
    end

endmodule
