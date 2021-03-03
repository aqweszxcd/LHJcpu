//此处使用vivado右键defines.v => set global include
//之后就不需要再在文件内添加`include "defines.v"（而且能避免"使用未定义的宏的bug"）

`timescale 1ns/100ps

`define Enable 1'b1
`define Disable 1'b0

`define DivisorZeroResult 32'hffffffff
`define ZeroWord 32'h00000000
`define ZeroWord8 8'h00
`define ZeroWord16 16'h0000
`define ZeroWord32 32'h00000000
`define ZeroWord64 64'h0000000000000000
`define ZeroWord128 128'h00000000000000000000000000000000
`define ZeroWord256 256'h0000000000000000000000000000000000000000000000000000000000000000
`define OneWord256 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
`define OneWord64 64'hffffffffffffffff
`define OneWord45 45'b111111111111111111111111111111111111111111111
`define OneWord32 32'b11111111111111111111111111111111
`define AddrMax 32'b01111111111111111111111111111111
`define MESI_M 2'b11
`define MESI_E 2'b10
`define MESI_S 2'b01
`define MESI_I 2'b00

//cache
`define SET_NUM_L1I 4//组相联组数量
`define LINE_NUM_L1I 16//cache line数量
`define LINE_SIZE_L1I 256//每条cache line长度 256=32bytes 512=64bytes
`define ADDR_LENTH_L1I 32//寻址长度
`define SET_NUM_L1I_BIT 2//组相联组数量
`define LINE_NUM_L1I_BIT 4//cache line数量
`define LINE_SIZE_L1I_BIT 5//每条cache line长度 256=32bytes 512=64bytes

`define SET_NUM_L1D 4//组相联组数量
`define LINE_NUM_L1D 16//cache line数量
`define LINE_SIZE_L1D 256//每条cache line长度 256=32bytes 512=64bytes
`define ADDR_LENTH_L1D 32//寻址长度
`define SET_NUM_L1D_BIT 2//组相联组数量
`define LINE_NUM_L1D_BIT 4//cache line数量
`define LINE_SIZE_L1D_BIT 5//每条cache line长度 256=32bytes 512=64bytes

`define SET_NUM_L2 4//组相联组数量
`define LINE_NUM_L2 64//cache line数量
`define LINE_SIZE_L2 256//每条cache line长度 256=32bytes 512=64bytes
`define ADDR_LENTH_L2 32//寻址长度
`define SET_NUM_L2_BIT 2//组相联组数量
`define LINE_NUM_L2_BIT 6//cache line数量
`define LINE_SIZE_L2_BIT 5//每条cache line长度 256=32bytes 512=64bytes

`define SET_NUM_L3 4//组相联组数量
`define LINE_NUM_L3 256//cache line数量
`define LINE_SIZE_L3 256//每条cache line长度 256=32bytes 512=64bytes
`define ADDR_LENTH_L3 32//寻址长度
`define SET_NUM_L3_BIT 2//组相联组数量
`define LINE_NUM_L3_BIT 8//cache line数量
`define LINE_SIZE_L3_BIT 5//每条cache line长度 256=32bytes 512=64bytes

`define LINE_SIZE 256//每条cache line长度 256=32bytes 512=64bytes
`define RAM_TIMES 8//取出整个line所需要的周期数（256/32=8）
`define ADDR_LENTH 32//寻址长度
`define RAM_NUM 4096//内存条数（32bit）


// SIM RAM
`define SramMemNum 2048   // memory depth(how many words)
`define L1IMemNum 64
`define L1DMemNum 64
`define L2MemNum 2048
`define HalfSramBus 15:0
`define SramBus 31:0
`define SramBusx4 127:0
`define DoubleSramBus 63:0
`define SramAddrBus 31:0
`define SramAddrBusx4 127:0
`define DecodedInstBus 72:0
`define DecodedInstBusPlus 73:0
`define ROBNumber 31:0
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
`define INST_TYPE_I_FENCE       7'b0001111
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


////////////////////////////RV32C Multiply Extention////////////////////////////////
//inst[1:0],inst[15:8]
`define  INST_C_LWSP_OP 2'b10
`define  INST_C_LWSP_3 3'b010

`define  INST_C_SWSP_OP 2'b10
`define  INST_C_SWSP_3 3'b110

`define  INST_C_LW_OP 2'b00
`define  INST_C_LW_3 3'b010

`define  INST_C_SW_OP 2'b00
`define  INST_C_SW_3 3'b110

`define  INST_C_J_OP 2'b01
`define  INST_C_J_3 3'b101

`define  INST_C_JAL_OP 2'b01
`define  INST_C_JAL_3 3'b001

`define  INST_C_JR_OP 2'b10
`define  INST_C_JR_3 3'b100
`define  INST_C_JR_4E 1'b0

`define  INST_C_JALR_OP 2'b10
`define  INST_C_JALR_3 3'b100
`define  INST_C_JALR_4E 1'b1

`define  INST_C_BEQZ_OP 2'b01
`define  INST_C_BEQZ_3 3'b110

`define  INST_C_BNEZ_OP 2'b01
`define  INST_C_BNEZ_3 3'b111

`define  INST_C_LI_OP 2'b01
`define  INST_C_LI_3 3'b010

`define  INST_C_LUI_OP 2'b01
`define  INST_C_LUI_3 3'b011

`define  INST_C_ADDI_OP 2'b01
`define  INST_C_ADDI_3 3'b000

`define  INST_C_ADDI16SP_OP 2'b01
`define  INST_C_ADDI16SP_3 3'b011

`define  INST_C_ADDI4SPN_OP 2'b00
`define  INST_C_ADDI4SPN_3 3'b000

`define  INST_C_SLLI_OP 2'b10
`define  INST_C_SLLI_3 3'b000

`define  INST_C_SRLI_OP 2'b01
`define  INST_C_SRLI_3 3'b100
`define  INST_C_SRLI_6E 2'b00

`define  INST_C_SRAI_OP 2'b01
`define  INST_C_SRAI_3 3'b100
`define  INST_C_SRAI_6E 2'b01

`define  INST_C_ANDI_OP 2'b01
`define  INST_C_ANDI_3 3'b100
`define  INST_C_ANDI_6E 2'b10

`define  INST_C_MV_OP 2'b10
`define  INST_C_MV_3 3'b100
`define  INST_C_MV_4E 1'b0

`define  INST_C_ADD_OP 2'b10
`define  INST_C_ADD_3 3'b100
`define  INST_C_ADD_4E 1'b1

`define  INST_C_AND_OP 2'b01
`define  INST_C_AND_3 3'b100
`define  INST_C_AND_4E 1'b0
`define  INST_C_AND_6E 2'b11
`define  INST_C_AND_8E2 2'b11

`define  INST_C_OR_OP 2'b01
`define  INST_C_OR_3 3'b100
`define  INST_C_OR_4E 1'b0
`define  INST_C_OR_6E 2'b11
`define  INST_C_OR_8E2 2'b10

`define  INST_C_XOR_OP 2'b01
`define  INST_C_XOR_3 3'b100
`define  INST_C_XOR_4E 1'b0
`define  INST_C_XOR_6E 2'b11
`define  INST_C_XOR_8E2 2'b01

`define  INST_C_SUB_OP 2'b01
`define  INST_C_SUB_3 3'b100
`define  INST_C_SUB_4E 1'b0
`define  INST_C_SUB_6E 2'b11
`define  INST_C_SUB_8E2 2'b00

`define  INST_C_NOP_OP 2'b01
`define  INST_C_NOP_3 3'b000

`define  INST_C_EBREAK_OP 2'b10
`define  INST_C_EBREAK_3 3'b100
`define  INST_C_EBREAK_4E 1'b1


`define  REG_SP 5'b00010
`define  REG_X0 5'b00000
`define  REG_RA 5'b00001
