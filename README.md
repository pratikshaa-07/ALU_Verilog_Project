# ALU_Verilog_Project

This repository contains a Verilog-based implementation of an Arithmetic Logic Unit (ALU). The ALU supports both arithmetic and logical operations with appropriate status flag generation and input validation. It is designed using sequential logic with a one-cycle delay for most operations and a two-cycle delay for multiplication operations.

## Files Included

- `alu_design.v` – Main ALU module (Verilog)
- `alu_testbench.v` – Testbench for verifying ALU functionality
- `design_document_alu.pdf` – Project report with architecture, working, and waveform explanation
- `normalop.png` – Simulation waveform for normal arithmetic operation
- `mult.png` – Simulation waveform for multiplication operation

## Features

- Parameterized data width
- Supports arithmetic operations: ADD, SUB, INC, DEC, CMP
- Supports logical operations: AND, OR, XOR, NOT, shift, rotate
- Uses `INP_VALID` signal for input validation
- Generates output flags: carry-out, overflow, equal, less, greater, error
- Multiplication operations require one extra clock cycle

## Simulation Notes

- Run the testbench with any Verilog simulator (e.g., ModelSim, Icarus Verilog)
- Most results are available on the second clock cycle after input
- Multiplication results (CMD 9 and 10) appear on the third clock cycle

## Author

Pratiksha Shetty  
B.E. in Electronics and Communication Engineering  
St Joseph Engineering College, Udupi
This project was completed during my internship at **Mirafra Software Technologies**, Manipal.
