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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.11.2025 06:55:27
// Design Name: 
// Module Name: alu_32_bit_3_stage_hazard
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


module alu_32_bit_3_stage_hazard
#(
    parameter ENABLE_FORWARDING = 1  // set 0 to disable forwarding and force stalls on RAW
)
(
    input clk, rst,
    input  wire        valid_in,
    input  wire [4:0] A,
    input  wire [4:0] B,
    input  wire [1:0]  opcode,
    input  wire [4:0]  dest,

    // Output interface
    output wire [31:0] result_out,
    output wire        valid_out,
    output wire [4:0]  dest_out,
    
    // Stall info
    output wire        stall_out
    );

    // ---------------------------------------------------------
    // Simple register file (32 x 32b)
    // - synchronous writeback from S3 (on posedge)
    // - asynchronous combinational read for src IDs
    // ---------------------------------------------------------
    reg [31:0] regfile [31:0];
    integer i;
    // initialize regfile (optional)
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regfile[i] = i;
    end

    wire [31:0] rf_read_A, rf_read_B;
    assign rf_read_A = (A == 5'd0) ? 32'b0 : regfile[A];
    assign rf_read_B  = (B == 5'd0) ? 32'b0 : regfile[B];
    
    
    //==============================================================
    // Stage-1 Registers
    //==============================================================
    reg        s12_valid;
    reg [4:0] s12_a, s12_b;
    reg [1:0]  s12_opcode;
    reg [4:0]  s12_dest;
    reg  [31:0] val_s12_a, val_s12_b;


    //==============================================================
    // Stage-2 Registers
    //==============================================================
    reg        s23_valid;
    reg [31:0] val_s23_a, val_s23_b;
    reg [1:0]  s23_opcode;
    reg [4:0]  s23_dest;

    //==============================================================
    // Stage-3 Registers
    //==============================================================
    reg        s34_valid;
    reg [4:0]  s34_dest;
    reg [31:0] alu_s34_reg;
    // ---------------------------------------------------------
    // Hazard Detection (RAW)
    // Compare incoming source IDs (A_id_in, B_id_in) with dests in S2 & S3.
    // These are ID comparisons (5-bit).
    // ---------------------------------------------------------    
    wire hazard_s2_A = s23_valid && (s23_dest != 5'd0) && (s23_dest == A);
    wire hazard_s2_B = s23_valid && (s23_dest != 5'd0) && (s23_dest == B);
    wire hazard_s3_A = s34_valid && (s34_dest != 5'd0) && (s34_dest == A);
    wire hazard_s3_B = s34_valid && (s34_dest != 5'd0) && (s34_dest == B);

    wire raw_hazard = (hazard_s2_A | hazard_s2_B | hazard_s3_A | hazard_s3_B);


    // -------------------------------------------------------------------------------------------------------
    // ALU logic -> we are calculating it here because, as soon as s2_reg gets updated, alu_ex got calculated
    // -------------------------------------------------------------------------------------------------------
    wire [31:0] alu_ex;
    assign alu_ex = (s23_opcode == 2'b00) ? (val_s23_a + val_s23_b) :
                    (s23_opcode == 2'b01) ? (val_s23_a - val_s23_b) :
                    (s23_opcode == 2'b10) ? (val_s23_a & val_s23_b) :
                                            (val_s23_a | val_s23_b);
    // ---------------------------------------------------------
    // Forwarding (bypass) logic:
    // If ENABLE_FORWARDING==1, we prefer:
    //   1) forward from EX (alu_ex) if dest_s2 matches the source ID (most recent)
    //   2) else forward from S3 (alu_s3_reg) if dest_s3 matches the source ID
    //   3) else use value read from regfile
    // ---------------------------------------------------------
    wire [31:0] A_forwarded = (ENABLE_FORWARDING && hazard_s2_A) ? alu_ex :
                              (ENABLE_FORWARDING && hazard_s3_A) ? alu_s34_reg :
                              rf_read_A;

    wire [31:0] B_forwarded = (ENABLE_FORWARDING && hazard_s2_B) ? alu_ex :
                              (ENABLE_FORWARDING && hazard_s3_B) ? alu_s34_reg :
                              rf_read_B;

    // RAW Hazard Detection (no forwarding)
    // IF: A/B of new instruction == dest register in S2 or S3
    
    assign stall_out = (ENABLE_FORWARDING) ? 1'b0 : raw_hazard;

//STAGE 1 
always@(posedge clk, posedge rst)
  begin
        if (rst) begin
            s12_valid <= 0;
        end
        else if (!stall_out) begin
            s12_valid  <= valid_in;
            s12_a      <= A;
            s12_b      <= B;
            s12_opcode <= opcode;
            s12_dest   <= dest;
            val_s12_a  <= A_forwarded;
            val_s12_b  <= B_forwarded;
        end
  end

// STAGE 2  
always@(posedge clk, posedge rst)
  begin
       if (rst)
        begin
        s23_valid <= 1'b0;
        val_s23_a <= 32'b0;
        val_s23_b <= 32'b0;
        s23_opcode <= 2'b0;
        s23_dest <= 5'b0;
        end
       else
        begin
        s23_valid <= s12_valid;
        s23_dest <= s12_dest;
        s23_opcode <= s12_opcode;
        val_s23_a  <= val_s12_a;
        val_s23_b  <= val_s12_b;
        end
  end

// STAGE 3
always@(posedge clk, posedge rst)
begin
  if(rst)
    begin
    s34_valid <= 1'b0;
    s34_dest <= 5'b0;
    alu_s34_reg <= 32'b0;
    end
  else
    begin
    s34_valid <= s23_valid;
    s34_dest <= s23_dest;
    alu_s34_reg <= alu_ex;
    end
end

    // Write-back: synchronous write to regfile from S3 (on posedge)
    // Ensure register 0 remains zero
    always @(posedge clk or posedge rst) 
    begin
        if (rst) begin
            // clear regfile optionally (we did initial block above as well)
            for (i = 0; i < 32; i = i + 1)
                regfile[i] <= 32'd0;
        end else begin
            if (s34_valid && (s34_dest != 5'd0)) begin
                regfile[s34_dest] <= alu_s34_reg;
            end
            // regfile[0] remains zero implicitly if not written (dest==0 skips)
        end
    end

    assign result_out = alu_s34_reg;
    assign valid_out  = s34_valid;
    assign dest_out   = s34_dest;
    
endmodule


module tb_alu_32_bit_hazard;
reg clk, rst;
reg valid_in;
reg [4:0] A ;
reg [4:0] B ;
reg [1:0]  opcode ;
reg [4:0]  dest ;
wire [31:0] result_out;
wire valid_out;
wire [4:0] dest_out;

alu_32_bit_3_stage_hazard alu_tb_hz1 (.dest_out(dest_out), .valid_out(valid_out), .dest(dest), .result_out(result_out), .clk(clk), .rst(rst), .valid_in(valid_in), .A(A), .B(B), .opcode(opcode) );
initial
begin
clk=1'b0; rst=1'b1;
#10; rst=1'b0;
end

always
begin
#5; clk = ~clk;
end


initial
begin
valid_in=1'b1; A=5'd10; B=5'd20; opcode=2'b00; dest=5'd30;
#50;valid_in=1'b1; A=5'd15; B=5'd20; opcode=2'b01; dest=5'd16;
#50;valid_in=1'b1; A=5'd8; B=5'd16; opcode=2'b10; dest=5'd9;
#50;valid_in=1'b1; A=5'd5; B=5'd18; opcode=2'b10; dest=5'd28;
#500;$finish;
end

endmodule

