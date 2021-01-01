`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 03:12:39
// Design Name: 
// Module Name: memInsDecode
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

//参考https://github.com/JF2098/A-simple-MIPS-CPU/tree/master/rtl
module memInsDecode(
    input wire[7:0]op,
    input wire[1:0]endOfAddr,
    input wire[31:0]readdata,writedata,
    output reg[31:0]readdataOut,writedataOut,
    output reg[3:0]readEn,writeEn,
    output reg read_addr_error,wirte_addr_error
    );
    always@(*)begin
        readEn<=4'b0;writeEn<=4'b0;
        case(op)
            `EXE_LW_OP:if(endOfAddr==2'b00)readEn<=4'b1111;
            `EXE_LH_OP,`EXE_LHU_OP:begin
                if(endOfAddr==2'b00)readEn<=4'b0011;
                else if(endOfAddr==2'b10)readEn<=4'b1100;
            end
            `EXE_LB_OP,`EXE_LBU_OP:begin
                if(endOfAddr==2'b00)readEn<=4'b0001;
                else if(endOfAddr==2'b01)readEn<=4'b0010;
                else if(endOfAddr==2'b10)readEn<=4'b0100;
                else if(endOfAddr==2'b11)readEn<=4'b1000;
            end

            `EXE_SW_OP:if(endOfAddr==2'b00)writeEn<=4'b1111;
            `EXE_SH_OP:begin
                if(endOfAddr==2'b00)writeEn<=4'b0011;
                else if(endOfAddr==2'b10)writeEn<=4'b1100;
            end
            `EXE_SB_OP:begin
                if(endOfAddr==2'b00)writeEn<=4'b0001;
                else if(endOfAddr==2'b01)writeEn<=4'b0010;
                else if(endOfAddr==2'b10)writeEn<=4'b0100;
                else if(endOfAddr==2'b11)writeEn<=4'b1000;
            end
        endcase
    end
    always@(*)begin
        readdataOut<=32'b0;writedataOut<=32'b0;
        case(op)
            `EXE_LW_OP:if(endOfAddr==2'b00)readdataOut<=readdata;
            `EXE_LH_OP:begin
                if(endOfAddr==2'b00)readdataOut<={{16{readdata[15]}},readdata[15:0]};
                else if(endOfAddr==2'b10)readdataOut<={{16{readdata[31]}},readdata[31:16]};
            end
            `EXE_LHU_OP:begin
                if(endOfAddr==2'b00)readdataOut<={16'b0,readdata[15:0]};
                else if(endOfAddr==2'b10)readdataOut<={16'b0,readdata[31:16]};
            end
            `EXE_LB_OP:begin
                if(endOfAddr==2'b00)readdataOut<={{24{readdata[7]}},readdata[7:0]};
                else if(endOfAddr==2'b01)readdataOut<={{24{readdata[15]}},readdata[15:8]};
                else if(endOfAddr==2'b10)readdataOut<={{24{readdata[23]}},readdata[23:16]};
                else if(endOfAddr==2'b11)readdataOut<={{24{readdata[31]}},readdata[31:24]};
            end
            //错误：没有加U
            `EXE_LBU_OP:begin
                if(endOfAddr==2'b00)readdataOut<={24'b0,readdata[7:0]};
                else if(endOfAddr==2'b01)readdataOut<={24'b0,readdata[15:8]};
                else if(endOfAddr==2'b10)readdataOut<={24'b0,readdata[23:16]};
                else if(endOfAddr==2'b11)readdataOut<={24'b0,readdata[31:24]};
            end

            `EXE_SW_OP:writedataOut<=writedata;
            `EXE_SH_OP:writedataOut<={writedata[15:0], writedata[15:0]};
            `EXE_SB_OP:writedataOut<={writedata[7:0], writedata[7:0],writedata[7:0],writedata[7:0]};
        endcase
    end
    always@(*)begin
        read_addr_error<=((op == `EXE_LH_OP || op == `EXE_LHU_OP) && endOfAddr[0]) 
        || (op == `EXE_LW_OP && endOfAddr != 2'b00);
        wirte_addr_error<=(op == `EXE_SH_OP & endOfAddr[0]) | (op == `EXE_SW_OP & endOfAddr != 2'b00);
    end
    







endmodule
