
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
    input wire [31:0] a,b,
    input wire[7:0] op,
	output wire y
    );
    assign y = (op == `EXE_BEQ_OP) ? (a ==b):
			(op == `EXE_BNE_OP) ? (a != b):
			(op == `EXE_BGTZ_OP) ? ((a[31] == 1'b0) && (a != `ZeroWord)):
		    (op == `EXE_BLEZ_OP) ? ((a[31] == 1'b1) || (a == `ZeroWord)):
		    ((op == `EXE_BGEZ_OP) || (op == `EXE_BGEZAL_OP))? (a[31] == 1'b0):
		    ((op == `EXE_BLTZ_OP) || (op == `EXE_BLTZAL_OP))? (a[31] == 1'b1):0;
    // wire equal,large0,equal0;
    // assign equal=(rs==rt);
    // assign large0=(rs>0);
    // assign equal0=(rs==0);
    // always@(*)begin
    //     case(op)
    //     `EXE_BEQ_OP:y<=equal;
    //     `EXE_BNE_OP:y<=~equal;
    //     `EXE_BGEZ_OP,`EXE_BGEZAL_OP:y<=large0|equal0;
    //     `EXE_BGTZ_OP:y<=large0;
    //     `EXE_BLEZ_OP:y<=~large0;
    //     `EXE_BLTZ_OP,`EXE_BLTZAL_OP:y<=~large0&~equal0;
    //     endcase
    // end

endmodule
