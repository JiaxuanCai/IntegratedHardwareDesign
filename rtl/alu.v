`timescale 1ns / 1ps
`include "defines.vh"
/////////////////////////////////
//alu辅助了一部分controller的逻辑
module alu#(parameter MUT_MAX=5)(
	input wire clk,rst,clr_mut_div,
	input wire[31:0] a,b,//第一个操作数和第二个操作数（rs、rt）（rs，imm）
	input wire[7:0] op,
	input wire[4:0] sa,
	output reg[31:0] y,
	input wire[31:0] HiInput,LoInput,
	output reg [31:0] HiOutput,LoOutput,
	output wire mut_div_stall,

	output reg overflow,
	output wire zero
    );
	
	wire[31:0] s,bout;
	wire subfunc;
	//错误：subu忘了加
	assign subfunc=op==`EXE_SUB_OP|op==`EXE_SUBU_OP|op==`EXE_SLT_OP|op==`EXE_SLTI_OP|op==`EXE_SLTU_OP|op==`EXE_SLTIU_OP;
	assign bout = subfunc ? ~b : b;
	assign s = a + bout + subfunc;
	reg stall_div,stall_mut,start_div,start_mut,signed_div;
	wire div_ready;
	assign mut_div_stall=stall_mut|stall_div;
	wire [31:0]mult_a,mult_b;
	assign mult_a=((op==`EXE_MULT_OP)&a[31])?(~a+1):a;
	assign mult_b=((op==`EXE_MULT_OP)&b[31])?(~b+1):b;
	wire [63:0]HL_mut,HL_div,multOut;
	assign HL_mut=((op==`EXE_MULT_OP)&(a[31]^b[31]))?~multOut+1:multOut;
	wire mut_ready;
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
			`EXE_ADD_OP,`EXE_ADDU_OP,`EXE_ADDI_OP,`EXE_ADDIU_OP:y <= s;
			`EXE_SUB_OP,`EXE_SUBU_OP:y <= s;
			`EXE_MULT_OP,`EXE_MULTU_OP:begin
				HiOutput<=HL_mut[63:32];
				LoOutput<=HL_mut[31:0];
			end
			`EXE_DIV_OP,`EXE_DIVU_OP:begin
				HiOutput<=HL_div[63:32];
				LoOutput<=HL_div[31:0];
			end
			//错误：逻辑错误
			//a负b正必真，否则不能a正b负且减法结果为负
			`EXE_SLT_OP,`EXE_SLTI_OP:y <= (a[31]&~b[31])?1:
												s[31]&~(~a[31]&b[31]);
			`EXE_SLTU_OP,`EXE_SLTIU_OP:y <=a<b;
			//分支跳转指令
			//访存指令
			`EXE_SW_OP,`EXE_LW_OP:y<=s;
			//内陷指令
			//特权指令


		default:y<=32'b0;
	endcase
	end
	assign zero = (y == 32'b0);
	
	//乘除状态机
	always@(*)begin
		start_mut<=1'b0;
		stall_mut<=1'b0;
		start_div<=1'b0;
		stall_div<=1'b0;
		case(op)
		`EXE_MULT_OP,`EXE_MULTU_OP:begin
			if(~mut_ready)begin
				start_mut<=1'b1;
				stall_mut<=1'b1;
			end
			else begin
				start_mut<=1'b0;
				stall_mut<=1'b0;
			end
		end
		`EXE_DIV_OP:begin
			if(~div_ready)begin
				start_div<=1'b1;
				signed_div<=1'b1;
				stall_div<=1'b1;
			end
			else begin
				start_div<=1'b0;
				signed_div<=1'b1;
				stall_div<=1'b0;
			end
		end
		`EXE_DIVU_OP:begin
			if(~div_ready)begin
				start_div<=1'b1;
				signed_div<=1'b0;
				stall_div<=1'b1;
			end
			else begin
				start_div<=1'b0;
				signed_div<=1'b0;
				stall_div<=1'b0;
			end
		end
		endcase
	end	
	//乘法状态机计数部分
	//满足最大乘法器周期要求
	reg [3:0]mult_count;
	wire is_mut;
	assign is_mut=(op==`EXE_MULT_OP)|(op==`EXE_MULTU_OP);
	assign mut_ready=mult_count==MUT_MAX;
	//op为乘，开始加，加到MUT_MAX乘法结果完成，归零。同时流水线重启，下一个op到来
	always@(posedge clk)begin
		if(rst) begin
			mult_count<=0;
		end else if(is_mut)begin
			if(mult_count!=MUT_MAX)
			mult_count<=mult_count+1;
			else
			mult_count<=0;
		end
	end

	//例外部分，暂时不管
	//TODO
	always @(*) begin
		case (op)
			`EXE_ADD_OP,`EXE_ADDI_OP:overflow <= a[31] & b[31] & ~s[31] |
							~a[31] & ~b[31] & s[31];
			`EXE_SUB_OP:overflow <= ~a[31] & b[31] & s[31] |
							a[31] & ~b[31] & ~s[31];
			default : overflow <= 1'b0;
		endcase	
	end
	div alu_div(
		clk,rst,
		signed_div,
		a,b,
		start_div,
		clr_mut_div,
		HL_div,
		div_ready
	);
	mult_gen_0 alu_mult(
		.CLK(clk),
		.A(mult_a),
		.B(mult_b),
		.CE(1'b1),
		.SCLR(clr_mut_div),
		.P(multOut)
	);
endmodule
