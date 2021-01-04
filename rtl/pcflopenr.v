`timescale 1ns / 1ps

//参考https://github.com/JF2098/A-simple-MIPS-CPU/tree/master/rtl
module pcflopenrc #(parameter WIDTH = 8)(
    input wire clk,rst,en,flush,
    input wire[WIDTH-1:0] d,
    input wire[WIDTH-1:0] newpc,
    output reg[WIDTH-1:0] q
    );

initial begin
    q<=32'hbfc00000;
end

always @(posedge clk) begin
    if(rst)
        q <= 32'hbfc00000;
    else if(flush)
        q <= newpc;
    else if(en)
        q <= d;
    else
        q <= q;
end
endmodule
