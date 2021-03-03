`include "defines.v"

// simulation ram module
module cache_ctrl (
input wire clk,
input wire rst,
//////////////////////////////////////////////////////////////////////////inst

output reg inst_valid_o,
output reg [`SramBus] inst_o,
//input wire re_p2_i,                  // pc read enable
//input wire[`SramAddrBus] raddr_p2_i, // pc read addr
//output reg read_hit_p2_o,                  // pc read enable
//output reg[`SramBus] rdata_p2_o,     // pc read data
//////////////////////////////////////////////////////////////////////////data
input wire re_p1_i,                  // ex read enable
input wire[`SramAddrBus] raddr_p1_i, // ex read addr
output wire read_hit_p1_o,
output wire[`SramBus] rdata_p1_o,      // ex read data

input wire we_p1_i,                     // write enable
input wire[`SramAddrBus] waddr_p1_i,    // write addr
input wire[`SramBus] wdata_p1_i,        // write data
output wire write_hit_p1_o,

///////////////////////////pc_reg
input wire jump_flag_i,
input wire[`RegBus] jump_addr_i,
input wire hold_flag_i,
input wire[`RegBus] hold_addr_i,
output reg[`SramAddrBus] pc_o,
output reg re_o
);
///////////////////////////pc_reg
reg[`SramAddrBus] offset;
always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            pc_o <= `ZeroWord;
            offset <= `ZeroWord;
        end else if (jump_flag_i == `JumpEnable) begin
            pc_o <= jump_addr_i;
            offset <= jump_addr_i +4;
        end else if (hold_flag_i == `HoldEnable) begin
            pc_o <= hold_addr_i;
            offset <= hold_addr_i;
        end else begin
            pc_o <= offset;
            offset <= offset + 4'h4;
        end
    end
always @ (posedge clk) begin
        if (rst == `RstEnable) re_o <= `ReadDisable;
        else re_o <= `ReadEnable;
end
///////////////////////////pc_reg

/*assign hold_flag_o=(pc_re_i^pc_re_o)&&(we_i^we_o)&&(ex_re_i^ex_re_o);

//////////////////////////////////////////////////////////////////////////cache
wire re_p1_i;//read
wire [`ADDR_LENTH-1:0] raddr_p1_i;
wire [`LINE_SIZE-1:0] rdata_p1_o;
wire read_hit_p1_o;
wire re_p2_i;//read
wire [`ADDR_LENTH-1:0] raddr_p2_i;
wire [`LINE_SIZE-1:0] rdata_p2_o;
wire read_hit_p2_o;
wire we_p1_i;//write
wire [`ADDR_LENTH-1:0] waddr_p1_i;
wire [`LINE_SIZE-1:0] wdata_p1_i;
wire write_hit_p1_o;


assign re_p1_i=ex_re_i;//read
assign raddr_p1_i;
assign ex_rdata_o=rdata_p1_o;
assign ex_re_o=read_hit_p1_o;
assign we_p1_i=we_i;//write
assign waddr_p1_i=waddr_i;
assign wdata_p1_i=wdata_i;
assign we_o=write_hit_p1_o;

assign re_p2_i;//read
assign raddr_p2_i;
assign rdata_p2_o;
assign read_hit_p2_o;*/



//input wire ex_re_i,                  // ex read enable
//input wire[`SramAddrBus] ex_raddr_i, // ex read addr




reg clk_L1,clk_L2,clk_L3;
reg [7:0]reg_clk_L1,reg_clk_L2,reg_clk_L3;
always@(posedge clk)begin
if(rst==`Enable)begin
clk_L1<=0;clk_L2<=0;clk_L3<=0;
reg_clk_L1<=0;reg_clk_L2<=0;reg_clk_L3<=0;
end
else begin
if(clk_L1==0)begin reg_clk_L1<=0;clk_L1<=~clk_L1;end else reg_clk_L1<=reg_clk_L1+1;
if(clk_L2==3)begin reg_clk_L2<=0;clk_L2<=~clk_L2;end else reg_clk_L2<=reg_clk_L2+1;
if(clk_L3==15)begin reg_clk_L3<=0;clk_L3<=~clk_L3;end else reg_clk_L3<=reg_clk_L3+1;
end
end

cache cache(
.rst(rst),
.clk_L1(clk_L1),
.clk_L2(clk_L2),
.clk_L3(clk_L3),

.re_p1_i(re_p1_i),//read
.raddr_p1_i(raddr_p1_i),
.rdata_p1_o(rdata_p1_o),
.read_hit_p1_o(read_hit_p1_o),
.re_p2_i(re_p2_i),//read
.raddr_p2_i(raddr_p2_i),
.rdata_p2_o(rdata_p2_o),
.read_hit_p2_o(read_hit_p2_o),
.we_p1_i(we_p1_i),//write
.waddr_p1_i(waddr_p1_i),
.wdata_p1_i(wdata_p1_i),
.write_hit_p1_o(write_hit_p1_o)
);








endmodule









