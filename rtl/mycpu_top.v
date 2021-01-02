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
//参考https://www.bilibili.com/video/BV1XJ411k7kR?p=3

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
    assign rst=~resetn;
    wire [31:0]instrF;
    wire [31:0]pcF;
	wire [5:0] opD,functD;
	wire [4:0] InstrRtD;
    wire branchD,jumpF,memwriteM;
    wire [31:0] aluoutM,writedataM;
    wire [3:0] readEnM,writeEnM;
    wire [4:0] rsE,rtE,rdE,rsD,rtD,rdD;
    wire lwstallD,branchstallD,stallF;
	wire jrD;
    wire jalD,balD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW;
	wire regwriteE,regwriteM,regwriteW;
	wire HLwriteM,HLwriteW;
	//错误：这里没有加，导致z,一定要看warning
	wire [7:0] alucontrolD;
	wire [7:0] alucontrolE,alucontrolM;
	wire flushE,equalD;
	wire stallD,stallE,stallM,stallW,flushM,flushW;
	wire writeTo31E,BJalM;
    wire [7:0]expectTypeM;
    //严重错误：忘记写导致readdataM只有1位
    wire [31:0] readdataM;
    wire memenM;

    assign inst_sram_en=1'b1;
    assign inst_sram_wen=4'b0;
    assign inst_sram_addr=pcF;
    assign inst_sram_wdata=32'b0;
    assign instrF=inst_sram_rdata;

    assign data_sram_en=memenM&~(|expectTypeM);
    assign data_sram_wen=writeEnM;
    //错误：地址转换，de了五个小时
    assign data_sram_addr=aluoutM[31]?{3'b0,aluoutM[28:0]}:aluoutM;
    assign data_sram_wdata=writedataM;
    assign readdataM=data_sram_rdata;

	controller c(
		~clk,rst,
		//取指令阶段信号
		alucontrolD,
		opD,functD,InstrRtD,
		pcsrcD,branchD,jumpD,jrD,jalD,balD,
		
        equalD,

		//运算级信号
		flushE,stallE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	writeTo31E,
		alucontrolE,

		//内存访问级信号
		memtoregM,memwriteM,
		regwriteM,HLwriteM,BJalM,memenM,alucontrolM,
		stallM,flushM,
		//写回级信号
		memtoregW,regwriteW,
		HLwriteW,stallW,flushW
	);
    //错误：时钟应该取反
	datapath dp(
		~clk,rst,
		//取指令阶段信号
		pcF,
		instrF,
		//指令译码阶段信号
		alucontrolD,
		pcsrcD,branchD,
		jumpD,jrD,jalD,balD,
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
		HLwriteM,BJalM,
        //错误：expectTypeM位置错误
		aluoutM,writedataM,expectTypeM,alucontrolM,
		readdataM,readEnM,writeEnM,
		flushM,
		//写回级信号
		memtoregW,
		regwriteW,
		HLwriteW,
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
    
endmodule
