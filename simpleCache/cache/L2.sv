`include "defines.v"
//(目前暂时队列为1 待修改)
//we_m_o and re_m_o 应该在hit上升沿被清理?

/*
32bit寻址
四路组相联
cacheline size 32Byte offset5bit
256组 index8bit
tag 19bit
addr 31:13 12:5 4:0 
*/

/*`define SET_NUM 4//组相联组数量
`define LINE_NUM 256//cache line数量
`define LINE_SIZE 256//每条cache line长度 256=32bytes 512=64bytes
`define ADDR_LENTH 32//寻址长度
`define SET_NUM_BIT 2//组相联组数量
`define LINE_NUM_BIT 8//cache line数量
`define LINE_SIZE_BIT 5//每条cache line长度 256=32bytes 512=64bytes*/

//18=`ADDR_LENTH-`LINE_NUM_BIT-`LINE_SIZE_BIT-1
//13=`LINE_NUM_BIT+`LINE_SIZE_BIT
//12=`LINE_NUM_BIT+`LINE_SIZE_BIT-1
//5=`LINE_SIZE_BIT

/*
32bit寻址
四路组相联
cacheline size 32Byte offset5bit
256组 index8bit
tag 19bit
addr 31:13 12:5 4:0 
*/
/*`define SET_NUM_L2 4//组相联组数量
`define LINE_NUM_L2 64//cache line数量
`define LINE_SIZE_L2 256//每条cache line长度 256=32bytes 512=64bytes
`define ADDR_LENTH_L2 32//寻址长度
`define SET_NUM_L2_BIT 2//组相联组数量
`define LINE_NUM_L2_BIT 6//cache line数量
`define LINE_SIZE_L2_BIT 5//每条cache line长度 256=32bytes 512=64bytes*/

module L2 (
L1IL2 interface_p2,//p2在模块中读
L1DL2 interface_p1,//p1在模块中读写
L2L3 interface_m,

input wire clk,
input wire rst,

/*input wire interface_p1.re_L1D_L2,//read
input wire [`ADDR_LENTH_L2-1:0] interface_p1.raddr_L1D_L2,
output reg [`LINE_SIZE_L2-1:0] interface_p1.rdata_L1D_L2,
output reg interface_p1.read_hit_L1D_L2,
input wire interface_p1.we_L1D_L2,//write
input wire [`ADDR_LENTH_L2-1:0] interface_p1.waddr_L1D_L2,
input wire [`LINE_SIZE_L2-1:0] interface_p1.wdata_L1D_L2,
output reg interface_p1.write_hit_L1D_L2,


input wire interface_p2.re_L1I_L2,//read
input wire [`ADDR_LENTH_L2-1:0] interface_p2.raddr_L1I_L2,
output reg [`LINE_SIZE_L2-1:0] interface_p2.rdata_L1I_L2,
output reg interface_p2.read_hit_L1I_L2,*/
//input wire we_p2_i,//write
//input wire [`ADDR_LENTH_L2-1:0] waddr_p2_i,
//input wire [`LINE_SIZE_L2-1:0] wdata_p2_i,
//output reg write_hit_p2_o,


//output reg interface_m.re_L2_L3,//read
//output reg [`ADDR_LENTH_L2-1:0] interface_m.raddr_L2_L3,
//input wire [`LINE_SIZE_L2-1:0] interface_m.rdata_L2_L3,
//input wire interface_m.read_hit_L2_L3,
//output reg interface_m.we_L2_L3,//write
//output reg [`ADDR_LENTH_L2-1:0] interface_m.waddr_L2_L3,
//output reg [`LINE_SIZE_L2-1:0] interface_m.wdata_L2_L3,
//input wire interface_m.write_hit_L2_L3,


output reg writing_o//state 状态
);

reg[`LINE_SIZE_L2-1:0] ram [0:`LINE_NUM_L2-1][0:`SET_NUM_L2-1];//ram
reg[`ADDR_LENTH_L2-`LINE_NUM_L2_BIT-`LINE_SIZE_L2_BIT-1:0] ram_tag[0:`LINE_NUM_L2-1][0:`SET_NUM_L2-1];//判断是否命中的tag(总寻址空间32bit)
reg[1:0] ram_MESI [0:`LINE_NUM_L2-1][0:`SET_NUM_L2-1];//是否正在等待写入下级缓存
reg[`SET_NUM_L2_BIT:0] ram_replace [0:`LINE_NUM_L2-1][0:`SET_NUM_L2-1];//cache替换策略Replacement strategy MQ2

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
        interface_m.re_L2_L3<=`Disable;
        for(i=0;i<`LINE_NUM_L2;i=i+1)begin
                for(n=0;n<`SET_NUM_L2;n=n+1)begin
                        ram_MESI[i][n] <= `ZeroWord256;
                        ram_replace[i][n] <= `ZeroWord256;
                end
        end
end
else begin
        unique if (interface_p1.re_L1D_L2 == `Enable&&interface_p2.re_L1I_L2 == `Enable) begin//1读取 2读取
                for(i=0,n=0,m=0;i<`SET_NUM_L2;i=i+1)begin
                        if(ram_tag[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==interface_p1.raddr_L1D_L2[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT]&&ram_MESI[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]!=`MESI_I&&ram_tag[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==interface_p2.raddr_L1I_L2[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT]&&ram_MESI[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]!=`MESI_I)begin//1命中2命中
                                interface_p1.rdata_L1D_L2<=ram[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i];
                                interface_p1.read_hit_L1D_L2<=`Enable;
                                interface_p2.rdata_L1I_L2<=ram[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i];
                                interface_p2.read_hit_L1I_L2<=`Enable;
                                ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                                n++;
                                m++;
                        end
                        else if(ram_tag[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==interface_p1.raddr_L1D_L2[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT]&&ram_MESI[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]!=`MESI_I)begin//1命中2未命中
                                interface_p1.rdata_L1D_L2<=ram[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i];
                                interface_p1.read_hit_L1D_L2<=`Enable;
                                interface_p2.rdata_L1I_L2<=`ZeroWord;
                                interface_p2.read_hit_L1I_L2<=`Disable;
                                ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                                n++;
                        end
                        else if(ram_tag[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==interface_p2.raddr_L1I_L2[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT]&&ram_MESI[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]!=`MESI_I)begin//1未命中2命中
                                interface_p1.rdata_L1D_L2<=`ZeroWord;
                                interface_p1.read_hit_L1D_L2<=`Disable;
                                interface_p2.rdata_L1I_L2<=ram[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i];
                                interface_p2.read_hit_L1I_L2<=`Enable;
                                ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                                m++;
                        end
                        else begin
                                if(n<1)begin
                                        interface_p1.rdata_L1D_L2<=`ZeroWord;
                                        interface_p1.read_hit_L1D_L2<=`Disable;
                                end
                                if(m<1)begin
                                        interface_p2.rdata_L1I_L2<=`ZeroWord;
                                        interface_p2.read_hit_L1I_L2<=`Disable;
                                end
                        end
                end
                if(interface_m.re_L2_L3==`Disable)begin
                        unique if(n==0&&m==0)begin
                                interface_m.re_L2_L3<=`Enable;
                                interface_m.raddr_L2_L3<=interface_p1.raddr_L1D_L2;
                        end
                        else if(n==1&&m==0)begin
                                interface_m.re_L2_L3<=`Enable;
                                interface_m.raddr_L2_L3<=interface_p2.raddr_L1I_L2;
                        end
                        else if(n==0&&m==1)begin
                                interface_m.re_L2_L3<=`Enable;
                                interface_m.raddr_L2_L3<=interface_p1.raddr_L1D_L2;
                        end
                end
        end

        else if (interface_p1.re_L1D_L2 == `Enable&&interface_p2.re_L1I_L2 == `Disable) begin//1读取 2不读取
                for(i=0,n=0,m=0;i<`SET_NUM_L2;i=i+1)begin
                        if(ram_tag[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==interface_p1.raddr_L1D_L2[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT]&&ram_MESI[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]!=`MESI_I)begin//1命中2未命中
                                interface_p1.rdata_L1D_L2<=ram[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i];
                                interface_p1.read_hit_L1D_L2<=`Enable;
                                interface_p2.rdata_L1I_L2<=`ZeroWord;
                                interface_p2.read_hit_L1I_L2<=`Disable;
                                ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                                n++;
                        end
                        else begin
                                if(n<1)begin
                                        interface_p1.rdata_L1D_L2<=`ZeroWord;
                                        interface_p1.read_hit_L1D_L2<=`Disable;
                                end
                                interface_p2.rdata_L1I_L2<=`ZeroWord;
                                interface_p2.read_hit_L1I_L2<=`Disable;
                        end
                end
                if(interface_m.re_L2_L3==`Disable)begin
                        if(n==0)begin
                                interface_m.re_L2_L3<=`Enable;
                                interface_m.raddr_L2_L3<=interface_p1.raddr_L1D_L2;
                        end
                end
        end
        
        else if (interface_p1.re_L1D_L2 == `Disable&&interface_p2.re_L1I_L2 == `Enable) begin//1不读取 2读取
                for(i=0,n=0,m=0;i<`SET_NUM_L2;i=i+1)begin
                        if(ram_tag[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==interface_p2.raddr_L1I_L2[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT]&&ram_MESI[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]!=`MESI_I)begin//1未命中2命中
                                interface_p1.rdata_L1D_L2<=`ZeroWord;
                                interface_p1.read_hit_L1D_L2<=`Disable;
                                interface_p2.rdata_L1I_L2<=ram[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i];
                                interface_p2.read_hit_L1I_L2<=`Enable;
                                ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                                m++;
                        end
                        else begin
                                interface_p1.rdata_L1D_L2<=`ZeroWord;
                                interface_p1.read_hit_L1D_L2<=`Disable;
                                if(m<1)begin
                                        interface_p2.rdata_L1I_L2<=`ZeroWord;
                                        interface_p2.read_hit_L1I_L2<=`Disable;
                                end
                        end
                end
                if(interface_m.re_L2_L3==`Disable)begin
                        if(m==0)begin
                                interface_m.re_L2_L3<=`Enable;
                                interface_m.raddr_L2_L3<=interface_p2.raddr_L1I_L2;
                        end
                end
        end
        
        else begin                                                                              //1不读取 2不读取
                                interface_p1.rdata_L1D_L2<=`ZeroWord;
                                interface_p1.read_hit_L1D_L2<=`Disable;
                                interface_p2.rdata_L1I_L2<=`ZeroWord;
                                interface_p2.read_hit_L1I_L2<=`Disable;
        end
        
if(interface_m.write_hit_L2_L3==`Enable)begin//如果写m hit 清理m flag
        interface_m.we_L2_L3<=`Disable;
        interface_m.waddr_L2_L3<=`ZeroWord;
end
        
end
end

/*
32bit寻址
四路组相联
cacheline size 32Byte offset5bit
256组 index8bit
tag 19bit
addr `ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT `LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:5 4:0 
*/
always @ (negedge clk) begin
if(interface_m.read_hit_L2_L3==`Enable&&interface_m.re_L2_L3==`Enable)begin
        interface_m.re_L2_L3<=`Disable;
        interface_m.raddr_L2_L3<=`ZeroWord;
        for(i=0,n=0;i<`SET_NUM_L2&&n<1;i=i+1)begin
                if(ram_MESI[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==`MESI_I)begin
                        n++;
                        ram[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=interface_m.rdata_L2_L3;//ram
                        ram_tag[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=interface_m.raddr_L2_L3[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT];//判断是否命中的tag(总寻址空间32bit)
                        ram_MESI[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=`MESI_E;//是否正在等待写入下级缓存
                        ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2(目前暂时队列为1 待修改)
                end
                else if(ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==3'b000)begin
                        n++;
                        ram[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=interface_m.rdata_L2_L3;//ram
                        ram_tag[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=interface_m.raddr_L2_L3[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT];//判断是否命中的tag(总寻址空间32bit)
                        ram_MESI[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=ram_MESI[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i];//是否正在等待写入下级缓存
                        ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=3'b100;//cache替换策略Replacement strategy MQ2
                end
        end
end
else if(interface_p1.we_L1D_L2==`Enable)begin
        for(i=0,n=0;i<`SET_NUM_L2;i=i+1)begin
                if(ram_tag[interface_p1.waddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]==interface_p1.waddr_L1D_L2[`ADDR_LENTH_L2-1:`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT]&&ram_MESI[interface_p1.waddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]!=`MESI_I)begin//写入命中
                        ram[interface_p1.waddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=interface_p1.wdata_L1D_L2;
                        interface_p1.write_hit_L1D_L2<=`Enable;
                        n++;
                end
                else begin                                                              //写入未命中
                        interface_p1.write_hit_L1D_L2<=`Disable;
                end
        end
        if(interface_m.we_L2_L3==`Disable)begin
                if(n==0)begin
                        interface_m.we_L2_L3<=`Enable;
                        interface_m.waddr_L2_L3<=interface_p1.waddr_L1D_L2;
                        interface_m.wdata_L2_L3<=interface_p1.wdata_L1D_L2;
                end
        end
end
else begin
        if(interface_m.we_L2_L3==`Disable)begin                           //空闲时向下写入
                for(i=0,m=0;i<`SET_NUM_L2&&m<1;i=i+1)begin
                        for(n=0;n<`SET_NUM_L2;n=n+1)begin
                                if(ram_MESI [i][n]==`MESI_M)begin
                                        interface_m.we_L2_L3<=`Enable;
                                        interface_m.waddr_L2_L3<={{ram_tag[i][n]},{i},{5'b00000}};
                                        interface_m.wdata_L2_L3<=ram[i][n];
                                        ram_MESI[i][n]<=`MESI_E;
                                        m++;
                                end
                        end
                end
        end
end

        
end

//权重下降在posedge clk
always@(posedge clk)begin


if(interface_m.read_hit_L2_L3==`Enable)begin
        for(i=0;i<`SET_NUM_L2;i=i+1)begin
                if(ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]>0)begin
                        ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=ram_replace[interface_m.raddr_L2_L3[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]-1;//其他项权重下降
                end
        end
end
else if(interface_p1.write_hit_L1D_L2==`Enable)begin
        for(i=0;i<`SET_NUM_L2;i=i+1)begin
                if(ram_replace[interface_p1.waddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]>0)begin
                        ram_replace[interface_p1.waddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=ram_replace[interface_p1.waddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]-1;//其他项权重下降
                end
        end
end

for(i=0,m=0;i<`LINE_NUM_L2;i=i+1)begin//是否正在向下级写入
        for(n=0;n<`SET_NUM_L2;n=n+1)begin
                if(ram_MESI [i][n]==`MESI_M) m++;
        end
end
if(m>0)writing_o<=`Enable;
else writing_o<=`Disable;

end

//权重下降在negedge clk
always@(negedge clk)begin


if(interface_p1.read_hit_L1D_L2==`Enable&&interface_p2.read_hit_L1I_L2==`Enable)begin
        for(i=0;i<`SET_NUM_L2;i=i+1)begin
                if(ram_replace[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]>0)begin
                        ram_replace[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=ram_replace[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]-1;//其他项权重下降
                end
        end
end
else if(interface_p1.read_hit_L1D_L2==`Enable&&interface_p2.read_hit_L1I_L2==`Disable)begin
        for(i=0;i<`SET_NUM_L2;i=i+1)begin
                if(ram_replace[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]>0)begin
                        ram_replace[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=ram_replace[interface_p1.raddr_L1D_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]-1;//其他项权重下降
                end
        end
end
else if(interface_p1.read_hit_L1D_L2==`Disable&&interface_p2.read_hit_L1I_L2==`Enable)begin
        for(i=0;i<`SET_NUM_L2;i=i+1)begin
                if(ram_replace[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]>0)begin
                        ram_replace[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]<=ram_replace[interface_p2.raddr_L1I_L2[`LINE_NUM_L2_BIT+`LINE_SIZE_L2_BIT-1:`LINE_SIZE_L2_BIT]][i]-1;//其他项权重下降
                end
        end
end


end




endmodule
