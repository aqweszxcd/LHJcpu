`include "defines.v"

// simulation ram module// 32bit
module L1D (
    input wire clk,
    input wire rst,
    //ex_a write
    input wire we_i,                     // write enable
    input wire[`SramAddrBus] waddr_i,    // write addr
    input wire[`SramBus] wdata_i,        // write data
    //ex_a read
    input wire re_i,                  // read enable
    input wire[`SramAddrBus] raddr_i, // read addr
    output reg re_o,                  // read enable
    output reg[`SramBus] rdata_o      // read data
);

   reg[`DoubleSramBus] ram[0:(`SramMemNum) - 1];
    
   reg[7:0] ram_in[0:(`SramMemNum*4) - 1];
   integer i;
    //测试用，初始化测试代码
    always@(negedge rst)begin
        $readmemh("D:/verilog------------------------------/tinyriscv/rtl5/data.txt",ram_in);
        for(i=0;i<`SramMemNum;i=i+1) ram[i]<={{ram_in[3+4*i]},{ram_in[2+4*i]},{ram_in[1+4*i]},{ram_in[0+4*i]}};
    end

always @ (posedge clk) begin
        if(rst == `Enable) begin
            re_o <= `Disable;
            rdata_o <= `ZeroWord256;
        end
        else if (re_i == `Enable && we_i == `Enable&&(raddr_i[31:2]==waddr_i[31:2])) begin
            ram[waddr_i>>2] <= wdata_i;
            re_o <= `Enable;
            rdata_o <=  wdata_i;
        end
        else if (re_i == `Disable && we_i == `Enable) begin
            ram[waddr_i>>2] <= wdata_i;
        end
        else if (re_i == `Enable && we_i == `Disable) begin
            re_o <= `Enable;
            rdata_o <=  ram[raddr_i>>2];
        end
        else if (re_i == `Disable && we_i == `Disable) begin
            re_o <= `Disable;
            rdata_o <= `ZeroWord256;
        end
        else begin
            re_o <= `Disable;
            rdata_o <= `ZeroWord256;
        end
end
    
endmodule
