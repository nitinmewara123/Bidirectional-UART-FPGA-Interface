`timescale 1ns/1ps

module tb_top();

    // Inputs
    reg clk;
    reg reset;
    reg rx;
    reg [7:0] sw;
    reg btn_send;

    // Outputs
    wire tx;
    wire [7:0] led;

    // Constants based on 100MHz clock and 115200 baud rate
    localparam CLK_PERIOD = 10; // 10ns = 100MHz
    localparam BIT_PERIOD = 8681; // 1 billion ns / 115200 baud ≈ 8681 ns per bit

    // Instantiate the Unit Under Test (UUT)
    top uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .sw(sw),
        .btn_send(btn_send),
        .led(led)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Task to simulate PC sending a UART byte to the FPGA
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            rx = 0; // Start bit
            #(BIT_PERIOD);
            
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i]; // Send data bits LSB first
                #(BIT_PERIOD);
            end
            
            rx = 1; // Stop bit
            #(BIT_PERIOD);
        end
    endtask

    // Test Sequence
    initial begin
        // 1. Initialize Inputs
        reset = 1;
        rx = 1; // UART idle state is HIGH
        sw = 8'b00000000;
        btn_send = 0;

        // Hold reset for 100ns
        #(CLK_PERIOD * 10);
        reset = 0;
        #(CLK_PERIOD * 10);

        $display("--- Starting Bidirectional UART Test ---");

        // -----------------------------------------------------------
        // TEST 1: PC sends data to FPGA (RX Test)
        // -----------------------------------------------------------
        $display("Time: %0t | TEST 1: Simulating PC sending 0x55 to FPGA...", $time);
        send_uart_byte(8'h55); 
        
        // Wait a little extra time for the FSM to settle and LEDs to latch
        #(BIT_PERIOD); 
        
        if (led == 8'h55)
            $display("Time: %0t | SUCCESS: LEDs updated to 8'h55 (01010101)", $time);
        else
            $display("Time: %0t | FAIL: LEDs are %b, expected 01010101", $time, led);


        // -----------------------------------------------------------
        // TEST 2: FPGA sends data to PC (TX Test)
        // -----------------------------------------------------------
        #(BIT_PERIOD * 2); // Wait a bit before next test
        
        $display("Time: %0t | TEST 2: Simulating user setting switches to 0xA3 (10100011) and pressing send...", $time);
        sw = 8'hA3; 
        
        // Wait a few clocks, then press and release the button
        #(CLK_PERIOD * 5);
        btn_send = 1;
        #(CLK_PERIOD * 20); // Hold button down for 20 clock cycles
        btn_send = 0;

        // We must wait for the entire byte to transmit before ending the simulation
        // 1 start bit + 8 data bits + 1 stop bit = 10 bits total
        #(BIT_PERIOD * 12); 

        $display("Time: %0t | TEST 2 Complete. Check the simulation waveform for the TX output.", $time);
        $display("--- Testbench Finished ---");
        
        $finish;
    end

endmodule