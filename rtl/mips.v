`timescale 1ns / 1ps


module mips(
	input wire clk,rst,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire memwriteM,
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,

	output wire [4:0] rsE,rtE,rdE,
	output wire [4:0] rsD,rtD,rdD,

	output lwstallD,branchstallD,

	output stallF,
	output flushE,stallD
);
	
	wire [5:0] opD,functD;
	wire [4:0] InstrRtD;
	wire jrD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW;
	wire regwriteE,regwriteM,regwriteW;
	wire HLwriteM,HLwriteW;
	//错误：这里没有加，导致z
	wire [7:0] alucontrolD;
	wire [7:0] alucontrolE;
	wire flushE,equalD;
	wire stallD,stallE,stallM,stallW,flushM,flushW;
	wire writeTo31E;

	controller c(
		clk,rst,
		//取指令阶段信号
		alucontrolD,
		opD,functD,InstrRtD,
		pcsrcD,branchD,jumpD,jrD,
		
        equalD,

		//运算级信号
		flushE,stallE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	writeTo31E,
		alucontrolE,

		//内存访问级信号
		memtoregM,memwriteM,
		regwriteM,HLwriteM,
		stallM,flushM,
		//写回级信号
		memtoregW,regwriteW,
		HLwriteW,BJalW,stallW,flushW
	);

	datapath dp(
		clk,rst,
		//取指令阶段信号
		pcF,
		instrF,
		//指令译码阶段信号
		alucontrolD,
		pcsrcD,branchD,
		jumpD,jrD,
		equalD,
		opD,functD,
		InstrRtD,
		//运算级信号
		memtoregE,
		alusrcE,regdstE,
		regwriteE,writeTo31E,
		alucontrolE,
		flushE,
		//内存访问级信号
		memtoregM,
		regwriteM,
		HLwriteM,
		aluoutM,writedataM,
		readdataM,
		flushM,
		//写回级信号
		memtoregW,
		regwriteW,
		HLwriteW,
		BJalW,
		flushW,
		rsE,rtE,rdE,
	    rsD,rtD,rdD,
		lwstallD,branchstallD,
	    stallF,
	    stallD,
		stallE,
		stallM,
		stallW
	);
	
endmodule
