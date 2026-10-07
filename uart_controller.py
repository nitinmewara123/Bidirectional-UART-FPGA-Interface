import serial
import time

PORT = 'COM13' 
BAUD = 115200

try:
    # Set timeout low so the while loop doesn't freeze
    ser = serial.Serial(PORT, BAUD, timeout=0.1)
    ser.setDTR(False)
    ser.setRTS(False)
    time.sleep(2) 

    # 1. Test the LEDs (Output from PC to FPGA)
    # We send 0x55 (ASCII 'U'), which is binary 01010101. 
    # This should light up alternating LEDs on your board.
    test_byte = b'\x55'
    print("Turning on alternating LEDs (01010101)...")
    ser.write(test_byte)
    ser.flush()

    # 2. Listen for the Switches (Input from FPGA to PC)
    print("Listening for FPGA... Flip your switches and press the Top Button! (Press Ctrl+C to stop)")
    
    while True:
        # Check if the FPGA sent anything
        if ser.in_waiting > 0:
            response = ser.read(1)
            
            # Convert the raw byte into integer and binary formats for easy reading
            val = ord(response)
            binary_str = format(val, '08b')
            
            print(f"Button Pressed! Received Binary: {binary_str} | ASCII: {response}")
            
        time.sleep(0.01) # Small delay to prevent the loop from hogging your CPU

except KeyboardInterrupt:
    print("\nExiting program.")
except Exception as e:
    print(f"Error: {e}")
finally:
    if 'ser' in locals() and ser.is_open:
        ser.close()
        print("Port closed safely.")