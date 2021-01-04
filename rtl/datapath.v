`timescale 1ns / 1ps
`include "defines.vh"

module datapath(
	
	input wire clk,rst,//时钟信号 重置信号
	
	//取指令阶段信�?
	output wire[31:0] pcF, //取指令级地址寄存�?
	input wire[31:0] instrF,// 取指令级的指�?

	//指令译码阶段信号
	//错误：没有引入alucontrolD
	input wire[7:0] alucontrolD,//计算单元计算类型选择
	input wire pcsrcD,branchD, //译码阶段地址来源 �? 条件跳转指令，相等则分支
	input wire jumpD,jrD,jalD,balD,//无条件跳转指令地�?
	input wire eretD,syscallD,breakD,invalidD,
	
	output wire brRest,//两个寄存器源操作数相等则有效
	output wire[5:0] opD,functD,// 指令的操作码字段 
	output wire [4:0] InstrRtD,
	output wire [31:0] instrD,

	//运算级信�?
	input wire memtoregE,//指令执行级的存储器写寄存器控制信�?
	input wire alusrcE,regdstE,BJalE,//执行指令级寄存器来源//指令执行级目标寄存器
	input wire regwriteE,writeTo31E,cp0readE,//计算级控制是否写入寄存器
	input wire[7:0] alucontrolE,//计算单元计算类型选择
	output wire flushE,//指令运算级刷新信�?


	//内存访问级信�?
	input wire memtoregM,//内存操作级的存储器写寄存器控制信�?
	input wire regwriteM,//访问内存级控制是否写入寄存器
	input wire HLwriteM,BJalM,
	output wire[31:0] aluoutM,writedata_decodedM,//运算级的运算结果//待写回内存的�?
	output wire[31:0] exceptTypeM,
 	input wire[7:0]alucontrolM,
	input wire[31:0] readdataM,//内存级读出的数据
	input wire cp0weM,
	output wire [3:0]readEnM,writeEnM,
	output wire flushM,flush_except,

	//写回级信�?
	input wire memtoregW,//写回级的存储器写寄存器控制信�?
	input wire regwriteW, //写回级读出的数据
	input wire HLwriteW,
	input wire cp0weW,
	output wire flushW,
	output wire [31:0]pcW,
	output wire [3:0]regenW,
	output wire [4:0]writeregW,
	output wire [31:0]resultW,
	
	

	output wire [4:0] rsE,rtE,rdE,
	output wire [4:0] rsD,rtD,rdD,
	
	output lwstallD,branchstallD,

	output stallF,stallD,stallE,stallM,stallW

);
	assign regenW={4{regwriteW}};
	//取指令阶段信�?
	//wire stallF;

	wire flushF;
	wire [7:0] exceptF;
	wire is_in_delayslotF;
	//地址控制信号
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
	wire [31:0] pcplus8F;


	//指令译码阶段信号
	wire [31:0] pcplus4D;
	wire [1:0]forwardaD,forwardbD;
	
	wire [4:0] saD;
	wire flushD;//stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire[31:0]pcD;
	wire [7:0] exceptD;
	wire is_in_delayslotD;
	wire [31:0] pcplus8D;

	//运算级信�?
	wire [1:0] forwardaE,forwardbE;
	wire [31:0] pcplus4E;
	wire forwardHLE;
	wire mut_div_stallE;
	wire clr_mut_divE;
	wire[31:0]pcE;
	
	wire [4:0] saE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE,aluoutEsrc;
	wire [63:0] aluHLsrc;
	wire [63:0] HLOutE;
	//wire cp0readE;
	wire [1:0] forwardcp0E;
	wire [7:0] exceptE;
	wire is_in_delayslotE;
	wire [31:0] cp0dataE, cp0data2E;
	wire overflowE,zeroE;
	wire [31:0] pcplus8E;
	//内存访问级信�?
	wire [4:0] writeregM;
	wire [63:0] HLOutM;
	wire [31:0] pcplus4M;
	wire[31:0]pcM;
	//wire flushM;
	wire [4:0] rdM;
	//wire cp0weM;
	//wire flush_except;
	wire [31:0] newpcM;
	wire is_in_delayslotM;
	wire [7:0] exceptM;
	wire [31:0] bad_addrM;
	//TODO
	//异常的部分实现后修改，暂时引�?


	//写回级信�?
	wire [31:0] aluoutW,readdataW;
	wire [63:0] HLOutW;
	wire [63:0] HLregW;
	wire [31:0] pcplus4W;
	wire [4:0] rdW;
	//wire flushW;
	wire[31:0] count_oW,compare_oW,status_oW,cause_oW,epc_oW, config_oW,prid_oW,badvaddrW;


	//冒险模块
	hazard h(
		//取指令阶段信�?
		.stallF(stallF),
		.flushF(flushF),

		//指令译码阶段信号
		.rsD(rsD),
		.rtD(rtD),
		.branchD(branchD), 
		.jumpD(jumpD),.jrD(jrD),
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
		.stallD(stallD),.flushD(flushD),

		//运算级信�?
		.rsE(rsE),
		.rtE(rtE),
		.rdE(rdE),
		.writeregE(writeregE),
		.regwriteE(regwriteE),
		.memtoregE(memtoregE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.flushE(flushE),
		.forwardHLE(forwardHLE),
		.mut_div_stallE(mut_div_stallE),
		.stallE(stallE),
		.cp0readE(cp0readE),
		.forwardcp0E(forwardcp0E),

		//内存访问级信�?
		.writeregM(writeregM),
		.regwriteM(regwriteM),
		.memtoregM(memtoregM),
		.HLwriteM(HLwriteM),
		.stallM(stallM),.flushM(flushM),
		.rdM(rdM),
		.cp0weM(cp0weM),
		.except_typeM(exceptTypeM),
		//写回级信�?
		.writeregW(writeregW),
		.regwriteW(regwriteW),
		.stallW(stallW),.flushW(flushW),

		.lwstallD(lwstallD),
		.branchstallD(branchstallD),
		.rdW(rdW),
		.cp0weW(cp0weW),
		.flush_except(flush_except)
	);

	//下一个指令地�?计算
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);  //地址计算部分
	//mux2 #(32) pcmux(pcnextbrFD, {pcplus4D[31:28],instrD[25:0],2'b00}, jumpD, pcnextFD);  //地址计算部分
	//jr�?1直接跳寄存器值，否则如果jump�?1跳拼接�?�，否则正常+4
	//错误：必须�?�择数据前推后的srca2D
	assign pcnextFD=jrD?srca2D:
						(jumpD|jalD)?{pcplus4D[31:28],instrD[25:0],2'b00}:pcnextbrFD;
	
	//寄存器访�?
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);


	//取指触发�?
	//加入flush和异常跳转地�?
	
	adder pcadd1(pcF,32'b100,pcplus4F);  //地址计算部分
	adder pcadd3(pcF,32'b1000,pcplus8F); //地址计算部分
	//按照视频里写�?10000000，自己感觉不太对？？测试之后再看。！
	assign exceptF = (pcF[1:0] == 2'b00) ? 8'b00000000 : 8'b01000000;
	assign is_in_delayslotF = (jumpD | jalD | jrD | balD | branchD);
	
	//译指触发�?
	//错误：地�?计算部分不能刷新
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);  //地址计算部分
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,pcD);
	flopenrc #(8) r4D(clk,rst,~stallD,flushD,exceptF,exceptD);
	flopenrc #(8) r5D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
	flopenrc #(32) r6D(clk,rst,~stallD,flushD,pcplus8F,pcplus8D);

	signext se(instrD[15:0],instrD[29:28],signimmD); //32位符号扩展立即数
	sl2 immsh(signimmD,signimmshD); //地址计算部分

	adder pcadd2(pcplus4D,signimmshD,pcbranchD);  //地址计算部分
	
	mux3 #(32) forwardamux(srcaD,aluoutM,aluoutE,forwardaD,srca2D);
	mux3 #(32) forwardbmux(srcbD,aluoutM,aluoutE,forwardbD,srcb2D);
	//eqcmp comp(srca2D,srcb2D,equalD);
	BranchDec brdecode(srca2D,srcb2D,alucontrolD,brRest);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign InstrRtD=instrD[20:16];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD=instrD[10:6];

	//运算级信号触发器
	flopenrc#(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc#(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc#(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc#(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc#(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc#(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc#(5) r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc#(32) r8E(clk,rst,~stallE,flushE,pcplus4D,pcplus4E);
	flopenrc #(32) r9E(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(8) r10E(clk,rst,~stallE,flushE,{exceptD[7:5],syscallD,breakD,eretD,invalidD,exceptD[0]},exceptE);
	flopenrc #(1) r11E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);
	flopenrc #(32) r12E(clk,rst,~stallE,flushE,pcplus8D,pcplus8E);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(64) forwardHLmux(HLregW,HLOutM,forwardHLE,aluHLsrc);
	mux3 #(32) forwardcp0mux(cp0dataE,aluoutW,aluoutM,forwardcp0E,cp0data2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);

	//alu alu(srca2E,srcb3E,alucontrolE,saE,aluoutE);
	//错误日志：未加入overflow、zero导致对齐错误
	pcflopenrc #(32) pcreg(clk,rst,~stallF,flushF,pcnextFD,newpcM,pcF);
	// pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);  //地址计算部分
	alu alu(clk,rst,clr_mut_divE,srca2E,srcb3E,alucontrolE,saE,aluoutEsrc,aluHLsrc[63:32],aluHLsrc[31:0],cp0data2E,HLOutE[63:32],HLOutE[31:0],mut_div_stallE,overflowE,zeroE);
	//错误：必须加载E阶段
	wire [4:0]writeregEsrc1;
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregEsrc1);
	mux2 #(5) wr2mux(writeregEsrc1,5'd31,writeTo31E,writeregE);
	
	assign clr_mut_divE=0;
	//错误日志：写成了floprc
	wire [31:0]writedataM;
	wire [31:0]pcplus8M;
	//内存访问级信号触发器
	//错误：数据前推的�?要，必须在E决定aluout
	mux2 #(32) resmux2(aluoutEsrc,pcplus8E,BJalE,aluoutE);

	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregE,writeregM);
	flopenrc #(64) r4M(clk,rst,~stallM,flushM,HLOutE,HLOutM);
	flopenrc#(32) r5M(clk,rst,~stallM,flushM,pcplus4E,pcplus4M);
	flopenrc #(32) r6M(clk,rst,~stallM,flushM,pcE,pcM);
	flopenrc #(5) r7M(clk,rst,~stallM,flushM,rdE,rdM);
	flopenrc #(1) r8M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
	flopenrc #(8) r9M(clk,rst,~stallM,flushM,{exceptE[7:1],overflowE},exceptM);
	flopenrc #(32) r10M(clk,rst,~stallM,flushM,pcplus8E,pcplus8M);
	
	//TODO
	
    wire[31:0]readdata_decodedM;
	//0104 变量名写错了
    wire adelM,adesM;
	memInsDecode memdec(alucontrolM,aluoutM[1:0],readdataM,writedataM,readdata_decodedM,writedata_decodedM,readEnM,writeEnM,adelM,adesM);
	
	//0103错误日志：顺序错�?
	exception except(rst, cp0weW,exceptM,aluoutW,rdW,adelM,adesM,status_oW, cause_oW, epc_oW,exceptTypeM,newpcM);
	
	assign bad_addrM = (exceptM[6])? pcM:(adelM | adesM)? aluoutM: 32'b0;

	wire [3:0]writeEnW;

	//写回级信号触发器
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,readdata_decodedM,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	flopenrc #(64) r4W(clk,rst,~stallW,flushW,HLOutM,HLOutW);
	flopenrc #(32) r5W(clk,rst,~stallW,flushW,pcM,pcW);
	flopenrc #(32) r6W(clk,rst,~stallW,flushW,writeEnM,writeEnW);
	flopenrc #(5)  r7W(clk,rst,~stallW,flushW,rdM,rdW);

	//HL寄存�?
	hilo_reg hilorrg(clk,rst,HLwriteW,HLOutW[63:32],HLOutW[31:0],HLregW[63:32],HLregW[31:0]);

	cp0_reg cp0(
		.clk(clk),.rst(rst),.we_i(cp0weW),.waddr_i(rdW),.raddr_i(rdE),
		.data_i(aluoutW),.int_i(6'b000000),.excepttype_i(exceptTypeM),
		.current_inst_addr_i(pcM),.is_in_delayslot_i(is_in_delayslotM),
		.bad_addr_i(bad_addrM),.data_o(cp0dataE),.count_o(count_oW),
		.compare_o(compare_oW),.status_o(status_oW),.cause_o(cause_oW),
		.epc_o(epc_oW),.config_o(config_oW),.prid_o(prid_oW),.badvaddr(bad_addrM));
	
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
	
endmodule
