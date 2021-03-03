`include "defines.v"
/*`define LINE_SIZE 256//每条cache line长度 256=32bytes 512=64bytes
`define RAM_TIMES 8//取出整个line所需要的周期数（256/32=8）
`define ADDR_LENTH 32//寻址长度*/

module ram (

input wire clk,
input wire rst,

L3ram interface_p1,

/*input wire re_p1_i,//read
input wire [`ADDR_LENTH-1:0] raddr_p1_i,
output reg [`LINE_SIZE-1:0] rdata_p1_o,
output reg read_hit_p1_o,
input wire we_p1_i,//write
input wire [`ADDR_LENTH-1:0] waddr_p1_i,
input wire [`LINE_SIZE-1:0] wdata_p1_i,
output reg write_hit_p1_o,*/

/*input wire interface_p1.re_L3_ram,//read
input wire [`ADDR_LENTH-1:0] interface_p1.raddr_L3_ram,
output reg [`LINE_SIZE-1:0] interface_p1.rdata_L3_ram,
output reg interface_p1.read_hit_L3_ram,
input wire interface_p1.we_L3_ram,//write
input wire [`ADDR_LENTH-1:0] interface_p1.waddr_L3_ram,
input wire [`LINE_SIZE-1:0] interface_p1.wdata_L3_ram,
output reg interface_p1.write_hit_L3_ram,*/

output reg writing_o//state 状态
);

reg[7:0] ram_in[0:(`RAM_NUM*4) - 1];
reg[31:0] ram [0:`RAM_NUM-1];//ram
integer i;
//测试用，初始化测试代码
always@(negedge rst)begin
        $readmemh("D:/verilog------------------------------/tinyriscv/rtl9/data_in.txt",ram_in);
        for(i=0;i<`RAM_NUM;i=i+1) ram[i]<={{ram_in[3+4*i]},{ram_in[2+4*i]},{ram_in[1+4*i]},{ram_in[0+4*i]}};
end

integer i;
reg [7:0] read_times;
reg [31:0] read_ram_cache [0:7];
always @ (posedge clk) begin
        if(rst == `Enable) begin
            interface_p1.read_hit_L3_ram <= `Disable;
            interface_p1.rdata_L3_ram <= `ZeroWord256;
            read_times <= `ZeroWord256;
            read_ram_cache[0] <= `ZeroWord256;
            read_ram_cache[1] <= `ZeroWord256;
            read_ram_cache[2] <= `ZeroWord256;
            read_ram_cache[3] <= `ZeroWord256;
            read_ram_cache[4] <= `ZeroWord256;
            read_ram_cache[5] <= `ZeroWord256;
            read_ram_cache[6] <= `ZeroWord256;
            read_ram_cache[7] <= `ZeroWord256;
        end
        else if (interface_p1.re_L3_ram== `Enable&&read_times<8) begin
            interface_p1.read_hit_L3_ram <= `Disable;
            interface_p1.rdata_L3_ram <= `ZeroWord256;
            read_times <= read_times+1;
            read_ram_cache[read_times] <= ram[interface_p1.raddr_L3_ram+read_times];
        end
        else if (interface_p1.re_L3_ram == `Enable&&read_times==8) begin
            interface_p1.read_hit_L3_ram <= `Enable;
            interface_p1.rdata_L3_ram <= `ZeroWord256;
            read_times <= read_times+1;
            interface_p1.rdata_L3_ram <= {{read_ram_cache[7]},{read_ram_cache[6]},{read_ram_cache[5]},{read_ram_cache[4]},{read_ram_cache[3]},{read_ram_cache[2]},{read_ram_cache[1]},{read_ram_cache[0]}};
        end
        else if (interface_p1.re_L3_ram == `Enable&&read_times==9) begin
            interface_p1.read_hit_L3_ram <= `Disable;
            interface_p1.rdata_L3_ram <= `ZeroWord256;
            read_times <= `ZeroWord256;
            interface_p1.rdata_L3_ram <= `ZeroWord256;
        end
        else begin
            interface_p1.read_hit_L3_ram <= `Disable;
            interface_p1.rdata_L3_ram <= `ZeroWord256;
            read_times <= `ZeroWord256;
            read_ram_cache[0] <= `ZeroWord256;
            read_ram_cache[1] <= `ZeroWord256;
            read_ram_cache[2] <= `ZeroWord256;
            read_ram_cache[3] <= `ZeroWord256;
            read_ram_cache[4] <= `ZeroWord256;
            read_ram_cache[5] <= `ZeroWord256;
            read_ram_cache[6] <= `ZeroWord256;
            read_ram_cache[7] <= `ZeroWord256;
        end
end

reg [7:0] write_times;
reg [31:0] write_ram_cache [0:7];
always @ (negedge clk) begin
        if (interface_p1.we_L3_ram== `Enable&&write_times==0) begin
            interface_p1.write_hit_L3_ram <= `Disable;
            {{write_ram_cache[7]},{write_ram_cache[6]},{write_ram_cache[5]},{write_ram_cache[4]},{write_ram_cache[3]},{write_ram_cache[2]},{write_ram_cache[1]},{write_ram_cache[0]}} <= interface_p1.wdata_L3_ram;
            write_times <= write_times+1;
        end
        else if (interface_p1.we_L3_ram == `Enable&&write_times<9) begin
            interface_p1.write_hit_L3_ram <= `Disable;
            ram[interface_p1.waddr_L3_ram+write_times-1] <= write_ram_cache[write_times-1];
            write_times <= write_times+1;
        end
        else if (interface_p1.we_L3_ram == `Enable&&write_times==9) begin
            interface_p1.write_hit_L3_ram <= `Enable;
            write_times <= write_times+1;
        end
        else if (interface_p1.we_L3_ram == `Enable&&write_times==10) begin
            interface_p1.write_hit_L3_ram <= `Disable;
            write_times <= `ZeroWord256;
        end
        else begin
            interface_p1.read_hit_L3_ram <= `Disable;
            write_times <= `ZeroWord256;
        end
end





endmodule
