`timescale 1ns / 1ps
`include "defines.vh"
//`include "defines2.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 05:19:22
// Design Name: 
// Module Name: exception
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

/*
    异常解析模块，实现例外错误类型，确定异常处理跳转地址
*/

module exception(
    input wire rst,

    input wire cp0weW,
    input wire [7:0] exceptionM,
    input wire [31:0] wdataW,
    input wire [4:0] waddrW,
    
    input wire adelM,
    input wire adesM,

    input wire [31:0]cp0_statusW, cp0_causeW,cp0_epcW,
    output wire [31:0]except_typeM,newPcM
    );

    wire [31:0] cp0_status, cp0_cause, cp0_epc;

    assign cp0_status = (cp0weW & (waddrW == `CP0_REG_STATUS))? wdataW:
                        cp0_statusW;
    assign cp0_cause = (cp0weW & (waddrW == `CP0_REG_CAUSE))? wdataW:
                        cp0_causeW;
    assign cp0_epc = (cp0weW & (waddrW == `CP0_REG_EPC))? wdataW:
                        cp0_epcW;


    //异常类型的解析
    //0103错误日志：连线的时连出了eret，这里解析的时候漏了，导致Z错误
    assign except_typeM = (rst)? 32'b0:
                    (((cp0_causeW[15:8] & cp0_statusW[15:8]) != 8'h00) && (cp0_statusW[1] == 1'b0) && (cp0_statusW[0] == 1'b1))? 32'h00000001: //int
                    (exceptionM[6] == 1'b1 | adelM)? 32'h00000004://adel
                    (adesM)? 32'h00000005: //ades
                    (exceptionM[4] == 1'b1)? 32'h00000008: //syscall
                    (exceptionM[3] == 1'b1)? 32'h00000009: //break
                    (exceptionM[2] == 1'b1)? 32'h0000000e: //eret
                    (exceptionM[1] == 1'b1)? 32'h0000000a: //ri
                    (exceptionM[0] == 1'b1)? 32'h0000000c: //ov
                    32'h0;
    
    //确定异常处理跳转的PCNew
    assign newPcM = (except_typeM == `EXCEPT_TYPE_INT) ? `EXCEPT_ENTRY:
                    (except_typeM == `EXCEPT_TYPE_AdEL) ? `EXCEPT_ENTRY:
                    (except_typeM == `EXCEPT_TYPE_AdES) ? `EXCEPT_ENTRY:
                    (except_typeM == `EXCEPT_TYPE_SYSCALL) ? `EXCEPT_ENTRY:
                    (except_typeM == `EXCEPT_TYPE_BREAK) ? `EXCEPT_ENTRY:
                    (except_typeM == `EXCEPT_TYPE_RI) ? `EXCEPT_ENTRY:
                    (except_typeM == `EXCEPT_TYPE_Ov) ? `EXCEPT_ENTRY:
                    (except_typeM == `EXCEPT_TYPE_ERET) ? cp0_epc:
                    32'b0;
endmodule