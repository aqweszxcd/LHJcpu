
`include "defines.v"
//“取指”与“译码”
// identify module
module id_0 (

	input wire clk,
	input wire rst,
	input wire[`SramBus] inst_i,             // inst content
    input wire[`SramAddrBus] inst_addr_i,    // inst addr
    input wire jump_flag_i,
    input wire hold_flag_i,

    // to regs
    output reg reg1_re_o,                    // reg1 read enable
    output reg[`RegAddrBus] reg1_raddr_o,    // reg1 read addr
    output reg reg2_re_o,                    // reg2 read enable
    output reg[`RegAddrBus] reg2_raddr_o,    // reg2 read addr
    input wire [`RegBus] reg1_rdata_i,

    // to ex
    output reg inst_valid_o,                 // inst is valid flag
    output reg [`SramAddrBus] inst_addr_o,
    output reg [6:0] opcode_o,
    output reg [2:0] funct3_o,
    output reg [6:0] funct7_o,
    output reg [`RegBus] imm_I_o,
    output reg [`RegBus] imm_S_o,
    output reg [`RegBus] imm_B_o,
    output reg [`RegBus] imm_U_o,
    output reg [`RegBus] imm_J_o,
    output reg reg_we_o,                     // reg write enable
    output reg[`RegAddrBus] reg_waddr_o,     // reg write addr

    // to sram
    output reg sram_re_o,                    // ram read enable
    output wire [`SramAddrBus] sram_raddr_o,
    output reg sram_we_o,                     // ram write enable
    output reg [`SramType] ex_rtype_o

);
    
    //立即数是有符号数
    //关于补位，默认低位补0，高位默认补“最高位（31）”，补到[31：0]为止
    //不光立即数需要补位，执行部分中的结果也需要按照reference card的注释进行补位
    
    //指令拆解
    //注：虽然全部拆出来了，看起来很多，有很多通道都是公用的很浪费资源，实际上综合的时候都会综合掉
    //imm_I_0 其中的数字0代表预处理步骤，完成所有处理可以输出的指令以及立即数该数字最高
    wire[6:0] opcode_0 = inst_i[6:0];
    wire[2:0] funct3_0 = inst_i[14:12];
    wire[6:0] funct7_0 = inst_i[31:25];
    wire[4:0] rd_0 = inst_i[11:7];
    wire[4:0] rs1_0 = inst_i[19:15];
    wire[4:0] rs2_0 = inst_i[24:20];
    wire[11:0] imm_I_0 = inst_i[31:20];
    wire[11:0] imm_S_0 = {inst_i[31:25],inst_i[11:7]};
    wire[12:1] imm_B_0 = {inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8]};
    wire[31:12] imm_U_0 = inst_i[31:12];
    wire[20:1] imm_J_0 = {inst_i[31],inst_i[19:12],inst_i[30:21],inst_i[20]};
    //立即数补位
    wire[`RegBus] imm_I_1 = {{(`RegWidth-12){inst_i[31]}},inst_i[31:20]};
    wire[`RegBus] imm_S_1 = {{(`RegWidth-12){inst_i[31]}},inst_i[31:25],inst_i[11:7]};
    wire[`RegBus] imm_B_1 = {{(`RegWidth-13){inst_i[31]}},inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
    wire[`RegBus] imm_U_1 = {inst_i[31:12],{(`RegWidth-20){1'b0}}};
    wire[`RegBus] imm_J_1 = {{(`RegWidth-21){inst_i[31]}},inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};

    always@(posedge clk)begin
        if(rst == `RstEnable || hold_flag_i == `HoldEnable || jump_flag_i == `JumpEnable) begin
            inst_addr_o <= `ZeroWord;
        end
        else begin
            inst_addr_o <= inst_addr_i;
        end
    end
    
    assign sram_raddr_o = reg1_rdata_i+imm_I_o;
    
    //控制sram读取类型
    always@(posedge clk)begin
        if(rst == `RstEnable || hold_flag_i == `HoldEnable || jump_flag_i == `JumpEnable) begin
            ex_rtype_o <= `ZeroWord;
        end
        else begin
        case({opcode_0,funct3_0})
            {`INST_TYPE_I_L,`INST_LB_3}: ex_rtype_o <= `SramByte;
            {`INST_TYPE_I_L,`INST_LH_3}: ex_rtype_o <= `SramHalf;
            {`INST_TYPE_I_L,`INST_LW_3}: ex_rtype_o <= `SramWord;
            default: ex_rtype_o <= `SramWord;
        endcase
        end
    end
    

    always @ (posedge clk) begin
        if (rst == `RstEnable || jump_flag_i == `JumpEnable || hold_flag_i == `HoldEnable) begin
            //to ex
            inst_valid_o <= `InstInvalid;
            opcode_o <= `ZeroWord;
            funct3_o <= `ZeroWord;
            funct7_o <= `ZeroWord;
            imm_I_o <= `ZeroWord;
            imm_S_o <= `ZeroWord;
            imm_B_o <= `ZeroWord;
            imm_U_o <= `ZeroWord;
            imm_J_o <= `ZeroWord;
            //to reg
            reg_we_o <= `WriteDisable;
            reg1_re_o <= `ReadDisable;
            reg2_re_o <= `ReadDisable;
            //to sram
            sram_re_o <= `ReadDisable;
            sram_we_o <= `WriteDisable;
        end 
        else begin
        case (opcode_0)
            `INST_TYPE_R: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteEnable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadEnable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadEnable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_I: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteEnable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadEnable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadDisable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_I_L: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteEnable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadEnable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadDisable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadEnable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_I_J: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteEnable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadEnable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadDisable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_I_E: begin       ///////////////////////////////////////////////////////////////////////////待实现
                //nop指令 用add x0 x0 0代替
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= `INST_TYPE_R;
                funct3_o <= `ZeroWord;
                funct7_o <= `ZeroWord;
                imm_I_o <= `ZeroWord;
                imm_S_o <= `ZeroWord;
                imm_B_o <= `ZeroWord;
                imm_U_o <= `ZeroWord;
                imm_J_o <= `ZeroWord;
                //to reg
                reg_we_o <= `WriteDisable;
                reg1_re_o <= `ReadDisable;
                reg2_re_o <= `ReadDisable;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_S: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteDisable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadEnable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadEnable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteEnable;
            end
            `INST_TYPE_B: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteDisable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadEnable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadEnable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_U_LUI: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteEnable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadDisable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadDisable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_U_AUIPC: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteEnable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadDisable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadDisable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            `INST_TYPE_J_JAL: begin
                //to ex
                inst_valid_o <= `InstValid;
                opcode_o <= opcode_0;
                funct3_o <= funct3_0;
                funct7_o <= funct7_0;
                imm_I_o <= imm_I_1;
                imm_S_o <= imm_S_1;
                imm_B_o <= imm_B_1;
                imm_U_o <= imm_U_1;
                imm_J_o <= imm_J_1;
                //to reg
                reg_we_o <= `WriteEnable;
                reg_waddr_o <= rd_0;
                reg1_re_o <= `ReadDisable;
                reg1_raddr_o <= rs1_0;
                reg2_re_o <= `ReadDisable;
                reg2_raddr_o <= rs2_0;
                //to sram
                sram_re_o <= `ReadDisable;
                sram_we_o <= `WriteDisable;
            end
            default: begin
                inst_valid_o <= `InstInvalid;
            end
        endcase
        end
        
    end

    
endmodule
