`timescale 1ns / 1ps


module controller(
	input wire clk,rst,
	
	//decode stage
	input wire[5:0] opD,functD,
	input wire[4:0] InstrRtD,
	output wire pcsrcD,branchD,jumpD,jrD,

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
	output wire memtoregW,regwriteW,HLwriteW,BJalW,
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
	wire BJalD;
	assign BJalD=jalD|balD;
	//execute stage
	
	wire memwriteE;
	wire BJalE,BJalM,BJalW;
	
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
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,HLwriteD,BJalD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,HLwriteE,BJalE}
	);

	flopenrc #(8) regM(
		clk,rst,~stallM,
		flushM,
		{memtoregE,memwriteE,regwriteE,HLwriteE,BJalE},
		{memtoregM,memwriteM,regwriteM,HLwriteM,BJalM}
	);

	flopenrc #(8) regW(
		clk,rst,~stallW,
		flushW,
		{memtoregM,regwriteM,HLwriteM,BJalM},
		{memtoregW,regwriteW,HLwriteW,BJalW}
	);

endmodule
