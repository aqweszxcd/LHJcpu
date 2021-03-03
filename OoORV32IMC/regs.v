`include "defines.v"

// common reg module
module regs (
input wire clk,
input wire rst,
//write
input wire we_jump_0_i,                  // reg write enable
input wire[`RegAddrBus] waddr_jump_0_i,  // reg write addr
input wire[`RegBus] wdata_jump_0_i,      // reg write data
input wire we_mem_0_i,                  // reg write enable
input wire[`RegAddrBus] waddr_mem_0_i,  // reg write addr
input wire[`RegBus] wdata_mem_0_i,      // reg write data
input wire we_int_0_i,                  // reg write enable
input wire[`RegAddrBus] waddr_int_0_i,  // reg write addr
input wire[`RegBus] wdata_int_0_i,      // reg write data
input wire we_int_1_i,                  // reg write enable
input wire[`RegAddrBus] waddr_int_1_i,  // reg write addr
input wire[`RegBus] wdata_int_1_i,      // reg write data
//read
output wire[1023:0] reg_rdata_o       // reg read data
);

reg[`RegBus] regs[0:`RegNum - 1];
assign reg_rdata_o={{regs[31]},{regs[30]},{regs[29]},{regs[28]},{regs[27]},{regs[26]},{regs[25]},{regs[24]},{regs[23]},{regs[22]},{regs[21]},{regs[20]},{regs[19]},{regs[18]},{regs[17]},{regs[16]},{regs[15]},{regs[14]},{regs[13]},{regs[12]},{regs[11]},{regs[10]},{regs[9]},{regs[8]},{regs[7]},{regs[6]},{regs[5]},{regs[4]},{regs[3]},{regs[2]},{regs[1]},{32{1'b0}}};

integer i,clear;
always @ (posedge clk) begin

if (rst == `Enable) begin
        for(clear=0;clear<32;clear=clear+1)begin
                regs[clear]<=`ZeroWord;
        end
end

else begin
        for(i=0;i<32;i=i+1)begin
                if(we_jump_0_i==`Enable&&waddr_jump_0_i==i) regs[i]<=wdata_jump_0_i;
                else if(we_mem_0_i==`Enable&&waddr_mem_0_i==i) regs[i]<=wdata_mem_0_i;
                else if(we_int_0_i==`Enable&&waddr_int_0_i==i) regs[i]<=wdata_int_0_i;
                else if(we_int_1_i==`Enable&&waddr_int_1_i==i) regs[i]<=wdata_int_1_i;
                else regs[i]<=regs[i];
        end
end

end


endmodule
