`include "defines.v"

interface L1IL2;
logic re_L1I_L2;
logic [`ADDR_LENTH-1:0] raddr_L1I_L2;
logic [`LINE_SIZE-1:0] rdata_L1I_L2;
logic read_hit_L1I_L2;
modport L1I (output re_L1I_L2,output raddr_L1I_L2,input rdata_L1I_L2,input read_hit_L1I_L2);
modport L2 (input re_L1I_L2,input raddr_L1I_L2,output rdata_L1I_L2,output read_hit_L1I_L2);
endinterface : L1IL2

interface L1DL2;
logic re_L1D_L2;
logic [`ADDR_LENTH-1:0] raddr_L1D_L2;
logic [`LINE_SIZE-1:0] rdata_L1D_L2;
logic read_hit_L1D_L2;
logic we_L1D_L2;
logic [`ADDR_LENTH-1:0] waddr_L1D_L2;
logic [`LINE_SIZE-1:0] wdata_L1D_L2;
logic write_hit_L1D_L2;
modport L1D (output re_L1D_L2,output raddr_L1D_L2,input rdata_L1D_L2,input read_hit_L1D_L2,output we_L1D_L2,output waddr_L1D_L2,output wdata_L1D_L2,input write_hit_L1D_L2);
modport L2 (input re_L1D_L2,input raddr_L1D_L2,output rdata_L1D_L2,output read_hit_L1D_L2,input we_L1D_L2,input waddr_L1D_L2,input wdata_L1D_L2,output write_hit_L1D_L2);
endinterface : L1DL2

interface L2L3;
logic re_L2_L3;
logic [`ADDR_LENTH-1:0] raddr_L2_L3;
logic [`LINE_SIZE-1:0] rdata_L2_L3;
logic read_hit_L2_L3;
logic we_L2_L3;
logic [`ADDR_LENTH-1:0] waddr_L2_L3;
logic [`LINE_SIZE-1:0] wdata_L2_L3;
logic write_hit_L2_L3;
modport L2 (output re_L2_L3,output raddr_L2_L3,input rdata_L2_L3,input read_hit_L2_L3,output we_L2_L3,output waddr_L2_L3,output wdata_L2_L3,input write_hit_L2_L3);
modport L3 (input re_L2_L3,input raddr_L2_L3,output rdata_L2_L3,output read_hit_L2_L3,input we_L2_L3,input waddr_L2_L3,input wdata_L2_L3,output write_hit_L2_L3);
endinterface : L2L3

interface L3ram;
logic re_L3_ram;
logic [`ADDR_LENTH-1:0] raddr_L3_ram;
logic [`LINE_SIZE-1:0] rdata_L3_ram;
logic read_hit_L3_ram;
logic we_L3_ram;
logic [`ADDR_LENTH-1:0] waddr_L3_ram;
logic [`LINE_SIZE-1:0] wdata_L3_ram;
logic write_hit_L3_ram;
modport L3 (output re_L3_ram,output raddr_L3_ram,input rdata_L3_ram,input read_hit_L3_ram,output we_L3_ram,output waddr_L3_ram,output wdata_L3_ram,input write_hit_L3_ram);
modport ram (input re_L3_ram,input raddr_L3_ram,output rdata_L3_ram,output read_hit_L3_ram,input we_L3_ram,input waddr_L3_ram,input wdata_L3_ram,output write_hit_L3_ram);
endinterface : L3ram

module cache(
input wire rst,
input wire clk_L1,
input wire clk_L2,
input wire clk_L3,
///////////////////L1I
input wire re_p2_i,//read
input wire [`ADDR_LENTH_L1I-1:0] raddr_p2_i,
output reg [`LINE_SIZE_L1I-1:0] rdata_p2_o,
output reg read_hit_p2_o,
//////////////////////L1D
input wire re_p1_i,//read
input wire [`ADDR_LENTH_L1D-1:0] raddr_p1_i,
output reg [`LINE_SIZE_L1D-1:0] rdata_p1_o,
output reg read_hit_p1_o,
input wire we_p1_i,//write
input wire [`ADDR_LENTH_L1D-1:0] waddr_p1_i,
input wire [`LINE_SIZE_L1D-1:0] wdata_p1_i,
output reg write_hit_p1_o
);

L1IL2 L1I_L2();//实例化接口
L1DL2 L1D_L2();//实例化接口
L2L3 L2_L3();//实例化接口
L3ram L3_ram();//实例化接口

L1I L1I_0 (
.clk(clk_L1),
.rst(rst),

.re_p1_i(re_p2_i),
.raddr_p1_i(raddr_p2_i),
.rdata_p1_o(rdata_p2_o),
.read_hit_p1_o(read_hit_p2_o),

.interface_m(L1I_L2. L1I),
.writing_o()
);

L1D L1D_0 (
.clk(clk_L1),
.rst(rst),

.re_p1_i(re_p1_i),//read
.raddr_p1_i(raddr_p1_i),
.rdata_p1_o(rdata_p1_o),
.read_hit_p1_o(read_hit_p1_o),
.we_p1_i(we_p1_i),//write
.waddr_p1_i(waddr_p1_i),
.wdata_p1_i(wdata_p1_i),
.write_hit_p1_o(write_hit_p1_o),

.interface_m(L1D_L2. L1D),
.writing_o()
);

L2 L2_0 (
.clk(clk_L2),
.rst(rst),
.interface_p2(L1I_L2. L2),
.interface_p1(L1D_L2. L2),
.interface_m(L2_L3. L2),
.writing_o()
);

L3 L3_0 (
.clk(clk_L3),
.rst(rst),
.interface_p1(L2_L3.L3),
.interface_m(L3_ram.L3),
.writing_o()
);

ram ram_0 (
.clk(clk_L3),
.rst(rst),
.interface_p1(L3_ram.ram),
.writing_o()
);

endmodule

