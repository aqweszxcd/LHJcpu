
`include "defines.v"
//“取指”与“译码”//其实是译码+重排缓存+发射
// identify module//id_ds
module id (                                       
input wire clk,
input wire rst,
//ex
input wire jump_flag_i,
input wire jump_continue_i,
input wire [`RegBus] jump_addr_i,
input wire hold_flag_i,
input wire [`RegBus] hold_addr_i,
//pc_if
input wire [`SramAddrBusx4] fb_addr_i,//Fetch Buffer
input wire [`SramBusx4] fb_i,//Fetch Buffer
input wire [3:0] fb_en_i,//Fetch Buffer Enable
output reg full_flag_o,



// to ex int0 (执行)
output reg iq_int_0_en_o,
output reg [71:0]iq_int_0_inst_o,
output reg [31:0]iq_int_0_addr_o,
// to ex int1 (执行)
output reg iq_int_1_en_o,
output reg [71:0]iq_int_1_inst_o,
output reg [31:0]iq_int_1_addr_o,
// to ex mem (执行)
output reg iq_mem_0_en_o,
output reg [71:0]iq_mem_0_inst_o,
output reg [31:0]iq_mem_0_addr_o,
// to ex jump (执行)
output reg iq_jump_0_en_o,
output reg [71:0]iq_jump_0_inst_o,
output reg [31:0]iq_jump_0_addr_o
// to wb
//input wire full_flag_i
);

wire [`SramAddrBus] fb_addr[0:3];
wire [`SramBus] fb[0:3];

assign fb_addr[0]=fb_addr_i[31:0];
assign fb_addr[1]=fb_addr_i[63:32];
assign fb_addr[2]=fb_addr_i[95:64];
assign fb_addr[3]=fb_addr_i[127:96];
assign fb[0]=fb_i[31:0];
assign fb[1]=fb_i[63:32];
assign fb[2]=fb_i[95:64];
assign fb[3]=fb_i[127:96];
    
    //立即数是有符号数
    //关于补位，默认低位补0，高位默认补“最高位（31）”，补到[31：0]为止
    //不光立即数需要补位，执行部分中的结果也需要按照reference card的注释进行补位
    
    //指令拆解
    //注：虽然全部拆出来了，看起来很多，有很多通道都是公用的很浪费资源，实际上综合的时候都会综合掉

//    wire[`RegBus] imm_I = {{(`RegWidth-12){inst_i[31]}},inst_i[31:20]};
//    wire[`RegBus] imm_S = {{(`RegWidth-12){inst_i[31]}},inst_i[31:25],inst_i[11:7]};
//    wire[`RegBus] imm_B = {{(`RegWidth-13){inst_i[31]}},inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
//    wire[`RegBus] imm_U = {inst_i[31:12],{(`RegWidth-20){1'b0}}};
//    wire[`RegBus] imm_J = {{(`RegWidth-21){inst_i[31]}},inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};

function [`DecodedInstBus] DECODE;

input [31:0] inst;
//type I
reg inst_valid;//1
reg[6:0] opcode;//7
reg[2:0] funct3;//3
reg[6:0] funct7;//7
reg[4:0] rd;//5
reg[4:0] rs1;//5
reg[4:0] rs2;//5

reg reg_we;//1
reg reg1_re;//1
reg reg2_re;//1
reg sram_re;//1
reg sram_we;//1
reg[31:0] imm;//32
reg [2:0] inst_type;//3 //jump/ram/others

//1+7+3+7+5+5+5+1+1+1+1+1+32+3
//8+10+15+5+35
//18+55
//73
begin
if(inst[1:0]==2'b11)begin
        case (inst[6:0])
            `INST_TYPE_R: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            `INST_TYPE_I: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = {{(`RegWidth-12){inst[31]}},inst[31:20]};
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            `INST_TYPE_I_L: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = {{(`RegWidth-12){inst[31]}},inst[31:20]};
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Enable;
                sram_we = `Disable;
                inst_type = 3'b010;
            end
            `INST_TYPE_I_J: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = 4;
                
                imm = {{(`RegWidth-12){inst[31]}},inst[31:20]};
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            `INST_TYPE_I_E: begin       ///////////////////////////////////////////////////////////////////////////待实现
                //nop指令
                inst_valid = `Disable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = `ZeroWord;
                reg_we = `Disable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            `INST_TYPE_I_FENCE: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = `ZeroWord;
                reg_we = `Disable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            `INST_TYPE_S: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = {{(`RegWidth-12){inst[31]}},inst[31:25],inst[11:7]};
                reg_we = `Disable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Enable;
                inst_type = 3'b010;
            end
            `INST_TYPE_B: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = {{(`RegWidth-13){inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                reg_we = `Disable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            `INST_TYPE_U_LUI: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = {inst[31:12],{(`RegWidth-20){1'b0}}};
                reg_we = `Enable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            `INST_TYPE_U_AUIPC: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = inst[24:20];
                
                imm = {inst[31:12],{(`RegWidth-20){1'b0}}};
                reg_we = `Enable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            `INST_TYPE_J_JAL: begin
                inst_valid = `Enable;
                opcode = inst[6:0];
                funct3 = inst[14:12];
                funct7 = inst[31:25];
                rd = inst[11:7];
                rs1 = inst[19:15];
                rs2 = 4;
                
                imm = {{(`RegWidth-21){inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
                reg_we = `Enable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            default: begin
                //nop指令
                inst_valid = `Disable;
                opcode = `ZeroWord;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = `ZeroWord;
                rs2 = `ZeroWord;
                
                imm = `ZeroWord;
                reg_we = `Disable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
        endcase
end

else begin
        case({inst[1:0],inst[15:13],inst[12],inst[11:10],inst[6:5]})
            {`INST_C_LWSP_OP,`INST_C_LWSP_3,inst[12],inst[11:10],inst[6:5]}:begin//C_LWSP lw rd, (4*imm)(sp) //load word from sp
                inst_valid = `Enable;
                opcode = `INST_TYPE_I_L;
                funct3 = `INST_LW_3;
                funct7 = `ZeroWord;
                rd = inst[11:7];
                rs1 = `REG_SP;
                rs2 = `ZeroWord;
                
                imm = $signed($signed({{inst[12]},{inst[6:2]}}));
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Enable;
                sram_we = `Disable;
                inst_type = 3'b010;
            end
            {`INST_C_SWSP_OP,`INST_C_SWSP_3,inst[12],inst[11:10],inst[6:5]}:begin//C_SWSP sw rs2, (4*imm)(sp) //store word to sp
                inst_valid = `Enable;
                opcode = `INST_TYPE_S;
                funct3 = `INST_SW_3;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = `REG_SP;
                rs2 = inst[6:2];
                
                imm = $signed($signed(inst[12:7]));
                reg_we = `Disable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Enable;
                inst_type = 3'b010;
            end
            {`INST_C_LW_OP,`INST_C_LW_3,inst[12],inst[11:10],inst[6:5]}:begin//C_LW lw rd', (4*imm)(rs1') //load word
                inst_valid = `Enable;
                opcode = `INST_TYPE_I_L;
                funct3 = `INST_LW_3;
                funct7 = `ZeroWord;
                rd = inst[4:2]+8;
                rs1 = inst[9:7]+8;
                rs2 = `ZeroWord;
                
                imm = $signed(2*$signed({{inst[12:10]},{inst[6:5]}}));
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Enable;
                sram_we = `Disable;
                inst_type = 3'b010;
            end
            {`INST_C_SW_OP,`INST_C_SW_3,inst[12],inst[11:10],inst[6:5]}:begin//C_SW sw rs1', (4*imm)(rs2') //store word
                inst_valid = `Enable;
                opcode = `INST_TYPE_S;
                funct3 = `INST_SW_3;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = inst[9:7]+8;
                rs2 = inst[4:2]+8;
                
                imm = $signed(2*$signed({{inst[12:10]},{inst[6:5]}}));
                reg_we = `Disable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Enable;
                inst_type = 3'b010;
            end
            {`INST_C_J_OP,`INST_C_J_3,inst[12],inst[11:10],inst[6:5]}:begin//C_J jal x0, 2*offset //jump
                inst_valid = `Enable;
                opcode = `INST_TYPE_J_JAL;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = `REG_X0;
                rs1 = `ZeroWord;
                rs2 = 2;
                
                imm = $signed($signed(inst[12:2]));
                reg_we = `Enable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            {`INST_C_JAL_OP,`INST_C_JAL_3,inst[12],inst[11:10],inst[6:5]}:begin//C_JAL jal ra, 2*offset //jump and link
                inst_valid = `Enable;
                opcode = `INST_TYPE_J_JAL;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = `REG_RA;
                rs1 = `ZeroWord;
                rs2 = 2;
                
                imm = $signed($signed(inst[12:2]));
                reg_we = `Enable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            {`INST_C_JR_OP,`INST_C_JR_3,`INST_C_JR_4E,inst[11:10],inst[6:5]}:begin//C_JR jalr x0,rs1,0 //jump reg       //C_MV add rd,x0,rs2 //move
                if(inst[6:2]==`REG_X0)begin
                inst_valid = `Enable;
                opcode = `INST_TYPE_I_J;
                funct3 = `INST_JALR_3;
                funct7 = `ZeroWord;
                rd = `REG_X0;
                rs1 = inst[11:7];
                rs2 = 2;
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
                end
                else begin
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_ADD_3;
                funct7 = `INST_ADD_7;
                rd = inst[11:7];
                rs1 = `REG_X0;
                rs2 = inst[6:2];
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
                end
            end
/*            {`INST_C_MV_OP,`INST_C_MV_3,`INST_C_MV_4E,inst[11:10],inst[6:5]}:begin//C_MV add rd,x0,rs2 //move
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_ADD_3;
                funct7 = `INST_ADD_7;
                rd = inst[11:7];
                rs1 = `REG_X0;
                rs2 = inst[6:2];
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end*/
            {`INST_C_JALR_OP,`INST_C_JALR_3,`INST_C_JALR_4E,inst[11:10],inst[6:5]}:begin//C_JALR jalr ra,rs1,0 //jump and link reg      //C_ADD add rd,rd,rs2 //add     //C_EBREAK ebreak //environment break
                if(inst[6:2]==`REG_X0)begin
                inst_valid = `Enable;
                opcode = `INST_TYPE_I_J;
                funct3 = `INST_JALR_3;
                funct7 = `ZeroWord;
                rd = `REG_RA;
                rs1 = inst[11:7];
                rs2 = 2;
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
                end
                else begin
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_ADD_3;
                funct7 = `INST_ADD_7;
                rd = inst[11:7];
                rs1 = inst[11:7];
                rs2 = inst[6:2];
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
                end
            end
/*            {`INST_C_ADD_OP,`INST_C_ADD_3,`INST_C_ADD_4E,inst[11:10],inst[6:5]}:begin//C_ADD add rd,rd,rs2 //add
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_ADD_3;
                funct7 = `INST_ADD_7;
                rd = inst[11:7];
                rs1 = inst[11:7];
                rs2 = inst[6:2];
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end*/
/*            {`INST_C_EBREAK_OP,`INST_C_EBREAK_3,`INST_C_EBREAK_4E,inst[11:10],inst[6:5]}:begin//C_EBREAK ebreak //environment break
                inst_valid = `Disable;
                opcode = `ZeroWord;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = `ZeroWord;
                rs2 = `ZeroWord;
                
                imm = `ZeroWord;
                reg_we = `Disable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end*/
            {`INST_C_BEQZ_OP,`INST_C_BEQZ_3,inst[12],inst[11:10],inst[6:5]}:begin//C_BEQZ beq rs',x0,2*imm //bench == 0
                inst_valid = `Enable;
                opcode = `INST_TYPE_B;
                funct3 = `INST_BEQ_3;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = inst[9:7]+8;
                rs2 = `REG_X0;
                
                imm = $signed(2*$signed({{inst[12:10]},{inst[6:2]}}));
                reg_we = `Disable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            {`INST_C_BNEZ_OP,`INST_C_BNEZ_3,inst[12],inst[11:10],inst[6:5]}:begin//C_BNEZ bne rs',x0,2*imm //bench != 0
                inst_valid = `Enable;
                opcode = `INST_TYPE_B;
                funct3 = `INST_BNE_3;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = inst[9:7]+8;
                rs2 = `REG_X0;
                
                imm = $signed(2*$signed({{inst[12:10]},{inst[6:2]}}));
                reg_we = `Disable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b100;
            end
            {`INST_C_LI_OP,`INST_C_LI_3,inst[12],inst[11:10],inst[6:5]}:begin//C_LI addi rd,x0,imm //load immediate
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_ADDI_3;
                funct7 = `ZeroWord;
                rd = inst[11:7];
                rs1 = `REG_X0;
                rs2 = `ZeroWord;
                
                imm = $signed({{inst[12]},{inst[6:2]}});
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_LUI_OP,`INST_C_LUI_3,inst[12],inst[11:10],inst[6:5]}:begin//C_LUI lui rd,imm //load upper imm      //C_ADDI16SP addi sp,sp,16*imm //add imm*16 to sp
                if(inst[11:7]==`REG_SP)begin
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_ADDI_3;
                funct7 = `ZeroWord;
                rd = `REG_SP;
                rs1 = `REG_SP;
                rs2 = `ZeroWord;
                
                imm = $signed(16*$signed({{inst[12]},{inst[6:2]}}));
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
                end
                else begin
                inst_valid = `Enable;
                opcode = `INST_TYPE_U_LUI;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = inst[11:7];
                rs1 = `ZeroWord;
                rs2 = `ZeroWord;
                
                imm = $signed({{inst[12]},{inst[6:2]}})<<12;
                reg_we = `Enable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
                end
            end
/*            {`INST_C_ADDI16SP_OP,`INST_C_ADDI16SP_3,inst[12],inst[11:10],inst[6:5]}:begin//C_ADDI16SP addi sp,sp,16*imm //add imm*16 to sp
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_ADDI_3;
                funct7 = `ZeroWord;
                rd = `REG_SP;
                rs1 = `REG_SP;
                rs2 = `ZeroWord;
                
                imm = $signed(16*$signed({{inst[12]},{inst[6:2]}}));
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end*/
            {`INST_C_ADDI_OP,`INST_C_ADDI_3,inst[12],inst[11:10],inst[6:5]}:begin//C_ADDI addi rd,rd,imm //add immediate        //C_NOP addi x0,x0,0 //no operation
                if(inst[11:7]==`REG_X0)begin
                inst_valid = `Disable;
                opcode = `ZeroWord;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = `ZeroWord;
                rs2 = `ZeroWord;
                
                imm = `ZeroWord;
                reg_we = `Disable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
                end
                else begin
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_ADDI_3;
                funct7 = `ZeroWord;
                rd = inst[11:7];
                rs1 = inst[11:7];
                rs2 = `ZeroWord;
                
                imm = $signed({{inst[12]},{inst[6:2]}});
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
                end
            end
/*            {`INST_C_NOP_OP,`INST_C_NOP_3,inst[12],inst[11:10],inst[6:5]}:begin//C_NOP addi x0,x0,0 //no operation
                inst_valid = `Disable;
                opcode = `ZeroWord;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = `ZeroWord;
                rs2 = `ZeroWord;
                
                imm = `ZeroWord;
                reg_we = `Disable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end*/
            {`INST_C_ADDI4SPN_OP,`INST_C_ADDI4SPN_3,inst[12],inst[11:10],inst[6:5]}:begin//C_ADDI4SPN addi rd',sp,4*imm //add imm*4 + sp
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_ADDI_3;
                funct7 = `ZeroWord;
                rd = inst[4:2]+8;
                rs1 = `REG_SP;
                rs2 = `ZeroWord;
                
                imm = $unsigned(4*$unsigned(inst[12:5]));
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_SLLI_OP,`INST_C_SLLI_3,inst[12],inst[11:10],inst[6:5]}:begin//C_SLLI slli rd,rd,imm //shift left logical imm
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_SLLI_3;
                funct7 = `INST_SLLI_7;
                rd = inst[11:7];
                rs1 = inst[11:7];
                rs2 = `ZeroWord;
                
                imm = {{27'h00},{inst[6:2]}};
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_SRLI_OP,`INST_C_SRLI_3,inst[12],`INST_C_SRLI_6E,inst[6:5]}:begin//C_SRLI srli rd',rd',imm //shift right logical imm
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_SRLI_3;
                funct7 = `INST_SRLI_7;
                rd = inst[9:7]+8;
                rs1 = inst[9:7]+8;
                rs2 = `ZeroWord;
                
                imm = {{27'h00},{inst[6:2]}};
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_SRAI_OP,`INST_C_SRAI_3,inst[12],`INST_C_SRAI_6E,inst[6:5]}:begin//C_SRAI srai rd',rd',imm //shift right arith imm
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_SRAI_3;
                funct7 = `INST_SRAI_7;
                rd = inst[9:7]+8;
                rs1 = inst[9:7]+8;
                rs2 = `ZeroWord;
                
                imm = {{27'h20},{inst[6:2]}};
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_ANDI_OP,`INST_C_ANDI_3,inst[12],`INST_C_ANDI_6E,inst[6:5]}:begin//C_ANDI andi rd',rd',imm //add imm
                inst_valid = `Enable;
                opcode = `INST_TYPE_I;
                funct3 = `INST_ANDI_3;
                funct7 = `ZeroWord;
                rd = inst[9:7]+8;
                rs1 = inst[9:7]+8;
                rs2 = `ZeroWord;
                
                imm = $signed({{inst[12]},{inst[6:2]}});
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_AND_OP,`INST_C_AND_3,`INST_C_AND_4E,`INST_C_AND_6E,`INST_C_AND_8E2}:begin//C_AND and rd',rd',rs2' //and
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_AND_3;
                funct7 = `INST_AND_7;
                rd = inst[9:7]+8;
                rs1 = inst[9:7]+8;
                rs2 = inst[4:2]+8;
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_OR_OP,`INST_C_OR_3,`INST_C_OR_4E,`INST_C_OR_6E,`INST_C_OR_8E2}:begin//C_OR or rd',rd',rs2' //or
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_OR_3;
                funct7 = `INST_OR_7;
                rd = inst[9:7]+8;
                rs1 = inst[9:7]+8;
                rs2 = inst[4:2]+8;
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_XOR_OP,`INST_C_XOR_3,`INST_C_XOR_4E,`INST_C_XOR_6E,`INST_C_XOR_8E2}:begin//C_XOR xor rd',rd',rs2' //xor
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_XOR_3;
                funct7 = `INST_XOR_7;
                rd = inst[9:7]+8;
                rs1 = inst[9:7]+8;
                rs2 = inst[4:2]+8;
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            {`INST_C_SUB_OP,`INST_C_SUB_3,`INST_C_SUB_4E,`INST_C_SUB_6E,`INST_C_SUB_8E2}:begin//C_SUB sub rd',rd',rs2' //sub
                inst_valid = `Enable;
                opcode = `INST_TYPE_R;
                funct3 = `INST_SUB_3;
                funct7 = `INST_SUB_7;
                rd = inst[9:7]+8;
                rs1 = inst[9:7]+8;
                rs2 = inst[4:2]+8;
                
                imm = `ZeroWord;
                reg_we = `Enable;
                reg1_re = `Enable;
                reg2_re = `Enable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
            default: begin
                //nop指令
                inst_valid = `Disable;
                opcode = `ZeroWord;
                funct3 = `ZeroWord;
                funct7 = `ZeroWord;
                rd = `ZeroWord;
                rs1 = `ZeroWord;
                rs2 = `ZeroWord;
                
                imm = `ZeroWord;
                reg_we = `Disable;
                reg1_re = `Disable;
                reg2_re = `Disable;
                sram_re = `Disable;
                sram_we = `Disable;
                inst_type = 3'b001;
            end
        endcase
end
//reg inst_valid;//1
//reg[6:0] opcode;//7
//reg[2:0] funct3;//3
//reg[6:0] funct7;//7
//reg[4:0] rd;//5
//reg[4:0] rs1;//5
//reg[4:0] rs2;//5

//reg reg_we;//1
//reg reg1_re;//1
//reg reg2_re;//1
//reg sram_re;//1
//reg sram_we;//1
//reg[31:0] imm;//32
//reg [2:0] inst_type;//3 //jump/ram/others
DECODE={{inst_valid},{opcode},{funct3},{funct7},{rd},{rs1},{rs2},{reg_we},{reg1_re},{reg2_re},{sram_re},{sram_we},{imm},{inst_type}};
//                 72                71:65        64:62     61:55   54:50       44:40                38             37             36             35               34:3    2:0
//                                                                                            49:45        39
end
endfunction



/*
//integer
integer a,b,c,d,e,x,y,z;
//rob addr 结构
reg [31:0] rob_addr [63:0];
//rob 结构
reg [73:0] rob [63:0];
//存在rob里的in_flight 指令
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=55;a<64;a=a+1)begin
                rob[a]<=`ZeroWord256;
        end
end
else begin
rob[56]<=rob[55];
rob[58]<=rob[57];
rob[59]<=rob[58];
rob[61]<=rob[60];
rob[63]<=rob[62];
end
end
//由pc_if写入id
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<55;a=a+1)begin
                rob[a]<=`ZeroWord256;
        end
end
else begin
        for(a=0,b=0;(a<55&&b<4);a=a+1)begin//write rob
                if(rob[a][73:72]==2'b00 && fb_en_i[b]==`Enable) begin
                        rob[a]<={{1'b0},{DECODE(fb[b])}};
                        rob_addr[a]<=fb_addr[b];
                        b=b+1;
                end
        end
        for(a=0,b=0;a<55;a=a+1)begin
                if(rob[a][73:72]==2'b00) begin
                        b=b+1;
                end
        end
        if(b>=21) full_flag_o<=`Disable;//44=>因为55-44+1==12
        else full_flag_o<=`Enable;
end
end

//判断rd写前是否要读/rs1读前是否要写/rs2读前是否要写
reg [63:0] rob_en [63:0];
reg [63:0] rob_en_front [63:0];
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<64;a=a+1)begin
                rob_en[a]<=`ZeroWord256;
        end
end
else begin
        for(a=0;a<64;a=a+1)begin
                for(b=0;b<64;b=b+1)begin
                        if(rob[a][73:72]==2'b01)begin
                                if(rob_addr[a]>rob_addr[b]) begin
                                        if(    (rob[a][39]==`Enable&&rob[a][54:50]!=5'b00000)  &&  (rob[b][38]==`Enable&&rob[b][49:45]==rob[a][54:50])  )begin//写的前面要读
                                                rob_en[a][b]<=`Disable;
                                        end
                                        if(    (rob[a][39]==`Enable&&rob[a][54:50]!=5'b00000)  &&  (rob[b][37]==`Enable&&rob[b][44:40]==rob[a][54:50])  )begin//写的前面要读
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else if(  (rob[a][39]==`Enable&&rob[a][54:50]!=5'b00000)  &&  (rob[b][39]==`Enable&&rob[b][54:50]==rob[a][54:50])  )begin//写的前面要写
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else if(  (rob[a][38]==`Enable&&rob[a][49:45]!=5'b00000)  &&  (rob[b][39]==`Enable&&rob[b][54:50]==rob[a][49:45])  )begin//读的前面要写
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else if(  (rob[a][37]==`Enable&&rob[a][44:40]!=5'b00000)  &&  (rob[b][39]==`Enable&&rob[b][54:50]==rob[a][44:40])  )begin//读的前面要写
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else begin
                                                rob_en[a][b]<=`Enable;
                                        end
                                end
                                else begin
                                        rob_en[a][b]<=`Enable;
                                end
                        end
                        else begin
                                rob_en[a][b]<=`Disable;
                        end
                end
        end
end
//        for(a=0;a<64;a=a+1)begin
//                rob_en_front[a]<=rob_en[a];
//        end
end

//判断前面是否有jump
reg [63:0] jump_front_en [63:0];
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<64;a=a+1)begin
                jump_front_en[a]<=`ZeroWord256;
        end
end
else begin
        for(a=0;a<64;a=a+1)begin
                for(b=0;b<64;b=b+1)begin
                        if((rob_addr[a]>rob_addr[b])&&(rob[b][2:0]==3'b100)) begin
                                jump_front_en[a][b]<=`Enable;
                        end
                        else begin
                                jump_front_en[a][b]<=`Disable;
                        end
                end
        end
end
end

//发射
always@(posedge clk)begin
if(rst == `Enable)begin
        iq_int_0_en_o<=`Disable;//read rob
        iq_int_0_inst_o<=`ZeroWord256;
        iq_int_0_addr_o<=`ZeroWord256;
        iq_int_1_en_o<=`Disable;
        iq_int_1_inst_o<=`ZeroWord256;
        iq_int_1_addr_o<=`ZeroWord256;
        iq_mem_0_en_o<=`Disable;
        iq_mem_0_inst_o<=`ZeroWord256;
        iq_mem_0_addr_o<=`ZeroWord256;
        iq_jump_0_en_o<=`Disable;
        iq_jump_0_inst_o<=`ZeroWord256;
        iq_jump_0_addr_o<=`ZeroWord256;
end
else if(jump_flag_i == `Enable)begin         // jump
        for(a=0;a<64;a=a+1)begin
                if(rob_addr[a]>=rob_addr[55])begin
                rob[a]<=`ZeroWord256;
                rob_addr[a]<=`ZeroWord256;
                
                iq_jump_0_en_o<=`Disable;
                iq_jump_0_inst_o<=`ZeroWord256;
                iq_jump_0_addr_o<=`ZeroWord256;
                end
        end
end
//else if(jump_continue_i == `Enable)begin         // jump
//        for(a=0;a<64;a=a+1)begin
//                if(rob_addr[a]==rob_addr[56])begin
//                rob[a]<=`ZeroWord256;
//                rob_addr[a]<=`ZeroWord256;
//                end
//        end
//end
else begin
        for(a=0,x=0,y=0,z=0;a<55;a=a+1)begin//read rob
                if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b100&&x<1&&rob_en[a]==`OneWord64&&jump_front_en[a]==`ZeroWord64) begin//&&rob_en_front[a]==`OneWord64 未添加 可能需要添加
                        iq_jump_0_inst_o<=rob[a][71:0];
                        iq_jump_0_addr_o<=rob_addr[a];
                        rob[55]<=rob[a];
                        rob_addr[55]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        x=x+1;
                end
                else if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b010&&y<1&&rob_en[a]==`OneWord64&&jump_front_en[a]==`ZeroWord64) begin
                        iq_mem_0_inst_o<=rob[a][71:0];
                        iq_mem_0_addr_o<=rob_addr[a];
                        rob[57]<=rob[a];
                        rob_addr[57]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        y=y+1;
                end
                else if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b001&&z<1&&rob_en[a]==`OneWord64&&jump_front_en[a]==`ZeroWord64) begin
                        iq_int_0_inst_o<=rob[a][71:0];
                        iq_int_0_addr_o<=rob_addr[a];
                        rob[60]<=rob[a];
                        rob_addr[60]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        z=z+1;
                end
                else if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b001&&z<2&&rob_en[a]==`OneWord64&&jump_front_en[a]==`ZeroWord64) begin
                        iq_int_1_inst_o<=rob[a][71:0];
                        iq_int_1_addr_o<=rob_addr[a];
                        rob[62]<=rob[a];
                        rob_addr[62]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        z=z+1;
                end
        end
        
        if(x==0)begin
        iq_jump_0_en_o<=`Disable;
        rob[55]<=`ZeroWord256;
        rob_addr[55]<=`ZeroWord256;
        end
        else begin
        iq_jump_0_en_o<=`Enable;
        end
        
        if(y==0)begin
        iq_mem_0_en_o<=`Disable;
        rob[57]<=`ZeroWord256;
        rob_addr[57]<=`ZeroWord256;
        end
        else begin
        iq_mem_0_en_o<=`Enable;
        end
        
        if(z==0)begin
        iq_int_0_en_o<=`Disable;
        rob[60]<=`ZeroWord256;
        rob_addr[60]<=`ZeroWord256;
        iq_int_1_en_o<=`Disable;
        rob[62]<=`ZeroWord256;
        rob_addr[62]<=`ZeroWord256;
        end
        else if(z==1)begin
        iq_int_0_en_o<=`Enable;
        iq_int_1_en_o<=`Disable;
        rob[62]<=`ZeroWord256;
        rob_addr[62]<=`ZeroWord256;
        end
        else begin
        iq_int_0_en_o<=`Enable;
        iq_int_1_en_o<=`Enable;                
        end

end
end*/
`define RobNum 48
//integer
integer a,b,x,y,z;
//rob addr 结构
reg [31:0] rob_addr [`RobNum-1:0];
//rob 结构
reg [73:0] rob [`RobNum-1:0];
//存在rob里的in_flight 指令
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=(`RobNum-9);a<`RobNum;a=a+1)begin
                rob[a]<=`ZeroWord256;
        end
end
else begin
rob[`RobNum-8]<=rob[`RobNum-9];
rob[`RobNum-6]<=rob[`RobNum-7];
rob[`RobNum-5]<=rob[`RobNum-6];
rob[`RobNum-3]<=rob[`RobNum-4];
rob[`RobNum-1]<=rob[`RobNum-2];
rob_addr[`RobNum-8]<=rob_addr[`RobNum-9];
rob_addr[`RobNum-6]<=rob_addr[`RobNum-7];
rob_addr[`RobNum-5]<=rob_addr[`RobNum-6];
rob_addr[`RobNum-3]<=rob_addr[`RobNum-4];
rob_addr[`RobNum-1]<=rob_addr[`RobNum-2];
end
end
//由pc_if写入id
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<(`RobNum-9);a=a+1)begin
                rob[a]<=`ZeroWord256;
                rob_addr[a]<=`ZeroWord256;
        end
end
else if (jump_flag_i==`Disable) begin
        for(a=0,b=0;(a<(`RobNum-9)&&b<4);a=a+1)begin//write rob
                if(rob[a][73:72]==2'b00 && fb_en_i[b]==`Enable) begin
                        rob[a]<={{1'b0},{DECODE(fb[b])}};
                        rob_addr[a]<=fb_addr[b];
                        b=b+1;
                end
        end
        for(a=0,b=0;a<(`RobNum-9);a=a+1)begin
                if(rob[a][73:72]==2'b00) begin
                        b=b+1;
                end
        end
        if(b>20) full_flag_o<=`Disable;
        else full_flag_o<=`Enable;
end
end

//判断rd写前是否要读/rs1读前是否要写/rs2读前是否要写
reg [`RobNum-1:0] rob_en [`RobNum-1:0];
//reg [`RobNum-1:0] rob_en_front [`RobNum-1:0];
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<`RobNum;a=a+1)begin
                rob_en[a]<=`ZeroWord256;
        end
end
else begin
        for(a=0;a<`RobNum;a=a+1)begin
                for(b=0;b<`RobNum;b=b+1)begin
                        if(rob[a][73:72]==2'b01)begin
                                if(rob_addr[a]>rob_addr[b]) begin
                                        if(    (rob[a][39]==`Enable&&rob[a][54:50]!=5'b00000)  &&  (rob[b][38]==`Enable&&rob[b][49:45]==rob[a][54:50])  )begin//写的前面要读
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else if(    (rob[a][39]==`Enable&&rob[a][54:50]!=5'b00000)  &&  (rob[b][37]==`Enable&&rob[b][44:40]==rob[a][54:50])  )begin//写的前面要读
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else if(  (rob[a][39]==`Enable&&rob[a][54:50]!=5'b00000)  &&  (rob[b][39]==`Enable&&rob[b][54:50]==rob[a][54:50])  )begin//写的前面要写
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else if(  (rob[a][38]==`Enable&&rob[a][49:45]!=5'b00000)  &&  (rob[b][39]==`Enable&&rob[b][54:50]==rob[a][49:45])  )begin//读的前面要写
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else if(  (rob[a][37]==`Enable&&rob[a][44:40]!=5'b00000)  &&  (rob[b][39]==`Enable&&rob[b][54:50]==rob[a][44:40])  )begin//读的前面要写
                                                rob_en[a][b]<=`Disable;
                                        end
                                        else begin
                                                rob_en[a][b]<=`Enable;
                                        end
                                end
                                else begin
                                        rob_en[a][b]<=`Enable;
                                end
                        end
                        else begin
                                rob_en[a][b]<=`Disable;
                        end
                end
        end
end
//        for(a=0;a<`RobNum;a=a+1)begin
//                rob_en_front[a]<=rob_en[a];
//        end
end

//判断前面是否有jump
reg [`RobNum-1:0] jump_front_en [`RobNum-1:0];
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<`RobNum;a=a+1)begin
                jump_front_en[a]<=`ZeroWord256;
        end
end
else begin
        for(a=0;a<`RobNum;a=a+1)begin
                for(b=0;b<`RobNum;b=b+1)begin
                        if((rob_addr[a]>rob_addr[b])&&(rob[b][73:72]==2'b01)&&(rob[b][2:0]==3'b100)) begin
                                jump_front_en[a][b]<=`Enable;
                        end
                        else begin
                                jump_front_en[a][b]<=`Disable;
                        end
                end
        end
end
end
//判断前面是否有mem
reg [`RobNum-1:0] mem_front_en [`RobNum-1:0];
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<`RobNum;a=a+1)begin
                mem_front_en[a]<=`ZeroWord256;
        end
end
else begin
        for(a=0;a<`RobNum;a=a+1)begin
                for(b=0;b<`RobNum;b=b+1)begin
                        if((rob_addr[a]>rob_addr[b])&&(rob[b][73:72]==2'b01)&&(rob[b][2:0]==3'b010)) begin
                                mem_front_en[a][b]<=`Enable;
                        end
                        else begin
                                mem_front_en[a][b]<=`Disable;
                        end
                end
        end
end
end
//判断前面是否有指令（用于判断是否运行fence.i）
reg [`RobNum-1:0] inst_front_en [`RobNum-1:0];
always@(posedge clk)begin
if(rst==`Enable)begin
        for(a=0;a<`RobNum;a=a+1)begin
                inst_front_en[a]<=`ZeroWord256;
        end
end
else begin
        for(a=0;a<`RobNum;a=a+1)begin
                for(b=0;b<`RobNum;b=b+1)begin
                        if(rob_addr[a]>rob_addr[b]&&(rob[b][73:72]==2'b01)) begin
                                inst_front_en[a][b]<=`Enable;
                        end
                        else begin
                                inst_front_en[a][b]<=`Disable;
                        end
                end
        end
end
end

//发射
always@(posedge clk)begin
if(rst == `Enable)begin
        iq_int_0_en_o<=`Disable;//read rob
        iq_int_0_inst_o<=`ZeroWord256;
        iq_int_0_addr_o<=`ZeroWord256;
        iq_int_1_en_o<=`Disable;
        iq_int_1_inst_o<=`ZeroWord256;
        iq_int_1_addr_o<=`ZeroWord256;
        iq_mem_0_en_o<=`Disable;
        iq_mem_0_inst_o<=`ZeroWord256;
        iq_mem_0_addr_o<=`ZeroWord256;
        iq_jump_0_en_o<=`Disable;
        iq_jump_0_inst_o<=`ZeroWord256;
        iq_jump_0_addr_o<=`ZeroWord256;
end
else if(jump_flag_i == `Enable)begin         // jump
        for(a=0;a<`RobNum;a=a+1)begin
                if(rob_addr[a]>=rob_addr[`RobNum-8])begin
                rob[a]<=`ZeroWord256;
                rob_addr[a]<=`ZeroWord256;
                
                iq_jump_0_en_o<=`Disable;
                iq_jump_0_inst_o<=`ZeroWord256;
                iq_jump_0_addr_o<=`ZeroWord256;
                end
        end
end
//else if(jump_continue_i == `Enable)begin         // jump
//        for(a=0;a<`RobNum;a=a+1)begin
//                if(rob_addr[a]==rob_addr[56])begin
//                rob[a]<=`ZeroWord256;
//                rob_addr[a]<=`ZeroWord256;
//                end
//        end
//end
else begin
        for(a=0,x=0,y=0,z=0;a<(`RobNum-9);a=a+1)begin//read rob
                if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b100&&rob[a][71:65]==`INST_TYPE_I_FENCE&&x<1&&rob_en[a]=={`RobNum{1'b1}}&&inst_front_en[a]=={`RobNum{1'b0}}) begin//是否该发射fence指令
                        iq_jump_0_inst_o<=rob[a][71:0];
                        iq_jump_0_addr_o<=rob_addr[a];
                        rob[`RobNum-9]<=rob[a];
                        rob_addr[`RobNum-9]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        x=x+1;
                end
                else if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b100&&rob[a][71:65]!=`INST_TYPE_I_FENCE&&x<1&&rob_en[a]=={`RobNum{1'b1}}&&jump_front_en[a]=={`RobNum{1'b0}}) begin//&&rob_en_front[a]==`{`RobNum{1'b1}} 未添加 可能需要添加
                        iq_jump_0_inst_o<=rob[a][71:0];
                        iq_jump_0_addr_o<=rob_addr[a];
                        rob[`RobNum-9]<=rob[a];
                        rob_addr[`RobNum-9]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        x=x+1;
                end
                else if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b010&&y<1&&rob_en[a]=={`RobNum{1'b1}}&&jump_front_en[a]=={`RobNum{1'b0}}&&mem_front_en[a]=={`RobNum{1'b0}}) begin
                        iq_mem_0_inst_o<=rob[a][71:0];
                        iq_mem_0_addr_o<=rob_addr[a];
                        rob[`RobNum-7]<=rob[a];
                        rob_addr[`RobNum-7]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        y=y+1;
                end
                else if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b001&&z<1&&rob_en[a]=={`RobNum{1'b1}}&&jump_front_en[a]=={`RobNum{1'b0}}) begin
                        iq_int_0_inst_o<=rob[a][71:0];
                        iq_int_0_addr_o<=rob_addr[a];
                        rob[`RobNum-4]<=rob[a];
                        rob_addr[`RobNum-4]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        z=z+1;
                end
                else if(rob[a][73:72]==2'b01&&rob[a][2:0]==3'b001&&z<2&&rob_en[a]=={`RobNum{1'b1}}&&jump_front_en[a]=={`RobNum{1'b0}}) begin
                        iq_int_1_inst_o<=rob[a][71:0];
                        iq_int_1_addr_o<=rob_addr[a];
                        rob[`RobNum-2]<=rob[a];
                        rob_addr[`RobNum-2]<=rob_addr[a];
                        rob[a][73:72]<=2'b00;
                        rob[a][71:0]<=`ZeroWord256;
                        z=z+1;
                end
        end
        
        if(x==0)begin
        iq_jump_0_en_o<=`Disable;
        rob[`RobNum-9]<=`ZeroWord256;
        rob_addr[`RobNum-9]<=`ZeroWord256;
        end
        else begin
        iq_jump_0_en_o<=`Enable;
        end
        
        if(y==0)begin
        iq_mem_0_en_o<=`Disable;
        rob[`RobNum-7]<=`ZeroWord256;
        rob_addr[`RobNum-7]<=`ZeroWord256;
        end
        else begin
        iq_mem_0_en_o<=`Enable;
        end
        
        if(z==0)begin
        iq_int_0_en_o<=`Disable;
        rob[`RobNum-4]<=`ZeroWord256;
        rob_addr[`RobNum-4]<=`ZeroWord256;
        iq_int_1_en_o<=`Disable;
        rob[`RobNum-2]<=`ZeroWord256;
        rob_addr[`RobNum-2]<=`ZeroWord256;
        end
        else if(z==1)begin
        iq_int_0_en_o<=`Enable;
        iq_int_1_en_o<=`Disable;
        rob[`RobNum-2]<=`ZeroWord256;
        rob_addr[`RobNum-2]<=`ZeroWord256;
        end
        else begin
        iq_int_0_en_o<=`Enable;
        iq_int_1_en_o<=`Enable;                
        end

end
end


endmodule


