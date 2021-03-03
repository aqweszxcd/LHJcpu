`include "defines.v"

/*`define SET_NUM_L1D 4//������������
`define LINE_NUM_L1D 16//cache line����
`define LINE_SIZE_L1D 256//ÿ��cache line���� 256=32bytes 512=64bytes
`define ADDR_LENTH_L1D 32//Ѱַ����
`define SET_NUM_L1D_BIT 2//������������
`define LINE_NUM_L1D_BIT 4//cache line����
`define LINE_SIZE_L1D_BIT 5//ÿ��cache line���� 256=32bytes 512=64bytes*/
// simulation ram module
module L1D (
input wire clk,
input wire rst,



L1DL2 interface_m,

input wire re_p1_i,//read
input wire [`ADDR_LENTH_L1D-1:0] raddr_p1_i,
output reg [`LINE_SIZE_L1D-1:0] rdata_p1_o,
output reg read_hit_p1_o,
input wire we_p1_i,//write
input wire [`ADDR_LENTH_L1D-1:0] waddr_p1_i,
input wire [`LINE_SIZE_L1D-1:0] wdata_p1_i,
output reg write_hit_p1_o,

/*output reg interface_m.re_L1D_L2,//read
output reg [`ADDR_LENTH_L1D-1:0] interface_m.raddr_L1D_L2,
input wire [`LINE_SIZE_L3-1:0] interface_m.rdata_L1D_L2,
input wire interface_m.read_hit_L1D_L2,
output reg interface_m.we_L1D_L2,//write
output reg [`ADDR_LENTH_L1D-1:0] interface_m.waddr_L1D_L2,
output reg [`LINE_SIZE_L3-1:0] interface_m.wdata_L1D_L2,
input wire interface_m.write_hit_L1D_L2,*/


output reg writing_o//state ״̬
);

reg[`LINE_SIZE_L1D-1:0] ram [0:`LINE_NUM_L1D-1][0:`SET_NUM_L1D-1];//ram
reg[`ADDR_LENTH_L1D-`LINE_NUM_L1D_BIT-`LINE_SIZE_L1D_BIT-1:0] ram_tag[0:`LINE_NUM_L1D-1][0:`SET_NUM_L1D-1];//�ж��Ƿ����е�tag(��Ѱַ�ռ�32bit)
reg[1:0] ram_MESI [0:`LINE_NUM_L1D-1][0:`SET_NUM_L1D-1];//�Ƿ����ڵȴ�д���¼�����
reg[`SET_NUM_L1D_BIT:0] ram_replace [0:`LINE_NUM_L1D-1][0:`SET_NUM_L1D-1];//cache�滻����Replacement strategy MQ2

/*
RISCV��WMO����ҪMESI ֻ��ҪMEI ����߳�֮��ͬ����fence.i 
M(Modified)������������Ч�����ݱ��޸��ˣ����ڴ��е����ݲ�һ�£�����ֻ�����ڱ�Cache�С�11
E(Exclusive)������������Ч�����ݺ��ڴ��е�����һ�£�����ֻ�����ڱ�Cache�С�10
S(Shared)������������Ч�����ݺ��ڴ��е�����һ�£����ݴ����ںܶ�Cache�С�01
I(Invalid)������������Ч��00
*/

//��ȡ������posedge clk д��������negedge clk  �첽���� �Է�ֹ��ͻ

integer i,n,m;
always @ (posedge clk) begin
if (rst == `Enable) begin
        interface_m.re_L1D_L2<=`Disable;
        for(i=0;i<`LINE_NUM_L1D;i=i+1)begin
                for(n=0;n<`SET_NUM_L1D;n=n+1)begin
                        ram_MESI[i][n] <= `ZeroWord256;
                        ram_replace[i][n] <= `ZeroWord256;
                end
        end
end
else begin

        if (re_p1_i == `Enable) begin//1��ȡ 2����ȡ
                for(i=0,n=0,m=0;i<`SET_NUM_L1D;i=i+1)begin
                        if(ram_tag[raddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]==raddr_p1_i[`ADDR_LENTH_L1D-1:`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT]&&ram_MESI[raddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]!=`MESI_I)begin//1����2δ����
                                rdata_p1_o<=ram[raddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i];
                                read_hit_p1_o<=`Enable;
                                ram_replace[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=3'b100;//cache�滻����Replacement strategy MQ2(Ŀǰ��ʱ����Ϊ1 ���޸�)
                                n++;
                        end
                        else begin
                                if(n<1)begin
                                        rdata_p1_o<=`ZeroWord;
                                        read_hit_p1_o<=`Disable;
                                end
                        end
                end
                if(interface_m.re_L1D_L2==`Disable)begin
                        if(n==0)begin
                                interface_m.re_L1D_L2<=`Enable;
                                interface_m.raddr_L1D_L2<=raddr_p1_i;
                        end
                end
        end
        
        else begin                                                                              //1����ȡ 2����ȡ
                                rdata_p1_o<=`ZeroWord;
                                read_hit_p1_o<=`Disable;
        end
        
if(interface_m.write_hit_L1D_L2==`Enable)begin//���дm hit ����m flag
        interface_m.we_L1D_L2<=`Disable;
        interface_m.waddr_L1D_L2<=`ZeroWord;
end
        
end
end

/*
32bitѰַ
��·������
cacheline size 32Byte offset5bit
256�� index8bit
tag 19bit
addr `ADDR_LENTH_L1D-1:`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT `LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:5 4:0 
*/
always @ (negedge clk) begin
if(interface_m.read_hit_L1D_L2==`Enable&&interface_m.re_L1D_L2==`Enable)begin
        interface_m.re_L1D_L2<=`Disable;
        interface_m.raddr_L1D_L2<=`ZeroWord;
        for(i=0,n=0;i<`SET_NUM_L1D&&n<1;i=i+1)begin
                if(ram_MESI[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]==`MESI_I)begin
                        n++;
                        ram[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=interface_m.rdata_L1D_L2;//ram
                        ram_tag[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=interface_m.raddr_L1D_L2[`ADDR_LENTH_L1D-1:`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT];//�ж��Ƿ����е�tag(��Ѱַ�ռ�32bit)
                        ram_MESI[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=`MESI_E;//�Ƿ����ڵȴ�д���¼�����
                        ram_replace[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=3'b100;//cache�滻����Replacement strategy MQ2(Ŀǰ��ʱ����Ϊ1 ���޸�)
                end
                else if(ram_replace[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]==3'b000)begin
                        n++;
                        ram[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=interface_m.rdata_L1D_L2;//ram
                        ram_tag[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=interface_m.raddr_L1D_L2[`ADDR_LENTH_L1D-1:`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT];//�ж��Ƿ����е�tag(��Ѱַ�ռ�32bit)
                        ram_MESI[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=ram_MESI[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i];//�Ƿ����ڵȴ�д���¼�����
                        ram_replace[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=3'b100;//cache�滻����Replacement strategy MQ2
                end
        end
end
else if(we_p1_i==`Enable)begin
        for(i=0,n=0;i<`SET_NUM_L1D;i=i+1)begin
                if(ram_tag[waddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]==waddr_p1_i[`ADDR_LENTH_L1D-1:`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT]&&ram_MESI[waddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]!=`MESI_I)begin//д������
                        ram[waddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=wdata_p1_i;
                        write_hit_p1_o<=`Enable;
                        n++;
                end
                else begin                                                              //д��δ����
                        write_hit_p1_o<=`Disable;
                end
        end
        if(interface_m.we_L1D_L2==`Disable)begin
                if(n==0)begin
                        interface_m.we_L1D_L2<=`Enable;
                        interface_m.waddr_L1D_L2<=waddr_p1_i;
                        interface_m.wdata_L1D_L2<=wdata_p1_i;
                end
        end
end
else begin
        if(interface_m.we_L1D_L2==`Disable)begin                           //����ʱ����д��
                for(i=0,m=0;i<`SET_NUM_L1D&&m<1;i=i+1)begin
                        for(n=0;n<`SET_NUM_L1D;n=n+1)begin
                                if(ram_MESI [i][n]==`MESI_M)begin
                                        interface_m.we_L1D_L2<=`Enable;
                                        interface_m.waddr_L1D_L2<={{ram_tag[i][n]},{i},{5'b00000}};
                                        interface_m.wdata_L1D_L2<=ram[i][n];
                                        ram_MESI[i][n]<=`MESI_E;
                                        m++;
                                end
                        end
                end
        end
end

        
end

//Ȩ���½���posedge clk
always@(posedge clk)begin


if(interface_m.read_hit_L1D_L2==`Enable)begin
        for(i=0;i<`SET_NUM_L1D;i=i+1)begin
                if(ram_replace[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]>0)begin
                        ram_replace[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=ram_replace[interface_m.raddr_L1D_L2[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]-1;//������Ȩ���½�
                end
        end
end
else if(write_hit_p1_o==`Enable)begin
        for(i=0;i<`SET_NUM_L1D;i=i+1)begin
                if(ram_replace[waddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]>0)begin
                        ram_replace[waddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=ram_replace[waddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]-1;//������Ȩ���½�
                end
        end
end

for(i=0,m=0;i<`LINE_NUM_L1D;i=i+1)begin//�Ƿ��������¼�д��
        for(n=0;n<`SET_NUM_L1D;n=n+1)begin
                if(ram_MESI [i][n]==`MESI_M) m++;
        end
end
if(m>0)writing_o<=`Enable;
else writing_o<=`Disable;

end

//Ȩ���½���negedge clk
always@(negedge clk)begin

if(read_hit_p1_o==`Enable)begin
        for(i=0;i<`SET_NUM_L1D;i=i+1)begin
                if(ram_replace[raddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]>0)begin
                        ram_replace[raddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]<=ram_replace[raddr_p1_i[`LINE_NUM_L1D_BIT+`LINE_SIZE_L1D_BIT-1:`LINE_SIZE_L1D_BIT]][i]-1;//������Ȩ���½�
                end
        end
end

end




endmodule
