`timescale 1ns/1ps
module top (
    input wire clk,
    input wire reset,
    input wire rx,
    output wire tx,
    input wire [7:0] sw,         // 8 Physical Switches
    input wire btn_send,         // Top Button to trigger TX
    output reg [7:0] led         // 8 Physical LEDs
);

    wire tick;
    wire rx_done;
    wire [7:0] rx_data_out;
    wire tx_ready;

    // --- BUTTON EDGE DETECTOR ---
    // Converts a physical button press into a single 1-clock-cycle pulse
    reg btn_sync_0, btn_sync_1, btn_prev;
    always @(posedge clk) begin
        btn_sync_0 <= btn_send;
        btn_sync_1 <= btn_sync_0;
        btn_prev   <= btn_sync_1;
    end
    wire send_pulse = (btn_sync_1 & ~btn_prev); // High for exactly 1 clock cycle

    // --- LED OUTPUT LATCH ---
    // When UART receives a byte, latch it to the physical LEDs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 8'b0;
        end else if (rx_done) begin
            led <= rx_data_out;
        end
    end

    // --- INSTANTIATE MODULES ---
    baud_gen #(.CLK_FREQ(100000000), .BAUD_RATE(115200)) u_baud (
        .clk(clk), .reset(reset), .tx_tick(tick)
    );

    uart_rx u_rx (
        .clk(clk), .reset(reset), .rx(rx), .rx_tick(tick),
        .data_out(rx_data_out), .rx_done(rx_done)
    );

    uart_tx u_tx (
        .clk(clk), .reset(reset), .tx_tick(tick),
        .tx_start(send_pulse),   // Start TX when the Top Button is pressed
        .data_in(sw),            // Grab data directly from the 8 switches
        .tx(tx),
        .tx_ready(tx_ready)
    );

endmodule