`include "defines.v"

/*`define SET_NUM_L1I 4//组相联组数量
`define LINE_NUM_L1I 16//cache line数量
`define LINE_SIZE_L1I 256//每条cache line长度 256=32bytes 512=64bytes
`define ADDR_LENTH_L1I 32//寻址长度
`define SET_NUM_L1I_BIT 2//组相联组数量
`define LINE_NUM_L1I_BIT 4//cache line数量
`define LINE_SIZE_L1I_BIT 5//每条cache line长度 256=32bytes 512=64bytes*/
// simulation ram module
module L1I (
input wire clk,
input wire rst,

L1IL2 interface_m,

input wire re_p1_i,//read
input wire [`ADDR_LENTH_L1I-1:0] raddr_p1_i,
output reg [`LINE_SIZE_L1I-1:0] rdata_p1_o,
output reg read_hit_p1_o,

/*output reg interface_m.re_L1I_L2,//read
output reg [`ADDR_LENTH_L1I-1:0] interface_m.raddr_L1I_L2,
input wire [`LINE_SIZE_L3-1:0] interface_m.rdata_L1I_L2,
input wire interface_m.read_hit_L1I_L2,
output reg interface_m.we_L1I_L2,//write
output reg [`ADDR_LENTH_L1I-1:0] interface_m.waddr_L1I_L2,
output reg [`LINE_SIZE_L3-1:0] interface_m.wdata_L1I_L2,
input wire interface_m.write_hit_L1I_L2,
*/

output reg writing_o//state 状态
);

reg[`LINE_SIZE_L1I-1:0] ram [0:`LINE_NUM_L1I-1][0:`SET_NUM_L1I-1];//ram
reg[`ADDR_LENTH_L1I-`LINE_NUM_L1I_BIT-`LINE_SIZE_L1I_BIT-1:0] ram_tag[0:`LINE_NUM_L1I-1][0:`SET_NUM_L1I-1];//判断是否命中的tag(总寻址空间32bit)
reg[1:0] ram_MESI [0:`LINE_NUM_L1I-1][0:`SET_NUM_L1I-1];//是否正在等待写入下级缓存
reg[`SET_NUM_L1I_BIT:0] ram_replace [0:`LINE_NUM_L1I-1][0:`SET_NUM_L1I-1];//cache替换策略Replacement strategy MQ2

/*
RISCV的WMO不需要MESI 只需要MEI 多核线程之间同步靠fence.i 
M(Modified)：这行数据有效，数据被修改了，和内存中的数据不一致，数据只存在于本Cache中。11
E(Exclusive)：这行数据有效，数据和内存中的数据一致，数据只存在于本Cache中。10
S(Shared)：这行数据有效，数据和内存中的数据一致，数据存在于很多Cache中。01
I(Invalid)：这行数据无效。00
*/

//读取运行在posedge clk 写入运行在negedge clk  异步进行 以防止冲突

integer i,n,m;
always @ (posedge clk) begin
if (rst == `Enable) begin
        interface_m.re_L1I_L2<=`Disable;
        for(i=0;i<`LINE_NUM_L1I;i=i+1)begin
                for(n=0;n<`SET_NUM_L1I;n=n+1)begin
                        ram_MESI[i][n] <= `ZeroWord256;
                        ram_replace[i][n] <= `ZeroWord256;
                end
        end
end
else begin

        if (re_p1_i == `Enable) begin//1读取 2不读取
                for(i=0,n=0,m=0;i<`SET_NUM_L1I;i=i+1)begin
                        if(ram_tag[raddr_p1_i[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]==raddr_p1_i[`ADDR_LENTH_L1I-1:`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT]&&ram_MESI[raddr_p1_i[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]!=`MESI_I)begin//1命中2未命中
                                rdata_p1_o<=ram[raddr_p1_i[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i];
                                read_hit_p1_o<=`Enable;
                                ram_replace[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                                n++;
                        end
                        else begin
                                if(n<1)begin
                                        rdata_p1_o<=`ZeroWord;
                                        read_hit_p1_o<=`Disable;
                                end
                        end
                end
                if(interface_m.re_L1I_L2==`Disable)begin
                        if(n==0)begin
                                interface_m.re_L1I_L2<=`Enable;
                                interface_m.raddr_L1I_L2<=raddr_p1_i;
                        end
                end
        end
        
        else begin                                                                              //1不读取 2不读取
                                rdata_p1_o<=`ZeroWord;
                                read_hit_p1_o<=`Disable;
        end
        
        
end
end

/*
32bit寻址
四路组相联
cacheline size 32Byte offset5bit
256组 index8bit
tag 19bit
addr `ADDR_LENTH_L1I-1:`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT `LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:5 4:0 
*/
always @ (negedge clk) begin
if(interface_m.read_hit_L1I_L2==`Enable&&interface_m.re_L1I_L2==`Enable)begin
        interface_m.re_L1I_L2<=`Disable;
        interface_m.raddr_L1I_L2<=`ZeroWord;
        for(i=0,n=0;i<`SET_NUM_L1I&&n<1;i=i+1)begin
                if(ram_MESI[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]==`MESI_I)begin
                        n++;
                        ram[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=interface_m.rdata_L1I_L2;//ram
                        ram_tag[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=interface_m.raddr_L1I_L2[`ADDR_LENTH_L1I-1:`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT];//判断是否命中的tag(总寻址空间32bit)
                        ram_MESI[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=`MESI_E;//是否正在等待写入下级缓存
                        ram_replace[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                end
                else if(ram_replace[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]==3'b000)begin
                        n++;
                        ram[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=interface_m.rdata_L1I_L2;//ram
                        ram_tag[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=interface_m.raddr_L1I_L2[`ADDR_LENTH_L1I-1:`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT];//判断是否命中的tag(总寻址空间32bit)
                        ram_MESI[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=ram_MESI[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i];//是否正在等待写入下级缓存
                        ram_replace[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2
                end
        end
end
        
end

//权重下降在posedge clk
always@(posedge clk)begin
if(interface_m.read_hit_L1I_L2==`Enable)begin
        for(i=0;i<`SET_NUM_L1I;i=i+1)begin
                if(ram_replace[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]>0)begin
                        ram_replace[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=ram_replace[interface_m.raddr_L1I_L2[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]-1;//其他项权重下降
                end
        end
end
end

//权重下降在negedge clk
always@(negedge clk)begin
if(read_hit_p1_o==`Enable)begin
        for(i=0;i<`SET_NUM_L1I;i=i+1)begin
                if(ram_replace[raddr_p1_i[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]>0)begin
                        ram_replace[raddr_p1_i[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]<=ram_replace[raddr_p1_i[`LINE_NUM_L1I_BIT+`LINE_SIZE_L1I_BIT-1:`LINE_SIZE_L1I_BIT]][i]-1;//其他项权重下降
                end
        end
end
end


endmodule

