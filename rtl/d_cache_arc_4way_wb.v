module d_cache_arc(
    input wire clk, rst,
    //mips core
    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,
    //错误0106必须有flush的逻辑
    input       no_dcache,flush_except,

    //axi interface
    output         cache_data_req     ,
    output         cache_data_wr      ,
    output  [1 :0] cache_data_size    ,
    output  [31:0] cache_data_addr    ,
    output  [31:0] cache_data_wdata   ,
    
    input   [31:0] cache_data_rdata   ,
    input          cache_data_addr_ok ,
    input          cache_data_data_ok 
    );


    
    //Cache����
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    parameter WAY_CNT       = 4;                                    //·��
    
    //Cache�洢��Ԫ
    //��Чλ
    reg                 cache_valid_way_0 [CACHE_DEEPTH - 1 : 0];   //0·
    reg                 cache_valid_way_1 [CACHE_DEEPTH - 1 : 0];   //1·
    reg                 cache_valid_way_2 [CACHE_DEEPTH - 1 : 0];   //2·
    reg                 cache_valid_way_3 [CACHE_DEEPTH - 1 : 0];   //3·
    //��λ
    reg                 cache_dirty_way_0 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty_way_1 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty_way_2 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty_way_3 [CACHE_DEEPTH - 1 : 0];
    //��־λ
    reg [TAG_WIDTH-1:0] cache_tag_way_0   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag_way_1   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag_way_2   [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag_way_3   [CACHE_DEEPTH - 1 : 0];
    //����λ
    reg [31:0]          cache_block_way_0 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block_way_1 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block_way_2 [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block_way_3 [CACHE_DEEPTH - 1 : 0];
    reg [WAY_CNT-2:0] pLRU;                         //����αLRU�㷨Ҫ�õ����ʹ����Ϣ

    //���ʵ�ַ�ֽ�
    wire [OFFSET_WIDTH-1:0] offset;     //�ֽ�ƫ����
    wire [INDEX_WIDTH-1:0] index;       //���λ
    wire [TAG_WIDTH-1:0] tag;           //��־λ
    
    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    //�ж�4·���Ƿ������е�·
    wire hit, miss;
    wire [1:0] hit_way;         //���е�·��
    //不经过dcahce时
     wire hit_other=no_dcache&cache_data_data_ok;
    assign hit     = ((cache_valid_way_0[index] & tag==cache_tag_way_0[index]) ||
                      (cache_valid_way_1[index] & tag==cache_tag_way_1[index]) ||
                      (cache_valid_way_2[index] & tag==cache_tag_way_2[index]) ||
                      (cache_valid_way_3[index] & tag==cache_tag_way_3[index]));
    assign hit_way = (cache_valid_way_0[index] & tag==cache_tag_way_0[index]) ? 0 :
                      (cache_valid_way_1[index] & tag==cache_tag_way_1[index]) ? 1 :
                      (cache_valid_way_2[index] & tag==cache_tag_way_2[index]) ? 2 :
                      (cache_valid_way_3[index] & tag==cache_tag_way_3[index]) ? 3 : 0;
    assign miss    = ~hit;
    
    //���ȱʧ��ѡ��һ�����滻��·�������·����ģ�����·������д���ڴ�
    wire [1:0] cache_way_switch;  //���滻��·��
    assign cache_way_switch =  ~pLRU[0] ? (~pLRU[1] ? 0 : 1) : (~pLRU[2] ? 2 : 3);
    wire miss_cache_way_dirty;
    assign miss_cache_way_dirty = cache_way_switch==0 ? cache_dirty_way_0[index] :
                                   cache_way_switch==1 ? cache_dirty_way_1[index] :
                                   cache_way_switch==2 ? cache_dirty_way_2[index] :
                                   cache_way_switch==3 ? cache_dirty_way_3[index] : 0;
    wire [TAG_WIDTH-1:0] miss_cache_way_tag;
    assign miss_cache_way_tag = cache_way_switch==0 ? cache_tag_way_0[index] :
                                   cache_way_switch==1 ? cache_tag_way_1[index] :
                                   cache_way_switch==2 ? cache_tag_way_2[index] :
                                   cache_way_switch==3 ? cache_tag_way_3[index] : 0;
    wire [31:0] miss_dirty_block;
    assign miss_dirty_block = cache_way_switch==0 ? cache_block_way_0[index] :
                                   cache_way_switch==1 ? cache_block_way_1[index] :
                                   cache_way_switch==2 ? cache_block_way_2[index] :
                                   cache_way_switch==3 ? cache_block_way_3[index] : 0;

    //����д
    wire read, write;
    assign write = cpu_data_wr;
    assign read = ~write;
    
    //���ڴ�
    //����read_req, addr_rcv, read_finish���ڹ�����sram�źš�
    wire read_req;      //һ�������Ķ����񣬴ӷ��������󵽽���
    reg addr_rcv;       //��ַ���ճɹ�(addr_ok)�󵽽���
    wire read_finish;   //���ݽ��ճɹ�(data_ok)�������������
    always @(posedge clk) begin
        if(~no_dcache)begin
        addr_rcv <= rst ? 1'b0 :
                    read & cache_data_req & cache_data_addr_ok ? 1'b1 :
                    read_finish ? 1'b0 : addr_rcv;
        end
    end
     reg [1:0] state;
    assign read_req = state==RM;
    assign read_finish = read_req & cache_data_data_ok;
    
    //д�ڴ�
    wire write_req;     
    reg waddr_rcv;      
    wire write_finish;   
    always @(posedge clk) begin
        if(~no_dcache)begin
        waddr_rcv <= rst ? 1'b0 :
                     cache_data_req & cache_data_addr_ok ? 1'b1 :
                     write_finish ? 1'b0 : waddr_rcv;
        end
    end
    assign write_req = state==WM;
    assign write_finish = write_req & cache_data_data_ok;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
   
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else if(~no_dcache)begin
            case(state)
            //如果不走cache，直接找结果
                IDLE:   state <= 
                                cpu_data_req & hit&~flush_except ? IDLE :
                                 cpu_data_req & miss_cache_way_dirty ? WM :
                                 cpu_data_req & read ? RM :
                                 cpu_data_req & write ? IDLE : 0;
                RM:     state <= read_finish ? IDLE : RM;
                WM:     state <= read & write_finish ? RM : write & write_finish ? IDLE : WM;
            endcase
        end
    end
        
    //������У�����Cache line
    wire [31:0] c_block;
    assign c_block = hit ? (hit_way==0 ? cache_block_way_0[index] :
                             hit_way==1 ? cache_block_way_1[index] :
                             hit_way==2 ? cache_block_way_2[index] :
                             hit_way==3 ? cache_block_way_3[index] : 0) : 0;
                                   
    always @(posedge clk) begin
        if(rst) begin
            pLRU <= 3'b000;
        end
        else begin
            if(cpu_data_req & hit&~no_dcache) begin
                if     (hit_way==0) begin
                    pLRU[1] <= 1'b1;
                    pLRU[0] <= 1'b1;
                end
                else if(hit_way==1) begin
                    pLRU[1] <= 1'b0;
                    pLRU[0] <= 1'b1;
                end
                else if(hit_way==2) begin
                    pLRU[2] <= 1'b1;
                    pLRU[0] <= 1'b0;
                end
                else if(hit_way==3) begin
                    pLRU[2] <= 1'b0;
                    pLRU[0] <= 1'b0;
                end
            end
        end
    end
   
    //output to mips core
    assign cpu_data_rdata   = hit ? c_block : cache_data_rdata;
//    assign cpu_data_addr_ok = cpu_data_req & hit | cache_data_req & cache_data_addr_ok;
//    assign cpu_data_data_ok = cpu_data_req & hit | cache_data_data_ok;
    assign cpu_data_addr_ok = cpu_data_data_ok;
    assign cpu_data_data_ok = cpu_data_req & hit&~no_dcache;

    //output to axi interface
    //assign cache_data_req   = read_req & ~addr_rcv | write_req & ~waddr_rcv;
    assign cache_data_req   = read_req | write_req;
    assign cache_data_wr    = write_req ? 1 : 0;
    assign cache_data_size  = cpu_data_size;
    assign cache_data_addr  = read_req  ? cpu_data_addr : 
                               write_req ? {miss_cache_way_tag, index, offset} : 0;
    assign cache_data_wdata = miss_dirty_block;
    
    wire [31:0] write_cache_data;
    wire [3:0] write_mask;

    //���ݵ�ַ����λ��size������д���루���sb��sh�Ȳ���д����һ���ֵ�ָ���4λ��Ӧ1���֣�4�ֽڣ���ÿ���ֵ�дʹ��
    assign write_mask = cpu_data_size==2'b00 ?
                            (cpu_data_addr[1] ? (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_data_size==2'b01 ? (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    //�����ʹ�ã�λΪ1�Ĵ�����Ҫ���µġ�
    //λ��չ��{8{1'b1}} -> 8'b11111111
    //new_data = old_data & ~mask | write_data & mask
    assign write_cache_data = (hit ? c_block : miss_dirty_block) & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};
    
    //д��Cache
    //�����ַ�е�tag, index����ֹaddr�����ı�
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    always @(posedge clk) begin
        if(~no_dcache)begin
        tag_save   <= rst ? 0 :
                      cpu_data_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_data_req ? index : index_save;
        end
    end

    integer t;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //��ʼ��cache�����ʹ����Ϣ
                cache_valid_way_0[t] <= 0;
                cache_valid_way_1[t] <= 0;
                cache_valid_way_2[t] <= 0;
                cache_valid_way_3[t] <= 0;
                
                cache_dirty_way_0[t] <= 0;
                cache_dirty_way_1[t] <= 0;
                cache_dirty_way_2[t] <= 0;
                cache_dirty_way_3[t] <= 0;
                
                pLRU                 <= 3'b000;
            end
        end
        else if(~no_dcache)begin
            if(cpu_data_req & write & hit) begin       // д���У�ֱ��д��cache
                case(hit_way)
                    0: begin
                        cache_dirty_way_0[index] <= 1'b1;
                        cache_block_way_0[index] <= write_cache_data;
                    end
                    1: begin
                        cache_dirty_way_1[index] <= 1'b1;
                        cache_block_way_1[index] <= write_cache_data;
                    end
                    2: begin
                        cache_dirty_way_2[index] <= 1'b1;
                        cache_block_way_2[index] <= write_cache_data;
                    end
                    3: begin
                        cache_dirty_way_3[index] <= 1'b1;
                        cache_block_way_3[index] <= write_cache_data;
                    end
                endcase
            end
            else if(cpu_data_req & write & miss) begin             //дȱʧ
                if(~miss_cache_way_dirty) begin     //������滻��·�Ǹɾ��ģ���ֱ��дcache line
                    case(cache_way_switch)
                        0: begin
                            cache_valid_way_0[index] <= 1'b1;
                            cache_dirty_way_0[index] <= 1'b1;
                            cache_tag_way_0[index]   <= tag;
                            cache_block_way_0[index] <= write_cache_data;
                            pLRU[1]                       <= 1'b1;
                            pLRU[0]                       <= 1'b1;
                        end
                        1: begin
                            cache_valid_way_1[index] <= 1'b1;
                            cache_dirty_way_1[index] <= 1'b1;
                            cache_tag_way_1[index]   <= tag;
                            cache_block_way_1[index] <= write_cache_data;
                            pLRU[1]                       <= 1'b0;
                            pLRU[0]                       <= 1'b1;
                        end
                        2: begin
                            cache_valid_way_2[index] <= 1'b1;
                            cache_dirty_way_2[index] <= 1'b1;
                            cache_tag_way_2[index]   <= tag;
                            cache_block_way_2[index] <= write_cache_data;
                            pLRU[2]                       <= 1'b1;
                            pLRU[0]                       <= 1'b0;
                        end
                        3: begin
                            cache_valid_way_3[index] <= 1'b1;
                            cache_dirty_way_3[index] <= 1'b1;
                            cache_tag_way_3[index]   <= tag;
                            cache_block_way_3[index] <= write_cache_data;
                            pLRU[2]                       <= 1'b0;
                            pLRU[0]                       <= 1'b0;
                        end
                    endcase
                end
                else if(write_finish) begin     //������滻��·����ģ���ȵ�д�ڴ������дcache line
                    case(cache_way_switch)
                        0: begin
                            cache_valid_way_0[index_save] <= 1'b1;
                            cache_dirty_way_0[index_save] <= 1'b1;
                            cache_tag_way_0[index_save]   <= tag_save;
                            cache_block_way_0[index_save] <= write_cache_data;
                            pLRU[1]                       <= 1'b1;
                            pLRU[0]                       <= 1'b1;
                        end
                        1: begin
                            cache_valid_way_1[index_save] <= 1'b1;
                            cache_dirty_way_1[index_save] <= 1'b1;
                            cache_tag_way_1[index_save]   <= tag_save;
                            cache_block_way_1[index_save] <= write_cache_data;
                            pLRU[1]                       <= 1'b0;
                            pLRU[0]                       <= 1'b1;
                        end
                        2: begin
                            cache_valid_way_2[index_save] <= 1'b1;
                            cache_dirty_way_2[index_save] <= 1'b1;
                            cache_tag_way_2[index_save]   <= tag_save;
                            cache_block_way_2[index_save] <= write_cache_data;
                            pLRU[2]                       <= 1'b1;
                            pLRU[0]                       <= 1'b0;
                        end
                        3: begin
                            cache_valid_way_3[index_save] <= 1'b1;
                            cache_dirty_way_3[index_save] <= 1'b1;
                            cache_tag_way_3[index_save]   <= tag_save;
                            cache_block_way_3[index_save] <= write_cache_data;
                            pLRU[2]                       <= 1'b0;
                            pLRU[0]                       <= 1'b0;
                        end
                    endcase
                end
            end
            else if(miss & read_finish) begin //��ȱʧ���ô����ʱ
                if(cache_way_switch==0) begin
                    cache_valid_way_0[index_save] <= 1'b1;
                    cache_dirty_way_0[index_save] <= 1'b0;
                    cache_tag_way_0[index_save]   <= tag_save;
                    cache_block_way_0[index_save] <= cache_data_rdata;
                    pLRU[1]                       <= 1'b1;
                    pLRU[0]                       <= 1'b1;
                end
                else if(cache_way_switch==1) begin                  //pLRU[1]Ϊ1����ʾ1·���δʹ��
                    cache_valid_way_1[index_save] <= 1'b1;
                    cache_dirty_way_1[index_save] <= 1'b0;
                    cache_tag_way_1[index_save]   <= tag_save;
                    cache_block_way_1[index_save] <= cache_data_rdata;
                    pLRU[1]                       <= 1'b0;
                    pLRU[0]                       <= 1'b1;
                end
                else if(cache_way_switch==2) begin
                    cache_valid_way_2[index_save] <= 1'b1;
                    cache_dirty_way_2[index_save] <= 1'b0;
                    cache_tag_way_2[index_save]   <= tag_save;
                    cache_block_way_2[index_save] <= cache_data_rdata;
                    pLRU[2]                       <= 1'b1;
                    pLRU[0]                       <= 1'b0;
                end
                else if(cache_way_switch==3) begin
                    cache_valid_way_3[index_save] <= 1'b1;
                    cache_dirty_way_3[index_save] <= 1'b0;
                    cache_tag_way_3[index_save]   <= tag_save;
                    cache_block_way_3[index_save] <= cache_data_rdata;
                    pLRU[2]                       <= 1'b0;
                    pLRU[0]                       <= 1'b0;
                end
            end
        end
    end
    
endmodule
