`timescale 1ns / 1ps
//参考https://github.com/JF2098/A-simple-MIPS-CPU/tree/master/rtl
module d_cache_simple #(parameter A_WIDTH = 32, parameter C_INDEX = 6)
(
    //CPU
    input wire clk,clrn,
    input wire[A_WIDTH-1:0] p_a,
    input wire[31:0] p_dout,
    input wire p_strobe, //en
    input wire p_rw,  //0 read 1 write
    input wire[3:0] p_wen,p_ren,
    input flush_except, //?????????cache
    input no_dcache,
    output wire p_ready,
    output wire[31:0] p_din,
    //MEM
    input wire[31:0] m_dout,
    input wire m_ready,
    output wire[31:0] m_din,
    output wire[A_WIDTH-1:0] m_a,
    output wire m_strobe,
    output wire m_rw
);
localparam T_WIDTH = A_WIDTH - C_INDEX - 2;
reg [3:0] cache_valid_way_0  [0 : (1<<C_INDEX)-1];
reg [3:0] cache_valid_way_1 [0 : (1<<C_INDEX)-1];
reg [3:0] cache_dirty_way_0  [0 : (1<<C_INDEX)-1];
reg [3:0] cache_dirty_way_1 [0 : (1<<C_INDEX)-1];
reg [T_WIDTH-1:0] cache_tag_way_0  [0 : (1<<C_INDEX) - 1];
reg [T_WIDTH-1:0] cache_tag_way_1 [0 : (1<<C_INDEX) - 1];
reg [31:0] cache_tag_way_1cache_block_way_0 [0 : (1<<C_INDEX) - 1];
reg [31:0] cache_tag_way_1cache_block_way_1 [0 : (1<<C_INDEX) - 1];
wire [C_INDEX-1:0] index = p_a[C_INDEX+1 : 2];
wire [T_WIDTH-1:0] tag = p_a[A_WIDTH-1 : C_INDEX+2];

reg [WAY_CNT-2:0] pLRU;//保存伪LRU算法要用的最近使用信息

//write to cache
integer i;
//kseg1????cache
always@(posedge clk or negedge clrn)begin
    if(clrn == 0) begin
        for(i = 0; i < (1<<C_INDEX); i=i+1)begin
            cache_valid_way_0 [i] <= 4'b0;
            cache_valid_way_1[i] <= 4'b0;
        end
    end else if(c_write  & ~flush_except & ~no_dcache) begin
            cache_valid_way_0 [index] <= p_wen;
        end
end
always@(posedge clk)begin
    if(c_write & ~flush_except & ~no_dcache) begin
        cache_tag_way_0 [index] <= tag;
        case(cache_way_switch)
            0:begin
            case(p_wen)
                4'b1111: cache_tag_way_1cache_block_way_0[index] <= c_din; //SW
                4'b1100: cache_tag_way_1cache_block_way_0[index][31:16] <= c_din[31:16]; //SH
                4'b0011: cache_tag_way_1cache_block_way_0[index][15:0] <= c_din[15:0];
                4'b1000: cache_tag_way_1cache_block_way_0[index][31:24] <=      [31:24]; //SB
                4'b0100: cache_tag_way_1cache_block_way_0[index][23:16] <= c_din[23:16];
                4'b0010: cache_tag_way_1cache_block_way_0[index][15:8] <= c_din[15:8];
                4'b0001: cache_tag_way_1cache_block_way_0[index][7:0] <= c_din[7:0];
                default: cache_tag_way_1cache_block_way_0[index] <= cache_tag_way_1cache_block_way_0[index];
            endcase
            end
            1:begin
                case(p_wen)
                4'b1111: cache_tag_way_1cache_block_way_1[index] <= c_din; //SW
                4'b1100: cache_tag_way_1cache_block_way_1[index][31:16] <= c_din[31:16]; //SH
                4'b0011: cache_tag_way_1cache_block_way_1[index][15:0] <= c_din[15:0];
                4'b1000: cache_tag_way_1cache_block_way_1[index][31:24] <= c_din[31:24]; //SB
                4'b0100: cache_tag_way_1cache_block_way_1[index][23:16] <= c_din[23:16];
                4'b0010: cache_tag_way_1cache_block_way_1[index][15:8] <= c_din[15:8];
                4'b0001: cache_tag_way_1cache_block_way_1[index][7:0] <= c_din[7:0];
                default: cache_tag_way_1cache_block_way_1[index] <= cache_tag_way_1cache_block_way_1[index];
            endcase
            end
        endcase
    end
end
always @(posedge clk) begin
        if(clrn) begin
            pLRU <= 1'b0;
        end
        else begin
            if(p_strobe & hit) begin
                if     (hit_way==0) begin
                    pLRU[0] <= 1'b1;
                end
                else if(hit_way==1) begin
                    pLRU[0] <= 1'b0;
                end
            end
        end
    end
//read from cache
//wire valid = ((cache_valid_way_0 [index] & p_ren) == p_ren)||((cache_valid_way_01[index] & p_ren) == p_ren); //cache_valid_way_0  should be "larger" than p_ren, 1100 & 1000 = 1000 √ 1000 & 1110 = 1000 ×
//wire [T_WIDTH-1 : 0] tagout = cache_tag_way_0 [index];
wire [31:0] c_dout = hit ? (hit_way==0 ? cache_block_way_0[index] :
                             hit_way==1 ? cache_block_way_1[index] : 0) : 0;

//cache control
wire cache_hit =( (((cache_valid_way_0 [index] & p_ren) == p_ren) & (cache_tag_way_0 [index] == tag))|
(((cache_valid_way_1[index] & p_ren) == p_ren) & (cache_tag_way_1[index] == tag)) )& ~flush_except ;//hit
wire cache_miss = ~cache_hit;
wire hit_way=(cache_valid_way_0 [index] & tag==cache_tag_way_0 [index]) ? 0 :
                      (cache_valid_way_1[index] & tag==cache_tag_way_1[index]) ? 1 : 0;
wire [1:0] cache_way_switch;  //被替换的路号
assign cache_way_switch =  ~pLRU[0] ? 0 : 1;
wire miss_cache_way_dirty;
    assign miss_cache_way_dirty = cache_way_switch==0 ? cache_dirty_way_0[index] :
                                   cache_way_switch==1 ? cache_dirty_way_1[index] :0;
wire [TAG_WIDTH-1:0] miss_cache_way_tag;
assign miss_cache_way_tag = cache_way_switch==0 ? cache_tag_way_0[index] :
                cache_way_switch==1 ? cache_tag_way_1[index] : 0;
wire [31:0] miss_dirty_block;
assign miss_dirty_block = cache_way_switch==0 ? cache_block_way_0[index] :
                cache_way_switch==1 ? cache_block_way_1[index] :0;
wire read, write;
assign write = p_rw;
assign read = ~write;



assign m_din = p_dout;
//??cache???????????????
assign m_a = (p_a[31:16] == 16'hbfaf) ? {16'h1faf,p_a[15:0]}: p_a; 
assign m_rw = p_strobe & p_rw; //write through
assign m_strobe = p_strobe & (p_rw | cache_miss);
assign p_ready = ~p_rw & cache_hit | (cache_miss | p_rw) & m_ready;
wire c_write = (p_rw | cache_miss & m_ready);
wire sel_in = p_rw;
wire sel_out = cache_hit;
wire [31:0] c_din = sel_in ? p_dout : m_dout;
assign p_din = sel_out ? c_dout :m_dout;

endmodule-