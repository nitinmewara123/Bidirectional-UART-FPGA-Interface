`timescale 1ns/1ps
module baud_gen #(
    parameter CLK_FREQ = 100000000, // Basys 3 master clock: 100 MHz
    parameter BAUD_RATE = 115200    // Target baud rate
)(
    input wire clk,
    input wire reset,
    output reg tx_tick
);
    // Calculate the divider needed. 100MHz / 115200 = 868
    localparam MAX_COUNT = CLK_FREQ / BAUD_RATE;
    reg [15:0] counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            tx_tick <= 0;
        end else if (counter == MAX_COUNT - 1) begin
            counter <= 0;
            tx_tick <= 1'b1;
        end else begin
            counter <= counter + 1;
            tx_tick <= 1'b0;
        end
    end
endmodule