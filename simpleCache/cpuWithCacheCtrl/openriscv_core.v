`include "defines.v"
module openriscv_core (
);
    //朧
    // RV32IM 单周期M
    
    // inoutput
    // 输入单元，暂时只输入时钟与复位信号
    // 输出单元，暂时只输出pc寄存器
    //暂时不知道fence机制，也没加
	wire clk;
	wire rst;
	
    // pc_reg
	wire [`SramAddrBus] pc_pc_reg_o;
	wire re_pc_reg_o;
	
	//id_0
	   // to pc_reg
        // to regs
    wire reg1_re_id_o;                    // reg1 read enable
    wire [`RegAddrBus] reg1_raddr_id_o;    // reg1 read addr
    wire reg2_re_id_o;                    // reg2 read enable
    wire [`RegAddrBus] reg2_raddr_id_o;    // reg2 read addr
        // to ex
    wire inst_valid_id_o;                 // inst is valid flag
    wire [`SramAddrBus] inst_addr_id_o;
    wire [6:0] opcode_id_o;
    wire [2:0] funct3_id_o;
    wire [6:0] funct7_id_o;
    wire [`RegBus] imm_I_id_o;
    wire [`RegBus] imm_S_id_o;
    wire [`RegBus] imm_B_id_o;
    wire [`RegBus] imm_U_id_o;
    wire [`RegBus] imm_J_id_o;
    wire reg_we_id_o;                     // reg write enable
    wire [`RegAddrBus] reg_waddr_id_o;     // reg write addr
        // to sram
    wire sram_re_id_o;                    // ram read enable
    wire [`SramAddrBus] sram_raddr_id_o;  // ram read addr
    wire sram_we_id_o;                    // ram write enable
    wire[`SramType] ex_rtype_id_o;

    // ex
        // from id 指令单元
        // regs cpu核心运行寄存器
    wire [`RegBus] reg_wdata_ex_o;        // reg write data
    wire reg_we_ex_o;                  // reg write enable
    wire [`RegAddrBus] reg_waddr_ex_o;  // reg write addr
        // sram 内存（模拟的，很浪费资源,fpga可以用片上ram代替）
    wire sram_we_ex_o;
    wire [`SramBus] sram_wdata_ex_o;      // ram write data
    wire [`SramAddrBus] sram_waddr_ex_o;  // ram write addr
    wire [`SramType] wtype_ex_o;        // write data
        // pc_reg pc寄存器（对于系统可见）
    wire hold_flag_ex_o;//hold
    wire [`RegBus] hold_addr_ex_o;//hold addr
    wire jump_flag_ex_o;//jump
    wire [`RegBus] jump_addr_ex_o;//jump addr
        // 流水线 待定
    wire [`SramAddrBus] inst_addr_ex_o;

    // regs
    wire [`RegBus] rdata1_regs_o;     // reg1 read data
    wire [`RegBus] rdata2_regs_o;     // reg2 read data

    // sim_ram
    wire [`SramBus] pc_rdata_ram_o;     // pc read data
    wire [`SramAddrBus] pc_raddr_ram_o;  // pc read addr out
    wire [`SramBus] ex_rdata_ram_o;     // ex read data
    

	outside u_outside(
	.clk(clk),
	.rst(rst),
	.pc_outside(pc_outside_i)
	);

    sim_ram u_sim_ram(
    .clk(clk),
    .rst(rst),
    .hold_flag_i(hold_flag_ram_i),//hold
    .jump_flag_i(jump_flag_ram_i),//jump
    .we_i(we_ram_i),                     // write enable
    .waddr_i(waddr_ram_i),    // write addr
    .wdata_i(wdata_ram_i),        // write data
    .wtype_i(wtype_ram_i),
    
    .pc_re_i(pc_re_ram_i),                  // pc read enable
    .pc_raddr_i(pc_raddr_ram_i), // pc read addr
    .pc_rdata_o(pc_rdata_ram_o),     // pc read data
    .pc_raddr_o(pc_raddr_ram_o),  // pc read addr out
    
    .ex_re_i(ex_re_ram_i),                  // ex read enable
    .ex_raddr_i(ex_raddr_ram_i), // ex read addr
    .ex_rdata_o(ex_rdata_ram_o),     // ex read data
    .ex_rtype_i(ex_rtype_ram_i)
    );

    pc_reg u_pc_reg(
    .clk(clk),
    .rst(rst),
    .jump_flag_i(jump_flag_pc_reg_i),
    .jump_addr_i(jump_addr_pc_reg_i),
    .hold_flag_i(hold_flag_pc_reg_i),
    .hold_addr_i(hold_addr_pc_reg_i),
	.pc_o(pc_pc_reg_o),
	.re_o(re_pc_reg_o)
    );

    regs u_regs(
    .clk(clk),
    .rst(rst),
    .we_i(we_regs_i),                  // reg write enable
    .waddr_i(waddr_regs_i),  // reg write addr
    .wdata_i(wdata_regs_i),      // reg write data
    .re1_i(re1_regs_i),                 // reg1 read enable
    .raddr1_i(raddr1_regs_i), // reg1 read addr
    .rdata1_o(rdata1_regs_o),     // reg1 read data
    .re2_i(re2_regs_i),                 // reg2 read enable
    .raddr2_i(raddr2_regs_i), // reg2 read addr
    .rdata2_o(rdata2_regs_o)     // reg2 read data
    );

    id_0 u_id_0(
    .clk(clk),
    .rst(rst),
	   // to pc_reg
	.inst_i(inst_id_i),             // inst content
    .inst_addr_i(inst_addr_id_i),    // inst addr
    .jump_flag_i(jump_flag_id_i),
    .hold_flag_i(hold_flag_id_i),
        // to regs
    .reg1_re_o(reg1_re_id_o),                    // reg1 read enable
    .reg1_raddr_o(reg1_raddr_id_o),    // reg1 read addr
    .reg2_re_o(reg2_re_id_o),                    // reg2 read enable
    .reg2_raddr_o(reg2_raddr_id_o),    // reg2 read addr
    .reg1_rdata_i(reg1_rdata_id_i),
        // to ex
    .inst_valid_o(inst_valid_id_o),                 // inst is valid flag
    .inst_addr_o(inst_addr_id_o),
    .opcode_o(opcode_id_o),
    .funct3_o(funct3_id_o),
    .funct7_o(funct7_id_o),
    .imm_I_o(imm_I_id_o),
    .imm_S_o(imm_S_id_o),
    .imm_B_o(imm_B_id_o),
    .imm_U_o(imm_U_id_o),
    .imm_J_o(imm_J_id_o),
    .reg_we_o(reg_we_id_o),                     // reg write enable
    .reg_waddr_o(reg_waddr_id_o),     // reg write addr
        // to sram
    .sram_re_o(sram_re_id_o),                    // ram read enable
    .sram_we_o(sram_we_id_o),                    // ram write enable
    .sram_raddr_o(sram_raddr_id_o),
    .ex_rtype_o(ex_rtype_id_o)
    );

    ex_0 u_ex_0(
    .clk(clk),
    .rst(rst),
        // from id 指令单元
    .inst_valid_i(inst_valid_ex_i),                 // inst is valid flag
    .inst_addr_i(inst_addr_ex_i),
    .opcode_i(opcode_ex_i),
    .funct3_i(funct3_ex_i),
    .funct7_i(funct7_ex_i),
    .imm_I_i(imm_I_ex_i),
    .imm_S_i(imm_S_ex_i),
    .imm_B_i(imm_B_ex_i),
    .imm_U_i(imm_U_ex_i),
    .imm_J_i(imm_J_ex_i),
    .reg_we_i(reg_we_ex_i),
    .reg_waddr_i(reg_waddr_ex_i),
        // regs cpu核心运行寄存器
    .reg1_rdata_i(reg1_rdata_ex_i),       // reg1 read data
    .reg2_rdata_i(reg2_rdata_ex_i),       // reg2 read data
    .reg_wdata_o(reg_wdata_ex_o),        // reg write data
    .reg_we_o(reg_we_ex_o),                  // reg write enable
    .reg_waddr_o(reg_waddr_ex_o),  // reg write addr
        // sram 内存（模拟的，很浪费资源,fpga可以用片上ram代替）
    .sram_we_o(sram_we_ex_o),
    .sram_rdata_i(sram_rdata_ex_i),      // ram read data
    .sram_wdata_o(sram_wdata_ex_o),      // ram write data
    .sram_waddr_o(sram_waddr_ex_o),  // ram write addr
    .wtype_o(wtype_ex_o),
        // pc_reg pc寄存器（对于系统可见）
	.pc_re_i(pc_re_ex_i),
	.pc_i(pc_ex_i),
    .hold_flag_o(hold_flag_ex_o),//hold
    .hold_addr_o(hold_addr_ex_o),//hold addr
    .jump_flag_o(jump_flag_ex_o),//jump
    .jump_addr_o(jump_addr_ex_o),//jump addr
        // 流水线 待定
    .inst_addr_o(inst_addr_ex_o)
    );





endmodule

