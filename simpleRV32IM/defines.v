//此处使用vivado右键defines.v => set global include
//之后就不需要再在文件内添加`include "defines.v"（而且能避免“使用未定义的宏的bug”）
`define RstEnable 1'b0
`define RstDisable 1'b1
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define JumpEnable 1'b1
`define JumpDisable 1'b0
`define HoldEnable 1'b1
`define HoldDisable 1'b0
`define InstValid 1'b1
`define InstInvalid 1'b0
`define True 1'b1
`define False 1'b0

`define DivisorZeroResult 32'hffffffff
`define ZeroWord 32'h00000000
`define ZeroWord8 8'h00
`define ZeroWord16 16'h0000
`define ZeroWord32 32'h00000000
`define ZeroWord64 64'h0000000000000000
`define ZeroWord128 128'h00000000000000000000000000000000

// SIM RAM
`define SramMemNum 2048   // memory depth(how many words)
`define SramBus 31:0
`define SramAddrBus 31:0
`define SramType 1:0 //00:32 01:8 10:16 11:64
`define SramByte 2'b01
`define SramHalf 2'b10
`define SramWord 2'b00
`define SramDouble 2'b11

// common regs
`define RegAddrBus 4:0
`define RegBus 31:0
`define DoubleRegBus 63:0
`define RegWidth 32
`define RegNum 32        // reg count
`define RegNumLog2 5

////////////////////////////RV32I Base Integer Instructions////////////////////////////////

// R type inst
`define INST_TYPE_R     7'b0110011
`define INST_ADD_3      3'h0
`define INST_SUB_3      3'h0
`define INST_XOR_3      3'h4
`define INST_OR_3       3'h6
`define INST_AND_3      3'h7
`define INST_SLL_3      3'h1
`define INST_SRL_3      3'h5
`define INST_SRA_3      3'h5
`define INST_SLT_3      3'h2
`define INST_SLTU_3     3'h3
`define INST_ADD_7      7'h00
`define INST_SUB_7      7'h20
`define INST_XOR_7      7'h00
`define INST_OR_7       7'h00
`define INST_AND_7      7'h00
`define INST_SLL_7      7'h00
`define INST_SRL_7      7'h00
`define INST_SRA_7      7'h20
`define INST_SLT_7      7'h00
`define INST_SLTU_7     7'h00

// I type inst
`define INST_TYPE_I     7'b0010011
`define INST_ADDI_3     3'h0
`define INST_XORI_3     3'h4
`define INST_ORI_3      3'h6
`define INST_ANDI_3     3'h7
`define INST_SLLI_3     3'h1
`define INST_SRLI_3     3'h5
`define INST_SRAI_3     3'h5
`define INST_SLTI_3     3'h2
`define INST_SLTIU_3    3'h3
`define INST_SLLI_7     7'h00
`define INST_SRLI_7     7'h00
`define INST_SRAI_7     7'h20

`define INST_TYPE_I_L   7'b0000011
`define INST_LB_3       3'h0
`define INST_LH_3       3'h1
`define INST_LW_3       3'h2
`define INST_LBU_3      3'h4
`define INST_LHU_3      3'h5

`define INST_TYPE_I_J   7'b1100111
`define INST_JALR_3     3'h0

`define INST_TYPE_I_E   7'b1110011
`define INST_ECALL_3    3'h0
`define INST_EBREAK_3   3'h0
`define INST_ECALL_7    7'h0
`define INST_EBREAK_7   7'h1

// S type inst
`define INST_TYPE_S     7'b0100011
`define INST_SB_3       3'h0
`define INST_SH_3       3'h1
`define INST_SW_3       3'h2

// B type inst
`define INST_TYPE_B     7'b1100011
`define INST_BEQ_3      3'h0
`define INST_BNE_3      3'h1
`define INST_BLT_3      3'h4
`define INST_BGE_3      3'h5
`define INST_BLTU_3     3'h6
`define INST_BGEU_3     3'h7

// U type inst
`define INST_TYPE_U_LUI        7'b0110111
`define INST_TYPE_U_AUIPC      7'b0010111

// J type inst
`define INST_TYPE_J_JAL        7'b1101111

// special
`define INST_TYPE_I_FENCE       7'b0001111 //未加入id与ex，默认什么都不做
`define INST_NOP_0      7'b0000000 //未加入id与ex，默认什么都不做
`define INST_NOP_1       7'b1111111 //未加入id与ex，默认什么都不做


////////////////////////////RV32M Multiply Extention////////////////////////////////

// R type instinst
`define INST_TYPE_R     7'b0110011
`define INST_MUL_3      3'h0
`define INST_MULH_3     3'h1
`define INST_MULSU_3    3'h2
`define INST_MULU_3     3'h3
`define INST_DIV_3      3'h4
`define INST_DIVU_3     3'h5
`define INST_REM_3      3'h6
`define INST_REMU_3     3'h7
`define INST_MUL_7      7'h01
`define INST_MULH_7     7'h01
`define INST_MULSU_7    7'h01
`define INST_MULU_7     7'h01
`define INST_DIV_7      7'h01
`define INST_DIVU_7     7'h01
`define INST_REM_7      7'h01
`define INST_REMU_7     7'h01