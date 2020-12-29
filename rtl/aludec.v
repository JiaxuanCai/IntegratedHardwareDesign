`timescale 1ns / 1ps
`include "defines.vh"
module aludec(
	input wire [5:0]op,
	input wire[5:0] funct,
	output reg[7:0] alucontrol
    );
	always @(*) begin
		if(op==`EXE_NOP)begin
			case(funct)
			//TODO

			//逻辑运算指令
			`EXE_AND:alucontrol <= `EXE_AND_OP;
			`EXE_OR:alucontrol <=`EXE_OR_OP;
			`EXE_XOR:alucontrol <=`EXE_XOR_OP;
			`EXE_NOR:alucontrol <=`EXE_NOR_OP;
			//移位指令
			//数据移动指令
			//算数运算指令
			`EXE_ADD:alucontrol <= `EXE_ADD_OP;
			`EXE_SUB:alucontrol <= `EXE_SUB_OP;
			`EXE_SLT:alucontrol <= `EXE_SLT_OP;
			//分支跳转指令
			//访存指令
			//内陷指令
			//特权指令
			default:alucontrol <= 9'b0000000;
		endcase
		end
		else begin
			case (op)
			//逻辑运算指令
			`EXE_ANDI:alucontrol <= `EXE_ANDI_OP;
			`EXE_XORI:alucontrol <= `EXE_XORI_OP;
			`EXE_LUI:alucontrol <= `EXE_LUI_OP;
			`EXE_ORI:alucontrol <= `EXE_ORI_OP;
			//移位指令
			//数据移动指令
			//算数运算指令
			`EXE_ADDI:alucontrol <= `EXE_ADDI_OP;
			
			//分支跳转指令
			`EXE_BEQ:alucontrol <= `EXE_BEQ_OP;
			`EXE_J:alucontrol <= `EXE_J_OP;
			//访存指令
			`EXE_LW:alucontrol <= `EXE_LW_OP;
			`EXE_SW:alucontrol <= `EXE_SW_OP;
			//内陷指令
			//特权指令
			default:  alucontrol <= 9'b0000000;
		endcase
		end
	end
endmodule
