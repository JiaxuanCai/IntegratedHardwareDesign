`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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
`include "defines.vh"

module mycpu_top(
	input wire[5:0] int,
	input wire aclk,aresetn,
	
	 // axi port
    //ar
    output wire[3:0] arid,      //read request id, fixed 4'b0
    output wire[31:0] araddr,   //read request address
    output wire[7:0] arlen,     //read request transfer length(beats), fixed 4'b0
    output wire[2:0] arsize,    //read request transfer size(bytes per beats)
    output wire[1:0] arburst,   //transfer type, fixed 2'b01
    output wire[1:0] arlock,    //atomic lock, fixed 2'b0
    output wire[3:0] arcache,   //cache property, fixed 4'b0
    output wire[2:0] arprot,    //protect property, fixed 3'b0
    output wire arvalid,        //read request address valid
    input wire arready,         //slave end ready to receive address transfer
    //r              
    input wire[3:0] rid,        //equal to arid, can be ignored
    input wire[31:0] rdata,     //read data
    input wire[1:0] rresp,      //this read request finished successfully, can be ignored
    input wire rlast,           //the last beat data for this request, can be ignored
    input wire rvalid,          //read data valid
    output wire rready,         //master end ready to receive data transfer
    //aw           
    output wire[3:0] awid,      //write request id, fixed 4'b0
    output wire[31:0] awaddr,   //write request address
    output wire[3:0] awlen,     //write request transfer length(beats), fixed 4'b0
    output wire[2:0] awsize,    //write request transfer size(bytes per beats)
    output wire[1:0] awburst,   //transfer type, fixed 2'b01
    output wire[1:0] awlock,    //atomic lock, fixed 2'b01
    output wire[3:0] awcache,   //cache property, fixed 4'b01
    output wire[2:0] awprot,    //protect property, fixed 3'b01
    output wire awvalid,        //write request address valid
    input wire awready,         //slave end ready to receive address transfer
    //w          
    output wire[3:0] wid,       //equal to awid, fixed 4'b0
    output wire[31:0] wdata,    //write data
    output wire[3:0] wstrb,     //write data strobe select bit
    output wire wlast,          //the last beat data signal, fixed 1'b1
    output wire wvalid,         //write data valid
    input wire wready,          //slave end ready to receive data transfer
    //b              
    input  wire[3:0] bid,       //equal to wid,awid, can be ignored
    input  wire[1:0] bresp,     //this write request finished successfully, can be ignored
    input wire bvalid,          //write data valid
    output wire bready,          //master end ready to receive write response

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata

    );

	//sram signal
	//cpu inst sram
	wire        inst_sram_en;
	wire [3 :0] inst_sram_wen;
	wire [31:0] inst_sram_addr;
	wire [31:0] inst_sram_wdata;
	wire [31:0] inst_sram_rdata;
	//cpu data sram
	wire        data_sram_en,data_sram_write;
	wire [1 :0] data_sram_size;//连到datapath的size
	wire [3 :0] data_sram_wen;
	wire [31:0] data_sram_addr;
	wire [31:0] data_sram_wdata;
	wire [31:0] data_sram_rdata;



	wire rst,clk;
	assign clk=aclk;
    assign rst=~aresetn;
	
    wire [31:0]instrF;
    wire [31:0]pcF;
	wire [5:0] opD,functD;
	wire [4:0] InstrRtD;
	wire [31:0]instrD;
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
	wire [7:0] alucontrolD;
	wire [7:0] alucontrolE,alucontrolM;
	wire flushE,equalD;
	wire stallD,stallE,stallM,stallW,flushM,flushW;
	wire writeTo31E,BJalM;
    wire [31:0] readdataM;
    wire memenM;

	// the follow definitions are between controller and datapath.
	// also use some of them  link the IPcores

	//cache mux signal
	wire cache_miss,sel_i;
	wire[31:0] i_addr,d_addr,m_addr;
	wire m_fetch,m_ld_st,mem_access;
	wire mem_write,m_st;
	wire mem_ready,m_i_ready,m_d_ready,i_ready,d_ready;
	wire[31:0] mem_st_data,mem_data;
	wire[1:0] mem_size,d_size;// size not use
	wire[3:0] m_sel,d_wen;
	wire [31:0]exceptTypeM;
	wire stallreq_from_if,stallreq_from_mem;



	// assign the inst_sram_parameters
	assign inst_sram_en = 1'b1; //always strobe
	assign inst_sram_wen = 4'b0; // always read
	assign inst_sram_addr = pcF; // pc
	assign inst_sram_wdata = 32'b0; // do not need write operation
	assign instrF = inst_sram_rdata; // use your own signal from F stage

	//assign the data_sram_parameters
	assign data_sram_en = memenM&~(|exceptTypeM);// notice: disable the data strobe when exceptions occur
	assign data_sram_write = memwriteM; // 0 read, 1 write
	assign data_sram_wen = writeEnM;
	assign data_sram_addr = aluoutM[31]?{3'b0,aluoutM[28:0]}:aluoutM;
	assign data_sram_wdata = writedataM;
	assign readdataM = data_sram_rdata; // use your own signal from M stage


	// these modules use your own
	controller c(
		instrD,
		~clk,rst,
		//取指令阶段信号
		alucontrolD,
		opD,functD,InstrRtD,
		pcsrcD,branchD,jumpD,jrD,jalD,balD,
		
        equalD,stallD,
		eretD,syscallD,breakD,invalidD,

		//运算级信号
		flushE,stallE,BJalE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	writeTo31E,
		alucontrolE,
		cp0readE,

		//内存访问级信号
		memtoregM,memwriteM,
		regwriteM,HLwriteM,BJalM,memenM,alucontrolM,
		stallM,flushM,
		cp0weM,
		//写回级信号
		memtoregW,regwriteW,
		HLwriteW,stallW,flushW,
		cp0weW
	);
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
		data_sram_size,
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
		stallreq_from_if,
		stallreq_from_mem,
		rsE,rtE,rdE,
	    rsD,rtD,rdD,
		lwstallD,branchstallD,
	    stallF,
	    stallD,
		stallE,
		stallM,
		stallW
	);
	

	// use a inst_miss signal to denote that the instruction is not loadssss
	reg inst_miss;
	always @(posedge clk) begin
		if (~aresetn) begin
			inst_miss <= 1'b1;
		end
		if (m_i_ready & inst_miss) begin // fetch instruction ready
			inst_miss <= 1'b0;
		end else if (~inst_miss & data_sram_en) begin // fetch instruction ready, but need load data, so inst_miss maintain 0
			inst_miss <= 1'b0;
		end else if (~inst_miss & data_sram_en & m_d_ready) begin //load data ready, set inst_miss to 1
			inst_miss <= 1'b1;
		end else begin // other conditions, set inst_miss to 1
			inst_miss <= 1'b1;
		end
	end

	assign sel_i = inst_miss;	// use inst_miss to select access memory(for load/store) or fetch(each instruction)
	assign d_addr = (data_sram_addr[31:16] != 16'hbfaf) ? data_sram_addr : {16'h1faf,data_sram_addr[15:0]}; // modify data address, to get the data from confreg
	assign i_addr = inst_sram_addr;
	assign m_addr = sel_i ? i_addr : d_addr;
	// 
	assign m_fetch = inst_sram_en & inst_miss; //if inst_miss equals 0, disable the fetch strobe
	assign m_ld_st = data_sram_en;

	assign inst_sram_rdata = mem_data;
	assign data_sram_rdata = mem_data;
	assign mem_st_data = data_sram_wdata;
	// use select signal
	assign mem_access = sel_i ? m_fetch : m_ld_st; 
	assign mem_size = sel_i ? 2'b10 : data_sram_size;
	assign m_sel = sel_i ? 4'b1111 : data_sram_wen;
	assign mem_write = sel_i ? 1'b0 : data_sram_write;

	//demux
	assign m_i_ready = mem_ready & sel_i;
	assign m_d_ready = mem_ready & ~sel_i;

	//
	assign stallreq_from_if = ~m_i_ready;
	assign stallreq_from_mem = data_sram_en & ~m_d_ready;

	axi_interface interface(
		.clk(aclk),
		.resetn(aresetn),
		
		 //cache/cpu_core port
		.mem_a(m_addr),
		.mem_access(mem_access),
		.mem_write(mem_write),
		.mem_size(mem_size),
		.mem_sel(m_sel),
		.mem_ready(mem_ready),
		.mem_st_data(mem_st_data),
		.mem_data(mem_data),
		// add a input signal 'flush', cancel the memory accessing operation in axi_interface, do not need any extra design. 
		.flush(|exceptTypeM), // use excepetion type

		.arid      (arid      ),
		.araddr    (araddr    ),
		.arlen     (arlen     ),
		.arsize    (arsize    ),
		.arburst   (arburst   ),
		.arlock    (arlock    ),
		.arcache   (arcache   ),
		.arprot    (arprot    ),
		.arvalid   (arvalid   ),
		.arready   (arready   ),
					
		.rid       (rid       ),
		.rdata     (rdata     ),
		.rresp     (rresp     ),
		.rlast     (rlast     ),
		.rvalid    (rvalid    ),
		.rready    (rready    ),
				
		.awid      (awid      ),
		.awaddr    (awaddr    ),
		.awlen     (awlen     ),
		.awsize    (awsize    ),
		.awburst   (awburst   ),
		.awlock    (awlock    ),
		.awcache   (awcache   ),
		.awprot    (awprot    ),
		.awvalid   (awvalid   ),
		.awready   (awready   ),
		
		.wid       (wid       ),
		.wdata     (wdata     ),
		.wstrb     (wstrb     ),
		.wlast     (wlast     ),
		.wvalid    (wvalid    ),
		.wready    (wready    ),
		
		.bid       (bid       ),
		.bresp     (bresp     ),
		.bvalid    (bvalid    ),
		.bready    (bready    )
	);
endmodule
