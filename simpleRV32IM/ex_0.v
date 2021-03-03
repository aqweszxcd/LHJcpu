`include "defines.v"
// excute and writeback module 执行与写回单元
module ex_0 (
    
    //不光立即数需要补位，执行部分中的结果也需要按照reference card的注释进行补位
    //部位分为msb extends（MSB是Most Significant Bit的缩写,指最高有效位）和zero extends，前者补最高有效位，后者补0
    
    input wire clk,
    input wire rst,

    // from id 指令单元
    
    input wire inst_valid_i,                 // inst is valid flag
    input wire [`SramAddrBus] inst_addr_i,
    input wire [6:0] opcode_i,
    input wire [2:0] funct3_i,
    input wire [6:0] funct7_i,
    input wire [`RegBus] imm_I_i,
    input wire [`RegBus] imm_S_i,
    input wire [`RegBus] imm_B_i,
    input wire [`RegBus] imm_U_i,
    input wire [`RegBus] imm_J_i,
    input wire reg_we_i,                     // reg write enable
    input wire [`RegAddrBus] reg_waddr_i,     // reg write addr

    // regs cpu核心运行寄存器
    input wire[`RegBus] reg1_rdata_i,       // reg1 read data
    input wire[`RegBus] reg2_rdata_i,       // reg2 read data
    output reg[`RegBus] reg_wdata_o,        // reg write data
    output reg reg_we_o,                     // reg write enable
    output reg[`RegAddrBus] reg_waddr_o,     // reg write addr
    
    // sram 内存（模拟的，很浪费资源,fpga可以用片上ram代替）
    input wire[`SramBus] sram_rdata_i,      // ram read data
    output reg[`SramBus] sram_wdata_o,      // ram write data
    output reg[`SramAddrBus] sram_waddr_o,  // ram write addr
    output reg sram_we_o,
    output reg[`SramType] wtype_o,        // write data               //////////////////////////////////////////////////////待添加

    // pc_reg pc寄存器（对于系统可见）
	input wire pc_re_i,
	input wire[`SramAddrBus] pc_i,
    output reg hold_flag_o,//hold
    output reg[`RegBus] hold_addr_o,//hold addr
    output reg jump_flag_o,//jump
    output reg[`RegBus] jump_addr_o,//jump addr
    
    // 乱序重排 待定 未使用 
    //output reg inst_valid_o,                 // inst is valid flag
    //output reg [`SramAddrBus] inst_addr_o
    //下级流水线 待定
    output reg [`SramAddrBus] inst_addr_o
);


wire [`DoubleRegBus] mul_result = $signed(reg1_rdata_i) * $signed(reg2_rdata_i);
wire [`RegBus] op1_mul = (reg1_rdata_i[31] == 1'b1)? (~reg1_rdata_i + 1): reg1_rdata_i;
wire [`DoubleRegBus] mulsu_result = (reg1_rdata_i[31] == 1'b1) ? ((~(op1_mul * reg2_rdata_i))+1) : (op1_mul * reg2_rdata_i);
wire [`DoubleRegBus] mulu_result = $unsigned(reg1_rdata_i) * $unsigned(reg2_rdata_i);

wire [`RegBus] div_result = $signed(reg1_rdata_i) / $signed(reg2_rdata_i);
wire [`RegBus] divu_result = $unsigned(reg1_rdata_i) / $unsigned(reg2_rdata_i);
wire [`RegBus] rem_result = $signed(reg1_rdata_i) % $signed(reg2_rdata_i);
wire [`RegBus] remu_result = $unsigned(reg1_rdata_i) % $unsigned(reg2_rdata_i);

    always@(posedge clk)begin
        if(rst == `RstEnable || hold_flag_o == `HoldEnable || jump_flag_o == `JumpEnable) begin
            inst_addr_o <= `ZeroWord;
            reg_we_o<=`WriteDisable;                     // reg write enable
            reg_waddr_o<=`ZeroWord;     // reg write addr 
        end
        else begin
            inst_addr_o<=inst_addr_i;
            reg_we_o<=reg_we_i;                     // reg write enable
            reg_waddr_o<=reg_waddr_i;     // reg write addr
        end
    end
        
always @ (posedge clk) begin
    if (rst == `RstEnable || hold_flag_o==`HoldEnable || jump_flag_o==`JumpEnable) begin
        // to reg
        reg_wdata_o <= `ZeroWord;
        // to ram
        sram_we_o <= `WriteDisable; 
        sram_wdata_o <= `ZeroWord;
        sram_waddr_o <= `ZeroWord;
        wtype_o <= `ZeroWord;
        // to pc_reg
        hold_flag_o <= `HoldDisable;
        hold_addr_o <= `ZeroWord;
        jump_flag_o <= `JumpDisable;
        jump_addr_o <= `ZeroWord;
    end
    else if (inst_valid_i == `InstValid) begin
        case({opcode_i,funct3_i,funct7_i})
            {`INST_TYPE_R,`INST_ADD_3,`INST_ADD_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i + reg2_rdata_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_SUB_3,`INST_SUB_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i - reg2_rdata_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_XOR_3,`INST_XOR_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i ^ reg2_rdata_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_OR_3,`INST_OR_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i | reg2_rdata_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_AND_3,`INST_AND_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i & reg2_rdata_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_SLL_3,`INST_SLL_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i << reg2_rdata_i[4:0];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_SRL_3,`INST_SRL_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i >> reg2_rdata_i[4:0];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_SRA_3,`INST_SRA_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{32{reg1_rdata_i[31]}},reg1_rdata_i} >> $signed(reg2_rdata_i[4:0]);
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_SLT_3,`INST_SLT_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{31{1'b0}},{($signed(reg1_rdata_i) < $signed(reg2_rdata_i)) ? 1:0}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_SLTU_3,`INST_SLTU_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{31{1'b0}},{($unsigned(reg1_rdata_i) < $unsigned(reg2_rdata_i)) ? 1:0}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_MUL_3,`INST_MUL_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= mul_result[31:0];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_MULH_3,`INST_MULH_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= mul_result[63:32];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_MULSU_3,`INST_MULSU_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                    reg_wdata_o <= mulsu_result[63:32];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_MULU_3,`INST_MULU_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= mulu_result[63:32];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_DIV_3,`INST_DIV_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= div_result;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_DIVU_3,`INST_DIVU_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= divu_result;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_REM_3,`INST_REM_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= rem_result;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_R,`INST_REMU_3,`INST_REMU_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= remu_result;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_ADDI_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i + imm_I_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_XORI_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i ^ imm_I_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_ORI_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i | imm_I_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_ANDI_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i & imm_I_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_SLLI_3,`INST_SLLI_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i << imm_I_i[4:0];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_SRLI_3,`INST_SRLI_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= reg1_rdata_i >> imm_I_i[4:0];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_SRAI_3,`INST_SRAI_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{32{reg1_rdata_i[31]}},reg1_rdata_i} >> $signed(imm_I_i[4:0]);
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_SLTI_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{31{1'b0}},{($signed(reg1_rdata_i) < $signed(imm_I_i)) ? 1:0}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I,`INST_SLTIU_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{31{1'b0}},{($unsigned(reg1_rdata_i) < $unsigned(imm_I_i)) ? 1:0}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I_L,`INST_LB_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{24{sram_rdata_i[7]}},{sram_rdata_i[7:0]}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I_L,`INST_LH_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{16{sram_rdata_i[15]}},{sram_rdata_i[15:0]}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I_L,`INST_LW_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= sram_rdata_i[31:0];
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I_L,`INST_LBU_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{24{1'b0}},{sram_rdata_i[7:0]}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I_L,`INST_LHU_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= {{16{1'b0}},{sram_rdata_i[15:0]}};
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I_J,`INST_JALR_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= inst_addr_i+4;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpEnable;
                jump_addr_o <= reg1_rdata_i+imm_I_i;
            end
            {`INST_TYPE_I_E,`INST_ECALL_3,`INST_ECALL_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                ///////////////////////////////////暂时为空
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_I_E,`INST_EBREAK_3,`INST_EBREAK_7}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                ///////////////////////////////////暂时为空
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_S,`INST_SB_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteEnable; 
                sram_wdata_o <= {{24{reg2_rdata_i[7]}},{reg2_rdata_i[7:0]}};
                sram_waddr_o <= reg1_rdata_i+imm_S_i;
                wtype_o <= `SramByte;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_S,`INST_SH_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteEnable; 
                sram_wdata_o <= {{16{reg2_rdata_i[7]}},{reg2_rdata_i[15:0]}};
                sram_waddr_o <= reg1_rdata_i+imm_S_i;
                wtype_o <= `SramHalf;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_S,`INST_SW_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteEnable; 
                sram_wdata_o <= reg2_rdata_i[31:0];
                sram_waddr_o <= reg1_rdata_i+imm_S_i;
                wtype_o <= `SramWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_B,`INST_BEQ_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= ($signed(reg1_rdata_i)==$signed(reg2_rdata_i))?`JumpEnable:`JumpDisable;
                jump_addr_o <= inst_addr_i+imm_B_i;
            end
            {`INST_TYPE_B,`INST_BNE_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= ($signed(reg1_rdata_i)!=$signed(reg2_rdata_i))?`JumpEnable:`JumpDisable;
                jump_addr_o <= inst_addr_i+imm_B_i;
            end
            {`INST_TYPE_B,`INST_BLT_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= ($signed(reg1_rdata_i)<$signed(reg2_rdata_i))?`JumpEnable:`JumpDisable;
                jump_addr_o <= inst_addr_i+imm_B_i;
            end
            {`INST_TYPE_B,`INST_BGE_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= ($signed(reg1_rdata_i)>=$signed(reg2_rdata_i))?`JumpEnable:`JumpDisable;
                jump_addr_o <= inst_addr_i+imm_B_i;
            end
            {`INST_TYPE_B,`INST_BLTU_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= ($unsigned(reg1_rdata_i)<$unsigned(reg2_rdata_i))?`JumpEnable:`JumpDisable;
                jump_addr_o <= inst_addr_i+imm_B_i;
            end
            {`INST_TYPE_B,`INST_BGEU_3,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= `ZeroWord;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= ($unsigned(reg1_rdata_i)>=$unsigned(reg2_rdata_i))?`JumpEnable:`JumpDisable;
                jump_addr_o <= inst_addr_i+imm_B_i;
            end
            {`INST_TYPE_U_LUI,funct3_i,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= imm_U_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_U_AUIPC,funct3_i,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= inst_addr_i+imm_U_i;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpDisable;
                jump_addr_o <= `ZeroWord;
            end
            {`INST_TYPE_J_JAL,funct3_i,funct7_i}:begin
                // 可使用的输入
                // inst_addr_i,opcode_i,funct3_i,funct7_i,
                // imm_I_i,imm_S_i,imm_B_i,imm_U_i,imm_J_i,
                // reg1_rdata_i,reg2_rdata_i,
                // sram_rdata_i,
                
                // to reg
                reg_wdata_o <= inst_addr_i+4;
                // to ram
                sram_we_o <= `WriteDisable; 
                sram_wdata_o <= `ZeroWord;
                sram_waddr_o <= `ZeroWord;
                wtype_o <= `ZeroWord;
                // to pc_reg
                hold_flag_o <= `HoldDisable;
                hold_addr_o <= `ZeroWord;
                jump_flag_o <= `JumpEnable;
                jump_addr_o <= inst_addr_i+imm_J_i;
            end
        endcase
    end
    else begin
    
    end
end


endmodule
