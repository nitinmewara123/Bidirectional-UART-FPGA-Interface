# Bidirectional UART FPGA Interface

A hardware-in-the-loop system bridging a Basys 3 (Artix-7) FPGA and a host PC via asynchronous serial communication (115200 baud). 

* **PC to FPGA:** A Python script transmits data via COM port to instantly illuminate specific physical LEDs on the FPGA.
* **FPGA to PC:** Physical switch states and button presses on the FPGA are captured, synchronized across clock domains, and transmitted back to the Python script for real-time terminal display.
