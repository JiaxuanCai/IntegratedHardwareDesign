`timescale 1ns / 1ps


module controller(
	input wire clk,rst,
	
	//decode stage
	input wire[5:0] opD,functD,
	input wire[4:0] InstrRtD,
	output wire pcsrcD,branchD,jumpD,

	input equalD,
	
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[7:0] alucontrolE,

	//mem stage
	output wire memtoregM,memwriteM,regwriteM,HLwriteM,
	input wire stallM,flushM,
	
	//write back stage
	output wire memtoregW,regwriteW,HLwriteW,
	input wire stallW,flushW

);
	
	//decode stage
	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD;
	wire HLwriteD,HLwriteE;
	//////////////////////////////////////
	wire memenD;
	wire jalD,jrD,balD;//以后修改通路可能用
	//////////////////////////////////////
	wire[7:0] alucontrolD;

	//execute stage
	
	wire memwriteE;

	maindec md(
		opD,functD,InstrRtD,
		memtoregD,memenD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalD,jrD,balD,
		HLwriteD
		//aluopD
	);

	aludec ad(opD,functD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(16) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,HLwriteD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,HLwriteE}
	);

	flopenrc #(8) regM(
		clk,rst,~stallM,
		flushM,
		{memtoregE,memwriteE,regwriteE,HLwriteE},
		{memtoregM,memwriteM,regwriteM,HLwriteM}
	);

	flopenrc #(8) regW(
		clk,rst,~stallW,
		flushW,
		{memtoregM,regwriteM,HLwriteM},
		{memtoregW,regwriteW,HLwriteW}
	);

endmodule
