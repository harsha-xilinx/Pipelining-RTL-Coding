/*Goal: Strengthen practical understanding with a hands-on warm-up. Write a verilog code 
💻 Mini Project #1: 3-Stage Pipelined 32-bit ALU
Stage	Operation
S1	Operand latch (A, B, opcode)
S2	Operation execution (add/sub/and/or)
S3	Result register

✅ Add hazard detection:
Stall when dependent instruction needs result from previous stage.
Optional: implement simple forwarding (bypass path).

Register insertion strategy.
Pipeline valid/stall handshake.
Timing improvement visualization.
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
dest_in - register used to store value after computation
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
