**** 
Goal: Strengthen practical understanding with a hands-on warm-up. 
Write a verilog code 💻 Mini Project #1: 3-Stage Pipelined 32-bit ALU Stage Operation S1 Operand latch (A, B, opcode) S2 Operation execution (add/sub/and/or) S3 Result register.
****


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.11.2025 16:30:16
// Design Name: 
// Module Name: alu_32_bit_3_stage_basic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu_32_bit_3_stage_basic(
input wire clk, rst_n,
input wire [31:0] A, B,
input wire [1:0] opcode,
input wire [4:0] addr,
output reg  [31:0]  result_out,
output reg          valid_out    );

reg [31:0] s1_a,s1_b;
reg [1:0] s1_opcode;
reg [31:0] s2_out;
reg [4:0] s1_addr, s2_addr;
reg [31:0] memory [0:255];

//stage1
always@(posedge clk, negedge rst_n)
if (~rst_n)
begin
  s1_a <= 0;
  s1_b <= 0;
  s1_opcode <= 0;
  s1_addr <= 0;
end
else
begin
  s1_a <= A;
  s1_b <= B;
  s1_opcode <= opcode;
  s1_addr <= addr;
end

//stage2 
always@(posedge clk, negedge rst_n)
if(~rst_n)
begin
 s2_out <= 0;
 s2_addr <= 0;
end
else
begin
  case (s1_opcode)
  2'b00: s2_out <= s1_a & s1_b;
  2'b01: s2_out <= s1_a | s1_b;
  2'b10: s2_out <= s1_a ^ s1_b;
  2'b11: s2_out <= s1_a + s1_b;
  default:
  s2_out <= 32'b0;
  endcase
  s2_addr <= s1_addr;
end

//stage 3
always@(posedge clk, negedge rst_n)
if(~rst_n)
begin
result_out <= 0; 
valid_out <= 0;
end
else
begin
memory[s2_addr] <= s2_out;
result_out <= s2_out; 
//valid_out <= 1'b1;
end

always@(result_out)
begin
valid_out= 1'b1;
end
endmodule

module tb;
reg clk, rst_n;
reg [31:0] A, B;
reg [1:0] opcode;
reg [4:0] addr ;
wire  [31:0]  result_out;
wire          valid_out;
alu_32_bit_3_stage_basic al32_basic (.clk(clk), .rst_n(rst_n), .A(A), .B(B), .opcode(opcode), .addr(addr), .result_out(result_out), .valid_out(valid_out));
initial
begin
clk=1'b0;rst_n=1'b0;
#10;rst_n=1'b1;
end

initial
begin
A=32'd20; B=32'd20; opcode=2'b00; addr=5'b10000;
#50;A=32'd25; B=32'd30; opcode=2'b01; addr=5'b10000;
#50;A=32'd32; B=32'd45; opcode=2'b10; addr=5'b10000;
#50;A=32'd16; B=32'd38; opcode=2'b11; addr=5'b10000;
#400; $finish;
end

always
begin
#5;clk=~clk;
end
endmodule
