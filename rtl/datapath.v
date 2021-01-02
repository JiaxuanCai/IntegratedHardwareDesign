`timescale 1ns / 1ps

module datapath(
	
	input wire clk,rst,//时钟信号 重置信号
	
	//取指令阶段信号
	output wire[31:0] pcF, //取指令级地址寄存器
	input wire[31:0] instrF,// 取指令级的指令

	//指令译码阶段信号
	//错误：没有引入alucontrolD
	input wire[7:0] alucontrolD,//计算单元计算类型选择
	input wire pcsrcD,branchD, //译码阶段地址来源 与 条件跳转指令，相等则分支
	input wire jumpD,jrD,//无条件跳转指令地址

	
	output wire brRest,//两个寄存器源操作数相等则有效
	output wire[5:0] opD,functD,// 指令的操作码字段 
	output wire [4:0] InstrRtD,
	//运算级信号
	input wire memtoregE,//指令执行级的存储器写寄存器控制信号
	input wire alusrcE,regdstE,//执行指令级寄存器来源//指令执行级目标寄存器
	input wire regwriteE,writeTo31E,//计算级控制是否写入寄存器
	input wire[7:0] alucontrolE,//计算单元计算类型选择
	output wire flushE,//指令运算级刷新信号


	//内存访问级信号
	input wire memtoregM,//内存操作级的存储器写寄存器控制信号
	input wire regwriteM,//访问内存级控制是否写入寄存器
	input wire HLwriteM,BJalM,
	output wire[31:0] aluoutM,writedata_decodedM,//运算级的运算结果//待写回内存的值
	output wire[7:0] expectTypeM,
 	input wire[7:0]alucontrolM,
	input wire[31:0] readdataM,//内存级读出的数据
	output wire [3:0]readEnM,writeEnM,
	output wire flushM,

	//写回级信号
	input wire memtoregW,//写回级的存储器写寄存器控制信号
	input wire regwriteW, //写回级读出的数据
	input wire HLwriteW,
	output wire flushW,
	output wire [31:0]pcW,
	output wire [3:0]writeEnW,
	output wire [4:0]writeregW,
	output wire [31:0]resultW,
	
	

	output wire [4:0] rsE,rtE,rdE,
	output wire [4:0] rsD,rtD,rdD,
	
	output lwstallD,branchstallD,

	output stallF,stallD,stallE,stallM,stallW

);
	
	//取指令阶段信号
	//wire stallF;

	//地址控制信号
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;

	//指令译码阶段信号
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	
	wire [4:0] saD;
	wire flushD;//stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire[31:0]pcD;

	//运算级信号
	wire [1:0] forwardaE,forwardbE;
	wire [31:0] pcplus4E;
	wire forwardHLE;
	wire mut_div_stallE;
	wire stallE;
	wire clr_mut_divE;
	wire[31:0]pcE;
	
	wire [4:0] saE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	wire [63:0] aluHLsrc;
	wire [63:0] HLOutE;
	//内存访问级信号
	wire [4:0] writeregM;
	wire [63:0] HLOutM;
	wire [31:0] pcplus4M;
	wire[31:0]pcM;
	wire stallM,flushM;
	//TODO
	//异常的部分实现后修改，暂时引出
	assign expectTypeM=0;

	//写回级信号
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;
	wire [63:0] HLOutW;
	wire [63:0] HLregW;
	wire [31:0] pcplus4W;
	wire[31:0]pcW;
	wire stallW,flushW;

	//冒险模块
	hazard h(

		//取指令阶段信号
		.stallF(stallF),

		//指令译码阶段信号
		.rsD(rsD),
		.rtD(rtD),
		.branchD(branchD), 
		.jumpD(jumpD),
		.forwardaD(forwardaD),
		.forwardbD(forwardbD),
		.stallD(stallD),.flushD(flushD),

		//运算级信号
		.rsE(rsE),
		.rtE(rtE),
		.writeregE(writeregE),
		.regwriteE(regwriteE),
		.memtoregE(memtoregE),
		.forwardaE(forwardaE),
		.forwardbE(forwardbE),
		.flushE(flushE),
		.forwardHLE(forwardHLE),
		.mut_div_stallE(mut_div_stallE),
		.stallE(stallE),
		
		//内存访问级信号
		.writeregM(writeregM),
		.regwriteM(regwriteM),
		.memtoregM(memtoregM),
		.HLwriteM(HLwriteM),
		.stallM(stallM),.flushM(flushM),

		//写回级信号
		.writeregW(writeregW),
		.regwriteW(regwriteW),
		.stallW(stallW),.flushW(flushW),

		.lwstallD(lwstallD),
		.branchstallD(branchstallD)
		
	);

	//下一个指令地址计算
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);  //地址计算部分
	//mux2 #(32) pcmux(pcnextbrFD, {pcplus4D[31:28],instrD[25:0],2'b00}, jumpD, pcnextFD);  //地址计算部分
	//jr为1直接跳寄存器值，否则如果jump为1跳拼接值，否则正常+4
	//错误：必须选择数据前推后的srca2D
	assign pcnextFD=jrD?srca2D:
						jumpD?{pcplus4D[31:28],instrD[25:0],2'b00}:pcnextbrFD;
	
	//寄存器访问
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);


	//取指触发器
	pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);  //地址计算部分
	adder pcadd1(pcF,32'b100,pcplus4F);  //地址计算部分

	
	//译指触发器
	//错误：地址计算部分不能刷新
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);  //地址计算部分
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,pcD);

	signext se(instrD[15:0],instrD[29:28],signimmD); //32位符号扩展立即数
	sl2 immsh(signimmD,signimmshD); //地址计算部分

	adder pcadd2(pcplus4D,signimmshD,pcbranchD);  //地址计算部分

	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
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

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(64) forwardHLmux(HLregW,HLOutM,forwardHLE,aluHLsrc);
	
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	//alu alu(srca2E,srcb3E,alucontrolE,saE,aluoutE);
	//错误日志：未加入overflow、zero导致对齐错误
	alu alu(clk,rst,clr_mut_divE,srca2E,srcb3E,alucontrolE,saE,aluoutE,aluHLsrc[63:32],aluHLsrc[31:0],HLOutE[63:32],HLOutE[31:0],mut_div_stallE);
	//错误：必须加载E阶段
	wire [4:0]writeregEsrc1;
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregEsrc1);
	mux2 #(5) wr2mux(writeregEsrc1,31,writeTo31E,writeregE);
	assign clr_mut_divE=0;
	//错误日志：写成了floprc
	wire [31:0]writedataM;
	//内存访问级信号触发器
	wire [31:0]aluoutMsrc;
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE,aluoutMsrc);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregE,writeregM);
	flopenrc #(64) r4M(clk,rst,~stallM,flushM,HLOutE,HLOutM);
	flopenrc#(32) r5M(clk,rst,~stallM,flushM,pcplus4E,pcplus4M);
	flopenrc #(32) r6M(clk,rst,~stallM,flushM,pcE,pcM);
	//错误：数据前推的需要，必须在M决定aluout
	wire [31:0]pcplus8M;
	assign pcplus8M=pcplus4M+4;
	mux2 #(32) resmux2(aluoutMsrc,pcplus8M,BJalM,aluoutM);
	//TODO
	
    wire[31:0]readdata_decodedM;
    wire read_addr_errorM,wirte_addr_errorM;
	memInsDecode memdec(alucontrolM,aluoutM[1:0],readdataM,writedataM,readdata_decodedM,writedata_decodedM,readEnM,writeEnM,read_addr_errorM,wirte_addr_errorM);

	//写回级信号触发器
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,readdata_decodedM,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	flopenrc #(64) r4W(clk,rst,~stallW,flushW,HLOutM,HLOutW);
	flopenrc #(32) r5W(clk,rst,~stallW,flushW,pcM,pcW);
	//HL寄存器
	hilo_reg hilorrg(clk,rst,HLwriteW,HLOutW[63:32],HLOutW[31:0],HLregW[63:32],HLregW[31:0]);

	
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
	
endmodule
