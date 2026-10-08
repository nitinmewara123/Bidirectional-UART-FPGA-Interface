`timescale 1ns/1ps
module baud_gen #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire reset,
    output wire tx_tick,  // 1x Baud rate for transmitter
    output wire rx_tick   // 16x Baud rate for receiver oversampling
);

    localparam TX_MAX = CLK_FREQ / BAUD_RATE;
    localparam RX_MAX = CLK_FREQ / (BAUD_RATE * 16);

    reg [31:0] tx_reg;
    reg [31:0] rx_reg;

    assign tx_tick = (tx_reg == TX_MAX - 1);
    assign rx_tick = (rx_reg == RX_MAX - 1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_reg <= 0;
            rx_reg <= 0;
        end else begin
            tx_reg <= (tx_reg == TX_MAX - 1) ? 0 : tx_reg + 1;
            rx_reg <= (rx_reg == RX_MAX - 1) ? 0 : rx_reg + 1;
        end
    end
endmodule
