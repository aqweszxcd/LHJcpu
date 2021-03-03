`include "defines.v"

// simulation ram module //64bit
module L1 (

input wire clk,
input wire rst,
input wire jump_flag_i,
input wire [`RegBus] jump_addr_i,
input wire hold_flag_i,
input wire [`RegBus] hold_addr_i,
    

input wire inst_re_i,                  // pc read enable
input wire[`SramAddrBus] inst_raddr_i, // pc read addr
output reg inst_re_o,
output reg[`DoubleSramBus] inst_rdata_o,     // pc read data
output reg[`SramAddrBus] inst_raddr_o,     // pc read addr

//ex_a write
input wire data_we_i,                     // write enable
input wire[`SramAddrBus] data_waddr_i,    // write addr
input wire[`SramBus] data_wdata_i,        // write data
//ex_a read
input wire data_re_i,                  // read enable
input wire[`SramAddrBus] data_raddr_i, // read addr
output reg data_re_o,                  // read enable
output reg[`SramBus] data_rdata_o      // read data
);

reg[`DoubleSramBus] ram[0:(`SramMemNum/2) - 1];
reg[7:0] ram_in[0:(`SramMemNum*4) - 1];
integer i;
//²âÊÔÓÃ£¬³õÊ¼»¯²âÊÔ´úÂë
always@(negedge rst)begin
        $readmemh("D:/verilog------------------------------/tinyriscv/rtl6/data.txt",ram_in);
        for(i=0;i<(`SramMemNum/2);i=i+1) ram[i]<={{ram_in[7+8*i]},{ram_in[6+8*i]},{ram_in[5+8*i]},{ram_in[4+8*i]},{ram_in[3+8*i]},{ram_in[2+8*i]},{ram_in[1+8*i]},{ram_in[0+8*i]}};
end
    
/*always @ (posedge clk) begin
        if (rst == `Disable && we_i == `Enable) begin
        ram[waddr_i>>3] <= wdata_i;
        end
end*/
always @ (posedge clk) begin
        if(rst == `Enable || hold_flag_i == `Enable || jump_flag_i == `Enable) begin
            inst_re_o <= `Disable;
            inst_rdata_o <= `ZeroWord256;
            inst_raddr_o <= `ZeroWord256;
        end else if(inst_re_i == `Enable) begin
            inst_re_o <= `Enable;
            inst_rdata_o <=  ram[inst_raddr_i>>3];
            inst_raddr_o <= inst_raddr_i;
        end else begin
            inst_re_o <= `Disable;
            inst_rdata_o <= `ZeroWord256;
            inst_raddr_o <= `ZeroWord256;
        end
end

always @ (posedge clk) begin
        if(rst == `Enable) begin
            data_re_o <= `Disable;
            data_rdata_o <= `ZeroWord256;
        end
        else if (data_re_i == `Enable && data_we_i == `Enable&&(data_raddr_i[31:3]==data_waddr_i[31:3])) begin
            if((data_raddr_i[2]==1'b0)&&(data_waddr_i[2]==1'b0))begin
            ram[data_waddr_i>>3] <= {{ram[data_waddr_i>>3][63:32]},{data_wdata_i}};
            data_re_o <= `Enable;
            data_rdata_o <=  data_wdata_i;
            end
            else if((data_raddr_i[2]==1'b1)&&(data_waddr_i[2]==1'b1))begin
            ram[data_waddr_i>>3] <= {{data_wdata_i},{ram[data_waddr_i>>3][31:0]}};
            data_re_o <= `Enable;
            data_rdata_o <=  data_wdata_i;
            end
            else if((data_raddr_i[2]==1'b1)&&(data_waddr_i[2]==1'b0))begin
            ram[data_waddr_i>>3] <= {{ram[data_waddr_i>>3][63:32]},{data_wdata_i}};
            data_re_o <= `Enable;
            data_rdata_o <=  ram[data_raddr_i>>3][63:32];
            end
            else if((data_raddr_i[2]==1'b0)&&(data_waddr_i[2]==1'b1))begin
            ram[data_waddr_i>>3] <= {{data_wdata_i},{ram[data_waddr_i>>3][31:0]}};
            data_re_o <= `Enable;
            data_rdata_o <=  ram[data_raddr_i>>3][31:0];
            end
        end
        else if (data_re_i == `Disable && data_we_i == `Enable) begin
            if(data_waddr_i[2]==1'b0)begin
            data_re_o <= `Disable;
            data_rdata_o <= `ZeroWord256;
            ram[data_waddr_i>>3] <= {{ram[data_waddr_i>>3][63:32]},{data_wdata_i}};
            end
            else if(data_waddr_i[2]==1'b1)begin
            data_re_o <= `Disable;
            data_rdata_o <= `ZeroWord256;
            ram[data_waddr_i>>3] <= {{data_wdata_i},{ram[data_waddr_i>>3][31:0]}};
            end
        end
        else if (data_re_i == `Enable && data_we_i == `Disable) begin
            if(data_raddr_i[2]==1'b0)begin
            data_re_o <= `Enable;
            data_rdata_o <=  ram[data_raddr_i>>3][31:0];
            end
            else if(data_raddr_i[2]==1'b1)begin
            data_re_o <= `Enable;
            data_rdata_o <=  ram[data_raddr_i>>3][63:32];
            end
        end
        else if (data_re_i == `Disable && data_we_i == `Disable) begin
            data_re_o <= `Disable;
            data_rdata_o <= `ZeroWord256;
        end
        else begin
            data_re_o <= `Disable;
            data_rdata_o <= `ZeroWord256;
        end
end


endmodule
