`include "defines.v"

// simulation ram module
module L1I (

    input wire clk,
    input wire rst,
    input wire hold_flag_i,//hold
    input wire jump_flag_i,//jump

    input wire pc_re_i,                  // pc read enable
    input wire[`SramAddrBus] pc_raddr_i, // pc read addr
    output reg[`SramBus] pc_rdata_o,     // pc read data
    output reg[`SramAddrBus] pc_raddr_o,     // pc read data
    input wire[`SramType] pc_rtype_i/////////////////////////////////////////////未使用

);

    reg[7:0] ram[0:(`SramMemNum*4) - 1];
   
    //测试用，初始化测试代码
    always@(negedge rst)begin
        $readmemh("D:/verilog------------------------------/tinyriscv/rtl/data.txt",ram);
    end
    
    always @ (posedge clk) begin
        if(rst == `RstEnable || hold_flag_i == `HoldEnable || jump_flag_i == `JumpEnable) begin
            pc_rdata_o <= `ZeroWord;
            pc_raddr_o <= `ZeroWord;
        end else if(pc_re_i == `ReadEnable) begin
            pc_rdata_o <=  {ram[pc_raddr_i+3],ram[pc_raddr_i+2],ram[pc_raddr_i+1],ram[pc_raddr_i+0]};
            pc_raddr_o <= pc_raddr_i;
        end else begin
            pc_rdata_o <= `ZeroWord;
            pc_raddr_o <= `ZeroWord;
        end
    end

endmodule
