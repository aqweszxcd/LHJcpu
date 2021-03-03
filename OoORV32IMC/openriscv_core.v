`include "defines.v"
module openriscv_core (
input wire clk,
input wire rst,
output wire [`SramAddrBus] pc_outside_i
);

//乱花街
// RV32IMC 单周期M 乱序

// inoutput
// 输入单元，暂时只输入时钟与复位信号
// 输出单元，暂时只输出pc寄存器
//支持fence.i


////////////////L1I
wire re_L1I_o;
wire [`DoubleSramBus] rdata_L1I_o;
wire [`SramAddrBus] raddr_L1I_o;

////////////////L1D
wire re_L1D_o;                  // read enable
wire [`SramBus] rdata_L1D_o;      // read data
/*
////////////////L1
wire inst_re_o;
wire [`DoubleSramBus] inst_rdata_o;     // pc read data
wire [`SramAddrBus] inst_raddr_o;     // pc read addr
//ex_a write
//ex_a read
wire data_re_o;                  // read enable
wire [`SramBus] data_rdata_o;      // read data*/


////////////////pc_if
wire re_pc_if_o;
wire [`SramAddrBus] pc_pc_if_o;

wire [`SramBusx4] fb_pc_if_o;//Fetch Buffer x4
wire [`SramAddrBusx4] fb_addr_pc_if_o;//Fetch Buffer x4
wire [3:0] fb_en_pc_if_o;//Fetch Buffer Enable x4

////////////////id
wire full_flag_id_o;
// to ex int0 (执行)
wire iq_int_0_en_id_o;
wire [71:0]iq_int_0_inst_id_o;
wire [31:0]iq_int_0_addr_id_o;
// to ex int1 (执行)
wire iq_int_1_en_id_o;
wire [71:0]iq_int_1_inst_id_o;
wire [31:0]iq_int_1_addr_id_o;
// to ex mem (执行)
wire iq_mem_0_en_id_o;
wire [71:0]iq_mem_0_inst_id_o;
wire [31:0]iq_mem_0_addr_id_o;
// to ex jump (执行)
wire iq_jump_0_en_id_o;
wire [71:0]iq_jump_0_inst_id_o;
wire [31:0]iq_jump_0_addr_id_o;

////////////////regs
wire[1023:0] reg_rdata_regs_o;       // reg read data

////////////////ex_j_0
// to regs
wire [`RegBus] reg_wdata_ex_j_0_o;        // reg write data
wire reg_we_ex_j_0_o;                     // reg write enable
wire [`RegAddrBus] reg_waddr_ex_j_0_o;     // reg write addr
// to pc_if pc寄存器（对于系统可见）
wire hold_flag_ex_j_0_o;//hold
wire [`RegBus] hold_addr_ex_j_0_o;//hold addr
wire jump_flag_ex_j_0_o;//jump
wire jump_continue_ex_j_0_o;//jump finish
wire [`RegBus] jump_addr_ex_j_0_o;//jump addr

////////////////ex_i_0
wire reg_we_ex_i_0_o;                     // reg write enable
wire [`RegAddrBus] reg_waddr_ex_i_0_o;     // reg write addr
wire [`RegBus] reg_wdata_ex_i_0_o;        // reg write data

////////////////ex_i_1
wire reg_we_ex_i_1_o;                     // reg write enable
wire [`RegAddrBus] reg_waddr_ex_i_1_o;     // reg write addr
wire [`RegBus] reg_wdata_ex_i_1_o;        // reg write data

////////////////mem_0
// ex_a 流水线下级
wire mem_mem_en_mem_0_o;
wire [31:0] mem_mem_addr_mem_0_o;
wire [71:0] mem_mem_inst_mem_0_o;
// L1D
wire re_mem_0_o;                  // read enable
wire [`SramBus] raddr_mem_0_o;      // read addr

////////////////ex_a_0
// regs cpu核心运行寄存器
wire reg_we_ex_a_0_o;                     // reg write enable
wire [`RegAddrBus] reg_waddr_ex_a_0_o;     // reg write addr
wire [`RegBus] reg_wdata_ex_a_0_o;        // reg write data
// L1D
wire we_ex_a_0_o;                     // write enable
wire [`SramAddrBus] waddr_ex_a_0_o;    // write addr
wire [`SramBus] wdata_ex_a_0_o;        // write data




/*L1I L1I_0 (
.clk(clk),
.rst(rst),
//ex
.jump_flag_i(jump_flag_ex_j_0_o),
.jump_addr_i(jump_addr_ex_j_0_o),
.hold_flag_i(hold_flag_ex_j_0_o),
.hold_addr_i(hold_addr_ex_j_0_o),
//pc_if
.re_i(re_pc_if_o),                  // pc read enable
.raddr_i(pc_pc_if_o),           // pc read addr
.re_o(re_L1I_o),
.rdata_o(rdata_L1I_o),          // pc read data
.raddr_o(raddr_L1I_o)       // pc read addr
);


L1D L1D_0 (
.clk(clk),
.rst(rst),
//ex_a write
.we_i(we_ex_a_0_o),                     // write enable
.waddr_i(waddr_ex_a_0_o),    // write addr
.wdata_i(wdata_ex_a_0_o),        // write data
//ex_a read
.re_i(re_mem_0_o),                  // read enable
.raddr_i(raddr_mem_0_o), // read addr
.re_o(re_L1D_o),                  // read enable
.rdata_o(rdata_L1D_o)      // read data
);*/

L1 L1_0 (
.clk(clk),
.rst(rst),
//ex
.jump_flag_i(jump_flag_ex_j_0_o),
.jump_addr_i(jump_addr_ex_j_0_o),
.hold_flag_i(hold_flag_ex_j_0_o),
.hold_addr_i(hold_addr_ex_j_0_o),
//pc_if
.inst_re_i(re_pc_if_o),                  // pc read enable
.inst_raddr_i(pc_pc_if_o),           // pc read addr
.inst_re_o(re_L1I_o),
.inst_rdata_o(rdata_L1I_o),          // pc read data
.inst_raddr_o(raddr_L1I_o),       // pc read addr
//ex_a write
.data_we_i(we_ex_a_0_o),                     // write enable
.data_waddr_i(waddr_ex_a_0_o),    // write addr
.data_wdata_i(wdata_ex_a_0_o),        // write data
//ex_a read
.data_re_i(re_mem_0_o),                  // read enable
.data_raddr_i(raddr_mem_0_o), // read addr
.data_re_o(re_L1D_o),                  // read enable
.data_rdata_o(rdata_L1D_o)      // read data
);


pc_if pc_if_0 (
.clk(clk),
.rst(rst),
//ex
.jump_flag_i(jump_flag_ex_j_0_o),
.jump_addr_i(jump_addr_ex_j_0_o),
.hold_flag_i(hold_flag_ex_j_0_o),
.hold_addr_i(hold_addr_ex_j_0_o),
//L1I
.re_o(re_pc_if_o),
.pc_o(pc_pc_if_o),
.re_i(re_L1I_o),
.inst_i(rdata_L1I_o),
.inst_addr_i(raddr_L1I_o),
//id
.fb_o(fb_pc_if_o),//Fetch Buffer x4
.fb_addr_o(fb_addr_pc_if_o),//Fetch Buffer x4
.fb_en_o(fb_en_pc_if_o),//Fetch Buffer Enable x4
.full_flag_i(full_flag_id_o)
);


// id
id id_0 (                                       
.clk(clk),
.rst(rst),
//ex
.jump_flag_i(jump_flag_ex_j_0_o),
.jump_continue_i(jump_continue_ex_j_0_o),//jump finish
.jump_addr_i(jump_addr_ex_j_0_o),
.hold_flag_i(hold_flag_ex_j_0_o),
.hold_addr_i(hold_addr_ex_j_0_o),
//pc_if
.fb_addr_i(fb_addr_pc_if_o),//Fetch Buffer
.fb_i(fb_pc_if_o),//Fetch Buffer
.fb_en_i(fb_en_pc_if_o),//Fetch Buffer Enable
.full_flag_o(full_flag_id_o),

// to ex int0 (执行)
.iq_int_0_en_o(iq_int_0_en_id_o),
.iq_int_0_inst_o(iq_int_0_inst_id_o),
.iq_int_0_addr_o(iq_int_0_addr_id_o),
// to ex int1 (执行)
.iq_int_1_en_o(iq_int_1_en_id_o),
.iq_int_1_inst_o(iq_int_1_inst_id_o),
.iq_int_1_addr_o(iq_int_1_addr_id_o),
// to ex mem (执行)
.iq_mem_0_en_o(iq_mem_0_en_id_o),
.iq_mem_0_inst_o(iq_mem_0_inst_id_o),
.iq_mem_0_addr_o(iq_mem_0_addr_id_o),
// to ex jump (执行)
.iq_jump_0_en_o(iq_jump_0_en_id_o),
.iq_jump_0_inst_o(iq_jump_0_inst_id_o),
.iq_jump_0_addr_o(iq_jump_0_addr_id_o)
);


//regs
regs regs_0 (
.clk(clk),
.rst(rst),
//write
.we_jump_0_i(reg_we_ex_j_0_o),                  // reg write enable
.waddr_jump_0_i(reg_waddr_ex_j_0_o),  // reg write addr
.wdata_jump_0_i(reg_wdata_ex_j_0_o),      // reg write data

.we_mem_0_i(reg_we_ex_a_0_o),                  // reg write enable
.waddr_mem_0_i(reg_waddr_ex_a_0_o),  // reg write addr
.wdata_mem_0_i(reg_wdata_ex_a_0_o),      // reg write data

.we_int_0_i(reg_we_ex_i_0_o),                  // reg write enable
.waddr_int_0_i(reg_waddr_ex_i_0_o),  // reg write addr
.wdata_int_0_i(reg_wdata_ex_i_0_o),      // reg write data

.we_int_1_i(reg_we_ex_i_1_o),                  // reg write enable
.waddr_int_1_i(reg_waddr_ex_i_1_o),  // reg write addr
.wdata_int_1_i(reg_wdata_ex_i_1_o),      // reg write data
//read
.reg_rdata_o(reg_rdata_regs_o)       // reg read data
);


//ex
ex_j ex_j_0 (
    .clk(clk),
    .rst(rst),
    // id
    .iq_jump_0_en_i(iq_jump_0_en_id_o),
    .iq_jump_0_addr_i(iq_jump_0_addr_id_o),
    .iq_jump_0_inst_i(iq_jump_0_inst_id_o),
    .jump_continue_o(jump_continue_ex_j_0_o),//jump finish
    // regs cpu核心运行寄存器
    .reg_rdata_i(reg_rdata_regs_o),       // reg read data
    .reg_wdata_o(reg_wdata_ex_j_0_o),        // reg write data
    .reg_we_o(reg_we_ex_j_0_o),                     // reg write enable
    .reg_waddr_o(reg_waddr_ex_j_0_o),     // reg write addr
    // pc_if pc寄存器（对于系统可见）
    .hold_flag_o(hold_flag_ex_j_0_o),//hold
    .hold_addr_o(hold_addr_ex_j_0_o),//hold addr
    .jump_flag_o(jump_flag_ex_j_0_o),//jump
    .jump_addr_o(jump_addr_ex_j_0_o)//jump addr
);


ex_i ex_i_0 (
    .clk(clk),
    .rst(rst),
    // id
    .iq_int_en_i(iq_int_0_en_id_o),
    .iq_int_addr_i(iq_int_0_addr_id_o),
    .iq_int_inst_i(iq_int_0_inst_id_o),
    // regs cpu核心运行寄存器
    .reg_rdata_i(reg_rdata_regs_o),       // reg read data
    .reg_wdata_o(reg_wdata_ex_i_0_o),        // reg write data
    .reg_we_o(reg_we_ex_i_0_o),                     // reg write enable
    .reg_waddr_o(reg_waddr_ex_i_0_o)     // reg write addr
);


ex_i ex_i_1 (
    .clk(clk),
    .rst(rst),
    // id
    .iq_int_en_i(iq_int_1_en_id_o),
    .iq_int_addr_i(iq_int_1_addr_id_o),
    .iq_int_inst_i(iq_int_1_inst_id_o),
    // regs cpu核心运行寄存器
    .reg_rdata_i(reg_rdata_regs_o),       // reg read data
    .reg_wdata_o(reg_wdata_ex_i_1_o),        // reg write data
    .reg_we_o(reg_we_ex_i_1_o),                     // reg write enable
    .reg_waddr_o(reg_waddr_ex_i_1_o)     // reg write addr
);


mem mem_0 (
    .clk(clk),
    .rst(rst),
    // iq 流水线上级
    .iq_mem_en_i(iq_mem_0_en_id_o),
    .iq_mem_addr_i(iq_mem_0_addr_id_o),
    .iq_mem_inst_i(iq_mem_0_inst_id_o),
    // ex_a 流水线下级
    .mem_mem_en_o(mem_mem_en_mem_0_o),
    .mem_mem_addr_o(mem_mem_addr_mem_0_o),
    .mem_mem_inst_o(mem_mem_inst_mem_0_o),
    // regs cpu核心运行寄存器
    .reg_rdata_i(reg_rdata_regs_o),       // reg read data
    // L1D
    .re_o(re_mem_0_o),                  // read enable
    .raddr_o(raddr_mem_0_o)      // read addr
);


ex_a ex_a_0 (
    .clk(clk),
    .rst(rst),
    // mem 流水线上级
    .mem_mem_en_i(mem_mem_en_mem_0_o),
    .mem_mem_addr_i(mem_mem_addr_mem_0_o),
    .mem_mem_inst_i(mem_mem_inst_mem_0_o),
    // regs cpu核心运行寄存器
    .reg_rdata_i(reg_rdata_regs_o),       // reg read data
    .reg_we_o(reg_we_ex_a_0_o),                     // reg write enable
    .reg_waddr_o(reg_waddr_ex_a_0_o),     // reg write addr
    .reg_wdata_o(reg_wdata_ex_a_0_o),        // reg write data
    // L1D
    .re_i(re_L1D_o),                  // read enable
    .rdata_i(rdata_L1D_o),      // read data
    .we_o(we_ex_a_0_o),                     // write enable
    .waddr_o(waddr_ex_a_0_o),    // write addr
    .wdata_o(wdata_ex_a_0_o)        // write data
);



endmodule

