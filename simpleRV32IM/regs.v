`include "defines.v"

// common reg module
module regs (

    input wire clk,
    input wire rst,

    input wire we_i,                  // reg write enable
    input wire[`RegAddrBus] waddr_i,  // reg write addr
    input wire[`RegBus] wdata_i,      // reg write data

    input wire re1_i,                 // reg1 read enable
    input wire[`RegAddrBus] raddr1_i, // reg1 read addr
    output reg[`RegBus] rdata1_o,     // reg1 read data

    input wire re2_i,                 // reg2 read enable
    input wire[`RegAddrBus] raddr2_i, // reg2 read addr
    output reg[`RegBus] rdata2_o      // reg2 read data

);

    reg[`RegBus] regs[0:`RegNum - 1];

    always @ (*) begin
        if (rst == `RstDisable) begin
            if((we_i == `WriteEnable) && (waddr_i != `RegNumLog2'h0)) begin
                regs[waddr_i] <= wdata_i;
            end
        end
    end

    always @ (*) begin
        if(rst == `RstEnable || raddr1_i == `RegNumLog2'h0) begin
            rdata1_o <= `ZeroWord;
        end 
        else if(re1_i == `ReadEnable) begin
            if(raddr1_i == waddr_i && we_i==`WriteEnable) rdata1_o<=wdata_i;
            else rdata1_o <= regs[raddr1_i];
        end 
        else begin
            rdata1_o  <= `ZeroWord;
        end
    end

    always @ (*) begin
        if(rst == `RstEnable || raddr2_i == `RegNumLog2'h0) begin
            rdata2_o <= `ZeroWord;
        end 
        else if(re2_i == `ReadEnable) begin
            if(raddr2_i == waddr_i && we_i==`WriteEnable) rdata2_o<=wdata_i;
            else rdata2_o <= regs[raddr2_i];
        end 
        else begin
            rdata2_o <= `ZeroWord;
        end
    end

endmodule
