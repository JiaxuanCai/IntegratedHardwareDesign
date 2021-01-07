`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/02 15:04:04
// Design Name: 
// Module Name: mycpu_top
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

//封装成Sram接口
//参�?�https://www.bilibili.com/video/BV1XJ411k7kR?p=3

module mycpu_top(
    input wire clk,resetn,
    input wire[15:0] int,  //interrupt,high active

    output wire inst_sram_en,
    output wire [3:0]inst_sram_wen,
    output wire [31:0]inst_sram_addr,
    output wire [31:0]inst_sram_wdata,
    input wire [31:0]inst_sram_rdata,

    output wire data_sram_en,
    output wire [3:0]data_sram_wen,
    output wire [31:0]data_sram_addr,
    output wire [31:0]data_sram_wdata,
    input wire [31:0]data_sram_rdata,

    //debug
    output wire [31:0]debug_wb_pc,
    output wire [3:0]debug_wb_rf_wen,  
    output wire [4:0]debug_wb_rf_wnum,
    output wire [31:0]debug_wb_rf_wdata
    );
    wire rst;
    wire [1:0]size;
    assign rst=~resetn;
	wire [31:0] data_paddr,inst_paddr;
    wire [31:0]instrF;
    wire [31:0]pcF;
	wire [5:0] opD,functD;
	wire [4:0] InstrRtD;
	wire [31:0] instrD;
    wire branchD,memwriteM;
    wire [31:0] aluoutM,writedataM;
    wire [3:0] readEnM,writeEnM;
    wire [4:0] rsE,rtE,rdE,rsD,rtD,rdD;
    wire lwstallD,branchstallD,stallF;
	wire jrD;
    wire jalD,balD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW;
	wire regwriteE,regwriteM,regwriteW;
	wire HLwriteM,HLwriteW;
	//错误：这里没有加，导致错误，一定要看warning
	wire [7:0] alucontrolD;
	wire [7:0] alucontrolE,alucontrolM;
	wire flushE,equalD;
	wire stallD,stallE,stallM,stallW,flushM,flushW;
	wire writeTo31E,BJalM,BJalE;
    wire [31:0]exceptTypeM;
	wire cp0readE,cp0weM,cp0weW;
	wire flush_except;
    //严重错误：忘记写导致readdataM只有1�?
    wire [31:0] readdataM;
    wire memenM;
	wire eretD,syscallD,breakD,invalidD;
    assign inst_sram_en=1'b1;
    assign inst_sram_wen=4'b0;
    assign inst_sram_addr=inst_paddr;
    assign inst_sram_wdata=32'b0;
    assign instrF=inst_sram_rdata;

    assign data_sram_en=memenM&~(|exceptTypeM);
    assign data_sram_wen=writeEnM;
    //错误：地�?转换，de了五个小�?
    assign data_sram_addr=data_paddr;
    assign data_sram_wdata=writedataM;
    assign readdataM=data_sram_rdata;

	controller c(
	instrD,
	~clk,rst,
	//取指令阶段信�?
	alucontrolD,
	opD,functD,InstrRtD,
	pcsrcD,branchD,jumpD,jrD,jalD,balD,

	equalD,stallD,eretD,syscallD,breakD,invalidD,
	
	//运算级信�?
	flushE,stallE,BJalE,
	memtoregE,alusrcE,
	regdstE,regwriteE,	writeTo31E,
	alucontrolE,
	cp0readE,

	//内存访问级信�?
	memtoregM,memwriteM,
	regwriteM,HLwriteM,BJalM,memenM,alucontrolM,
	stallM,flushM,
	cp0weM,
	
	//写回级信�?
	memtoregW,regwriteW,
	HLwriteW,stallW,flushW,
	cp0weW
);

    //错误：时钟应该取�?
	datapath dp(
		~clk,rst,
		//取指令阶段信�?
		pcF,
		instrF,
		//指令译码阶段信号
		alucontrolD,
		pcsrcD,branchD,
		jumpD,jrD,jalD,balD,
		eretD,syscallD,breakD,invalidD,
		equalD,
		opD,functD,
		InstrRtD,
		instrD,
		//运算级信�?
		memtoregE,
		alusrcE,regdstE,BJalE,
		regwriteE,writeTo31E,cp0readE,
		alucontrolE,
		flushE,
		//内存访问级信�?
		memtoregM,
		regwriteM,
		HLwriteM,BJalM,
        //错误：expectTypeM位置错误
		aluoutM,writedataM,exceptTypeM,alucontrolM,
		readdataM,cp0weM,readEnM,writeEnM,
		size,
		flushM, flush_except,
		//写回级信�?
		memtoregW,
		regwriteW,
		HLwriteW,
		cp0weW,
		flushW,
		debug_wb_pc,
		debug_wb_rf_wen,
		debug_wb_rf_wnum,
		debug_wb_rf_wdata,




		rsE,rtE,rdE,
	    rsD,rtD,rdD,
		lwstallD,branchstallD,
	    stallF,
	    stallD,
		stallE,
		stallM,
		stallW
	);
	mmu addrTrans(
		pcF,
		inst_paddr,
		aluoutM,
		data_paddr,
		no_dcache    //是否经过d cache
	);

	
    
endmodule
