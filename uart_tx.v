`timescale 1ns/1ps
module uart_tx (
    input wire clk,
    input wire reset,
    input wire tx_tick,        // From baud generator
    input wire tx_start,       // Signal to begin transmission
    input wire [7:0] data_in,  // 8-bit data to send
    output reg tx,             // Serial output bit
    output reg tx_ready        // High when ready to accept new data
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] tx_data_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx <= 1'b1;
            tx_ready <= 1'b1;
            bit_idx <= 3'd0;
            tx_data_reg <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_ready <= 1'b1;
                    if (tx_start) begin
                        tx_data_reg <= data_in;
                        tx <= 1'b0;        // Drive Start Bit (0) immediately
                        tx_ready <= 1'b0;
                        state <= START;
                    end
                end

                START: begin
                    if (tx_tick) begin
                        tx <= tx_data_reg[0]; // Output first data bit (LSB)
                        bit_idx <= 3'd0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (tx_tick) begin
                        if (bit_idx == 3'd7) begin
                            tx <= 1'b1;    // Drive Stop Bit (1)
                            state <= STOP;
                        end else begin
                            tx <= tx_data_reg[bit_idx + 1];
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end

                STOP: begin
                    if (tx_tick) begin
                        tx <= 1'b1;
                        tx_ready <= 1'b1;  // Ready only AFTER full Stop Bit completes
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
