
`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 03:23:42
// Design Name: 
// Module Name: BranchDec
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


module BranchDec(
    input wire [31:0] rs,rt,
    input wire[7:0] op,
	output reg y
    );
    wire equal,large0,equal0;
    assign equal=(rs==rt);
    assign large0=(rs>0);
    assign equal0=(rs==0);
    always@(*)begin
        case(op)
        `EXE_BEQ_OP:y<=equal;
        `EXE_BNE_OP:y<=~equal;
        `EXE_BGEZ_OP,`EXE_BGEZAL_OP:y<=large0|equal0;
        `EXE_BGTZ_OP:y<=large0;
        `EXE_BLEZ_OP:y<=~large0;
        `EXE_BLTZ_OP,`EXE_BLTZAL_OP:y<=~large0&~equal0;
        endcase
    end

endmodule
