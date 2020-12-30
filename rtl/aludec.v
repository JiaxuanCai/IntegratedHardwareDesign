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
			`EXE_SLL:alucontrol <=`EXE_SLL_OP;
			`EXE_SRL:alucontrol <=`EXE_SRL_OP;
			`EXE_SRA:alucontrol <=`EXE_SRA_OP;
			`EXE_SLLV:alucontrol <=`EXE_SLLV_OP;
			`EXE_SRLV:alucontrol <=`EXE_SRLV_OP;
			///////////////////////////////////
			//错误，写错了
			`EXE_SRAV:alucontrol <=`EXE_SRAV_OP;
			//数据移动指令
			`EXE_MFHI:alucontrol <=`EXE_MFHI_OP;
			`EXE_MFLO:alucontrol <=`EXE_MFLO_OP;
			`EXE_MTHI:alucontrol <=`EXE_MTHI_OP;
			`EXE_MTLO:alucontrol <=`EXE_MTLO_OP;


			//算数运算指令
			`EXE_ADD:alucontrol <= `EXE_ADD_OP;
			`EXE_SUB:alucontrol <= `EXE_SUB_OP;
			`EXE_SLT:alucontrol <= `EXE_SLT_OP;
			//分支跳转指令
			//访存指令
			//内陷指令
			//特权指令
			default:alucontrol <= 8'b0;
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
