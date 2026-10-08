`timescale 1ns/1ps
module uart_rx (
    input wire clk,
    input wire reset,
    input wire rx,             
    input wire rx_tick, 
    output reg [7:0] data_out, 
    output reg rx_done         
);

    // FSM States
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] s_cnt;           // 16x oversampling counter
    reg [2:0] bit_idx;
    reg [7:0] rx_shift_reg;
    reg rx_sync_0, rx_sync_1;

    // Synchronize asynchronous RX line to prevent metastability
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end else begin
            rx_sync_0 <= rx;
            rx_sync_1 <= rx_sync_0;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            s_cnt <= 4'b0;
            bit_idx <= 3'b0;
            rx_shift_reg <= 8'b0;
            data_out <= 8'b0;
            rx_done <= 1'b0;
        end else begin
            rx_done <= 1'b0; // Default pulse low
            
            case (state)
                IDLE: begin
                    if (~rx_sync_1) begin // Detect start bit (falling edge)
                        state <= START;
                        s_cnt <= 4'd0;
                    end
                end

                START: begin
                    if (rx_tick) begin
                        if (s_cnt == 4'd7) begin // Sample at the 8th tick (middle)
                            if (~rx_sync_1) begin
                                state <= DATA;
                                s_cnt <= 4'd0;
                                bit_idx <= 3'd0;
                            end else begin
                                state <= IDLE; // False start, glitch ignored
                            end
                        end else begin
                            s_cnt <= s_cnt + 1;
                        end
                    end
                end

                DATA: begin
                    if (rx_tick) begin
                        if (s_cnt == 4'd15) begin // 16 ticks later (middle of next bit)
                            rx_shift_reg[bit_idx] <= rx_sync_1; 
                            s_cnt <= 4'd0;
                            if (bit_idx == 3'd7) begin
                                state <= STOP;
                            end else begin
                                bit_idx <= bit_idx + 1;
                            end
                        end else begin
                            s_cnt <= s_cnt + 1;
                        end
                    end
                end

                STOP: begin
                    if (rx_tick) begin
                        if (s_cnt == 4'd15) begin // Middle of stop bit
                            data_out <= rx_shift_reg;
                            rx_done <= 1'b1;
                            state <= IDLE;
                        end else begin
                            s_cnt <= s_cnt + 1;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
