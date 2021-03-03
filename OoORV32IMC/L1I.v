`include "defines.v"

// simulation ram module //64bit
module L1I (

input wire clk,
input wire rst,
input wire jump_flag_i,
input wire [`RegBus] jump_addr_i,
input wire hold_flag_i,
input wire [`RegBus] hold_addr_i,
    
//input wire we_i,                     // write enable                                    //未使用
//input wire[`SramAddrBus] waddr_i,    // write addr                                    //未使用
//input wire[`DoubleSramBus] wdata_i,        // write data                                    //未使用

input wire re_i,                  // pc read enable
input wire[`SramAddrBus] raddr_i, // pc read addr
output reg re_o,
output reg[`DoubleSramBus] rdata_o,     // pc read data
output reg[`SramAddrBus] raddr_o     // pc read addr
);

reg[`DoubleSramBus] ram[0:(`SramMemNum/2) - 1];
reg[7:0] ram_in[0:(`SramMemNum*4) - 1];
integer i;
//测试用，初始化测试代码
always@(negedge rst)begin
        $readmemh("D:/verilog------------------------------/tinyriscv/rtl5/data.txt",ram_in);
        for(i=0;i<(`SramMemNum/2);i=i+1) ram[i]<={{ram_in[7+8*i]},{ram_in[6+8*i]},{ram_in[5+8*i]},{ram_in[4+8*i]},{ram_in[3+8*i]},{ram_in[2+8*i]},{ram_in[1+8*i]},{ram_in[0+8*i]}};
end
    
/*always @ (posedge clk) begin
        if (rst == `Disable && we_i == `Enable) begin
        ram[waddr_i>>3] <= wdata_i;
        end
end*/
always @ (posedge clk) begin
        if(rst == `Enable || hold_flag_i == `Enable || jump_flag_i == `Enable) begin
            re_o <= `Disable;
            rdata_o <= `ZeroWord256;
            raddr_o <= `ZeroWord256;
        end else if(re_i == `Enable) begin
            re_o <= `Enable;
            rdata_o <=  ram[raddr_i>>3];
            raddr_o <= raddr_i;
        end else begin
            re_o <= `Disable;
            rdata_o <= `ZeroWord256;
            raddr_o <= `ZeroWord256;
        end
end



endmodule
