`timescale 1ns / 1ps
`include "defines.vh"
/////////////////////////////////
//alu辅助了一部分controller的逻辑
module alu(
	input wire[31:0] a,b,//第一个操作数和第二个操作数（rs、rt）（rs，imm）
	input wire[7:0] op,
	input wire[4:0] sa,
	output reg[31:0] y,
	input wire[31:0] HiInput,LoInput,
	output reg [31:0] HiOutput,LoOutput,

	
	output reg overflow,
	output wire zero
    );

	wire[31:0] s,bout;
	wire subfunc;
	assign subfunc=op==`EXE_SUB_OP|op==`EXE_SLT_OP;
	assign bout = subfunc ? ~b : b;
	assign s = a + bout + subfunc;
	always @(*) begin
		HiOutput<=HiInput;
		LoOutput<=LoOutput;
		case(op)
			//逻辑运算指令
			`EXE_AND_OP,`EXE_ANDI_OP:y<=a&b;
			`EXE_OR_OP,`EXE_ORI_OP:y<=a|b;
			`EXE_XOR_OP,`EXE_XORI_OP:y<=a^b;
			`EXE_NOR_OP:y<=~(a|b);
			`EXE_LUI_OP:y<={b[15:0],16'b0};
			//移位指令
			//错误：'a' is not a constant
			//`EXE_SLL_OP:y<={b[31-sa:0],zerowire[sa:0]};
			`EXE_SLL_OP:y<=b<<sa;
			`EXE_SRL_OP:y<=b>>sa;
			`EXE_SRA_OP:y<=($signed(b))>>>sa;
			`EXE_SLLV_OP:y<=b<<a;
			`EXE_SRLV_OP:y<=b>>a;
			`EXE_SRAV_OP:y<=($signed(b))>>>a;
			//数据移动指令
			`EXE_MFHI_OP:y<=HiInput;
			`EXE_MFLO_OP:y<=LoInput;
			`EXE_MTHI_OP:HiOutput<=a;
			`EXE_MTLO_OP:LoOutput<=a;
			//算数运算指令
			`EXE_ADD_OP,`EXE_ADDI_OP,`EXE_SW_OP,`EXE_LW_OP:y <= s;
			`EXE_SUB_OP:y <= s;
			`EXE_SLT_OP:y <= s[31];
			//分支跳转指令
			//访存指令
			//内陷指令
			//特权指令


		default:y<=32'b0;
	endcase
		// case (op[1:0])
		// 	2'b00: y <= a & bout;
		// 	2'b01: y <= a | bout;
		// 	2'b10: y <= s;
		// 	2'b11: y <= s[31];
		// 	default : y <= 32'b0;
		// endcase	
	end
	assign zero = (y == 32'b0);

	//例外部分，暂时不管
	//TODO
	always @(*) begin
		case (op[2:1])
			2'b01:overflow <= a[31] & b[31] & ~s[31] |
							~a[31] & ~b[31] & s[31];
			2'b11:overflow <= ~a[31] & b[31] & s[31] |
							a[31] & ~b[31] & ~s[31];
			default : overflow <= 1'b0;
		endcase	
	end
endmodule
