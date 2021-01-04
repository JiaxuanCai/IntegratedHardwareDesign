`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/01 01:51:08
// Design Name: 
// Module Name: hazard
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

module hazard(

	//取指令阶段信�?
	output wire stallF,flushF,//取指令级暂停控制信号，低电位有效

	//指令译码阶段信号
	input wire[4:0] rsD,rtD,//指令译码阶段数据前推rs、rd寄存�?
	input wire branchD,//条件跳转指令，相等则分支
	input wire jumpD,jrD,
	output wire forwardaD,forwardbD,//指令译码阶段数据前推rs、rd
	output wire stallD,//译码级暂停控制信号，低电位有�?
	output wire flushD,

	//运算级信�?
	input wire[4:0] rsE,rtE,rdE,//运算阶段数据前推rs寄存�?,运算阶段数据前推rt寄存�?
	input wire[4:0] writeregE,//运算阶段写寄存器控制信号
	input wire regwriteE,//计算级控制是否写入寄存器
	input wire memtoregE,//指令执行级的存储器写寄存器控制信�?
	output reg[1:0] forwardaE,forwardbE,//指令执行级阶段数据前推rs 指令执行级阶段数据前推rt
	output wire flushE,//指令运算级刷新信�?
	output wire forwardHLE,
	input wire mut_div_stallE,
	output stallE,
	input cp0readE, //协处理器读取信号
	output reg[1:0] forwardcp0E, //协处理器前推信号

	//内存访问级信�?
	input wire[4:0] writeregM,//内存阶段写寄存器控制信号
	input wire regwriteM,// 内存级控制是否写入寄存器
	input wire memtoregM,//内存数据写到寄存�?
	input wire HLwriteM,
	output stallM,flushM,
	input [4:0] rdM,
	input cp0weM, //协处理器写信�?
	input [31:0] except_typeM,

	//写回级信�?
	input wire[4:0] writeregW,//写回阶段写寄存器控制信号
	input wire regwriteW,//写回级控制是否写入寄存器
	output stallW,flushW,

	output lwstallD,branchstallD,
	input[4:0] rdW,
	input cp0weW, //协处理器写信�?
	output flush_except
);

	wire jrstallD;
	// 分支指令 冒险 产生的数据前�?
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//运算级数据前�?
	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		forwardcp0E = 2'b00;
        /////////////////////////////////////////////////////////////////////////////////////////�?�?
		//处理两个R型或三个R型指令相�? 比如三个add指令，三个都相关
		//处理rs寄存�?
		if(rsE != 0) begin
			//此处还需进一步改�? 还不能处理连续加�?
			if(rsE == writeregM & regwriteM & writeregM !=0 ) begin
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW & regwriteW !=0) begin
				forwardaE = 2'b01;
			end
		end
		//处理rt寄存�?
		if(rtE != 0) begin
			if(rtE == writeregM & regwriteM & writeregM!=0) begin  // writeregM是内存级要写入的目的寄存器编�?  regwriteM是是否写寄存器使�?
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW & writeregW!=0) begin
				forwardbE = 2'b01;
			end
		end
		//涉及到cp0时处理rd寄存�?
		if(cp0readE != 0) begin
			if(rdM == rdE && cp0weM) begin  // writeregM是内存级要写入的目的寄存器编�?  regwriteM是是否写寄存器使�?
				forwardcp0E = 2'b10;
			end else if(rdW == rdE && cp0weW) begin
				forwardcp0E = 2'b01;
			end
		end
	
		/////////////////////////////////////////////////////////////////////////////////////////结束
	end

    /////////////////////////////////////////////////////////////////////////////////////////////////////////NOTICE
	//下面的可能存在�?�辑上的错误

	//如果在M阶段写，直接前推即可
	assign forwardHLE=HLwriteM;
	//取指令的暂停控制信号  （属于数据冒险模块）
	assign #1 lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign flush_except = (|except_typeM);
	//分支指令的暂停控制信�?  （属于控制冒险模块）
	assign #1 branchstallD = branchD & ( regwriteE  &  (writeregE == rsD | writeregE == rtD)  |  memtoregM & (writeregM == rsD | writeregM == rtD) );
	assign #1 jrstallD=(jumpD&jrD)&(regwriteE  &  (writeregE == rsD | writeregE == rtD)  |  memtoregM & (writeregM == rsD | writeregM == rtD) );
    //F级暂�?
	assign #1 stallF = stallD;

    //D级暂�?
	assign #1 stallD = lwstallD | branchstallD | jrstallD | mut_div_stallE ;

	//E级暂�?
	assign #1 stallE = mut_div_stallE ;

	//M级暂�?
	assign #1 stallM = 0;
	
	//W级暂�?
	assign #1 stallW=0;

	//F级刷�?
	assign flushF = flush_except;

	//D级刷�?
	assign flushD = flushF;

	//E级刷�?
	//assign #1 flushE = lwstallD | branchstallD|jumpD;
	//错误：不能根据branch或�?�jump刷新e�?
	assign #1 flushE = lwstallD | branchstallD | jumpD | flush_except;

	//M级刷�?
	assign #1 flushM=flushF;
	
	//W级刷�?
	assign #1 flushW=flushF;

endmodule
