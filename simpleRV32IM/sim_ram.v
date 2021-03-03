`include "defines.v"

// simulation ram module
module sim_ram (

    input wire clk,
    input wire rst,
    input wire hold_flag_i,//hold
    input wire jump_flag_i,//jump

    input wire we_i,                     // write enable
    input wire[`SramAddrBus] waddr_i,    // write addr
    input wire[`SramBus] wdata_i,        // write data
    input wire[`SramType] wtype_i,        // write data

    input wire pc_re_i,                  // pc read enable
    input wire[`SramAddrBus] pc_raddr_i, // pc read addr
    output reg[`SramBus] pc_rdata_o,     // pc read data
    output reg[`SramAddrBus] pc_raddr_o,     // pc read data
    input wire[`SramType] pc_rtype_i,/////////////////////////////////////////////未使用

    input wire ex_re_i,                  // ex read enable
    input wire[`SramAddrBus] ex_raddr_i, // ex read addr
    output reg[`SramBus] ex_rdata_o,      // ex read data
    input wire[`SramType] ex_rtype_i

);

    reg[7:0] ram[0:(`SramMemNum*4) - 1];
   
    //测试用，初始化测试代码
    always@(negedge rst)begin
        $readmemh("D:/verilog------------------------------/tinyriscv/rtl/data_in.txt",ram);
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


//ex读写模块
    always @ (*) begin
    case(wtype_i)
        `SramByte:begin
            if (rst == `RstDisable && we_i == `WriteEnable) begin
            {ram[waddr_i+0]} <= wdata_i[7:0];
            end
        end
        `SramHalf:begin
            if (rst == `RstDisable && we_i == `WriteEnable) begin
            {ram[waddr_i+1],ram[waddr_i+0]} <= wdata_i[15:0];
            end
        end
        `SramWord:begin
            if (rst == `RstDisable && we_i == `WriteEnable) begin
            {ram[waddr_i+3],ram[waddr_i+2],ram[waddr_i+1],ram[waddr_i+0]} <= wdata_i[31:0];
            end
        end
    endcase
    end

    always @ (*) begin
    case(ex_rtype_i)
        `SramByte:begin
            if(rst == `RstEnable) begin
                ex_rdata_o <= `ZeroWord;
            end else if(ex_re_i == `ReadEnable) begin
                ex_rdata_o <= {{24{ram[ex_raddr_i+0][7]}},{ram[ex_raddr_i+0]}};
            end else begin
                ex_rdata_o <= `ZeroWord;
            end
        end
        `SramHalf:begin
            if(rst == `RstEnable) begin
                ex_rdata_o <= `ZeroWord;
            end else if(ex_re_i == `ReadEnable) begin
                ex_rdata_o <= {{16{ram[ex_raddr_i+1][7]}},{ram[ex_raddr_i+1]},{ram[ex_raddr_i+0]}};
            end else begin
                ex_rdata_o <= `ZeroWord;
            end
        end
        `SramWord:begin
            if(rst == `RstEnable) begin
                ex_rdata_o <= `ZeroWord;
            end else if(ex_re_i == `ReadEnable) begin
                ex_rdata_o <= {ram[ex_raddr_i+3],ram[ex_raddr_i+2],ram[ex_raddr_i+1],ram[ex_raddr_i+0]};
            end else begin
                ex_rdata_o <= `ZeroWord;
            end
        end
    endcase
    end
endmodule
