`timescale 1ns / 1ps


module controller(
	input wire [31:0] instrD,
	input wire clk,rst,
	
	//decode stage
	output wire [7:0]alucontrolD,
	input wire[5:0] opD,functD,
	input wire[4:0] InstrRtD,
	output wire pcsrcD,branchD,jumpD,jrD,jalD,balD,

	input equalD,stallD,
	output eretD,syscallD,breakD,invalidD,
	
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,writeTo31E,
	output wire[7:0] alucontrolE,
	output wire cp0readE,

	//mem stage
	output wire memtoregM,memwriteM,regwriteM,HLwriteM,BJalM,memenM,
	output wire[7:0]alucontrolM,
	input wire stallM,flushM,
	output wire cp0weM,
	
	//write back stage
	output wire memtoregW,regwriteW,HLwriteW,
	input wire stallW,flushW,
	output wire cp0weW

);
	
	//decode stage
	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD;
	wire cp0weD,cp0readD;
	wire cp0weE;
	wire writeTo31D;

	wire HLwriteD,HLwriteE;
	//////////////////////////////////////
	wire memenD,memenE;
	wire jrD,balD;//以后修改通路可能用
	//////////////////////////////////////
	wire BJalD;
	assign BJalD=jalD|balD|jrD;
	//execute stage
	
	wire memwriteE;
	wire BJalE,BJalW;

	maindec md(
	opD,
	functD,
	InstrRtD,
	instrD,
	stallD,
	memtoregD,memenD,memwriteD,
	branchD,alusrcD,
	regdstD,regwriteD,
	jumpD,
	cp0weD,cp0readD,eretD,syscallD,breakD,
	jalD,jrD,balD,writeTo31D,
	HLwriteD
	//output wire[1:0] aluop
    );


	aludec ad(opD,functD,InstrRtD,instrD,stallD,alucontrolD,invalidD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	//错误 流水线大小不够
	flopenrc #(32) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,HLwriteD,BJalD,writeTo31D,memenD,cp0weD,cp0readD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,HLwriteE,BJalE,writeTo31E,memenE,cp0weE,cp0readE}
	);
	//错误：流水线中变量写错，alucontrolM恒伟1
	flopenrc #(32) regM(
		clk,rst,~stallM,
		flushM,
		{memtoregE,memwriteE,regwriteE,HLwriteE,BJalE,alucontrolE,memenE,cp0weE},
		{memtoregM,memwriteM,regwriteM,HLwriteM,BJalM,alucontrolM,memenM,cp0weM}
	);

	flopenrc #(8) regW(
		clk,rst,~stallW,
		flushW,
		{memtoregM,regwriteM,HLwriteM,BJalM,cp0weM},
		{memtoregW,regwriteW,HLwriteW,BJalW,cp0weW}
	);
endmodule
