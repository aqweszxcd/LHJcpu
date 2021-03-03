`include "defines.v"
// excute and writeback module 执行与写回单元 jump模块
module ex_j (
    input wire clk,
    input wire rst,
    // id
    input iq_jump_0_en_i,
    input wire [31:0] iq_jump_0_addr_i,
    input wire [71:0] iq_jump_0_inst_i,
    output reg jump_continue_o,//jump
    // regs cpu核心运行寄存器
    input wire[1023:0] reg_rdata_i,       // reg read data
    output reg[`RegBus] reg_wdata_o,        // reg write data
    output reg reg_we_o,                     // reg write enable
    output reg[`RegAddrBus] reg_waddr_o,     // reg write addr
    // pc_if pc寄存器（对于系统可见）
    output reg hold_flag_o,//hold
    output reg[`RegBus] hold_addr_o,//hold addr
    output reg jump_flag_o,//jump
    output reg[`RegBus] jump_addr_o//jump addr
    
//      下级流水线
//    input iq_jump_0_en_i,
//    input wire [71:0] iq_jump_0_inst_i,
    
);
//DECODE={{inst_valid},{opcode},{funct3},{funct7},{rd},{rs1},{rs2},{reg_we},{reg1_re},{reg2_re},{sram_re},{sram_we},{imm},{inst_type}};
//                   72                71:65        64:62     61:55   54:50       44:40                38             37             36             35               34:3    2:0
//                                                                                              49:45        39
wire [6:0]opcode=iq_jump_0_inst_i[71:65];
wire [2:0]funct3=iq_jump_0_inst_i[64:62];
wire [6:0]funct7=iq_jump_0_inst_i[61:55];
wire [4:0]rd=iq_jump_0_inst_i[54:50];
wire [4:0]rs1=iq_jump_0_inst_i[49:45];
wire [4:0]rs2=iq_jump_0_inst_i[44:40];
wire reg_we=iq_jump_0_inst_i[39];
//wire reg1_re=iq_jump_0_inst_i[38];
//wire reg2_re=iq_jump_0_inst_i[37];
//wire sram_re=iq_jump_0_inst_i[36];
//wire sram_we=iq_jump_0_inst_i[35];
wire [31:0]imm=iq_jump_0_inst_i[34:3];

function[31:0]reg_rdata;
input [4:0] rs;
begin
        case(rs)
                5'd0:reg_rdata=reg_rdata_i[31:0];
                5'd1:reg_rdata=reg_rdata_i[63:32];
                5'd2:reg_rdata=reg_rdata_i[95:64];
                5'd3:reg_rdata=reg_rdata_i[127:96];
                5'd4:reg_rdata=reg_rdata_i[159:128];
                5'd5:reg_rdata=reg_rdata_i[191:160];
                5'd6:reg_rdata=reg_rdata_i[223:192];
                5'd7:reg_rdata=reg_rdata_i[255:224];
                5'd8:reg_rdata=reg_rdata_i[287:256];
                5'd9:reg_rdata=reg_rdata_i[319:288];
                5'd10:reg_rdata=reg_rdata_i[351:320];
                5'd11:reg_rdata=reg_rdata_i[383:352];
                5'd12:reg_rdata=reg_rdata_i[415:384];
                5'd13:reg_rdata=reg_rdata_i[447:416];
                5'd14:reg_rdata=reg_rdata_i[479:448];
                5'd15:reg_rdata=reg_rdata_i[511:480];
                5'd16:reg_rdata=reg_rdata_i[543:512];
                5'd17:reg_rdata=reg_rdata_i[575:544];
                5'd18:reg_rdata=reg_rdata_i[607:576];
                5'd19:reg_rdata=reg_rdata_i[639:608];
                5'd20:reg_rdata=reg_rdata_i[671:640];
                5'd21:reg_rdata=reg_rdata_i[703:672];
                5'd22:reg_rdata=reg_rdata_i[735:704];
                5'd23:reg_rdata=reg_rdata_i[767:736];
                5'd24:reg_rdata=reg_rdata_i[799:768];
                5'd25:reg_rdata=reg_rdata_i[831:800];
                5'd26:reg_rdata=reg_rdata_i[863:832];
                5'd27:reg_rdata=reg_rdata_i[895:864];
                5'd28:reg_rdata=reg_rdata_i[927:896];
                5'd29:reg_rdata=reg_rdata_i[959:928];
                5'd30:reg_rdata=reg_rdata_i[991:960];
                5'd31:reg_rdata=reg_rdata_i[1023:992];
                default:reg_rdata=`ZeroWord;
        endcase
end
endfunction

/*wire[`RegBus]reg1,reg2;
assign reg1=reg_rdata(rs1);
assign reg2=reg_rdata(rs2);*/

reg[`RegBus]reg1,reg2;
always@(negedge clk) begin
reg1=reg_rdata(rs1);
reg2=reg_rdata(rs2);
end


        
always @ (posedge clk) begin
    if (rst == `Enable) begin
    //if (rst == `Enable || hold_flag_o==`Enable || jump_flag_o==`Enable) begin
                reg_we_o<=`Disable;
                reg_waddr_o<=`ZeroWord;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=`Disable;
                jump_flag_o<=`Disable;
                jump_addr_o <=`ZeroWord;
    end
    else if (iq_jump_0_en_i == `Enable) begin
        case({opcode,funct3,funct7})
            {`INST_TYPE_I_J,`INST_JALR_3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=iq_jump_0_addr_i+rs2;
                jump_continue_o<=`Disable;
                jump_flag_o<=`Enable;
                jump_addr_o <=reg1+imm;
            end
            {`INST_TYPE_I_E,`INST_ECALL_3,`INST_ECALL_7}:begin
                reg_we_o<=reg_we;///////////////////////////////////////////////////////////////////////////////////////////////////////nop
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=`Disable;
                jump_flag_o<=`Disable;
                jump_addr_o <=`ZeroWord;
            end
            {`INST_TYPE_I_E,`INST_EBREAK_3,`INST_EBREAK_7}:begin
                reg_we_o<=reg_we;///////////////////////////////////////////////////////////////////////////////////////////////////////nop
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=`Disable;
                jump_flag_o<=`Disable;
                jump_addr_o <=`ZeroWord;
            end
            {`INST_TYPE_I_FENCE,funct3,funct7}:begin
                reg_we_o<=`ZeroWord;
                reg_waddr_o<=`Disable;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=`Disable;
                jump_flag_o<= `Enable;
                jump_addr_o <=iq_jump_0_addr_i+4;
            end
            {`INST_TYPE_B,`INST_BEQ_3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=($signed(reg1)==$signed(reg2))?`Disable:`Enable;
                jump_flag_o<=($signed(reg1)==$signed(reg2))?`Enable:`Disable;
                jump_addr_o <=iq_jump_0_addr_i+imm;
            end
            {`INST_TYPE_B,`INST_BNE_3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=($signed(reg1)!=$signed(reg2))?`Disable:`Enable;
                jump_flag_o<=($signed(reg1)!=$signed(reg2))?`Enable:`Disable;
                jump_addr_o <=iq_jump_0_addr_i+imm;
            end
            {`INST_TYPE_B,`INST_BLT_3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=($signed(reg1)<$signed(reg2))?`Disable:`Enable;
                jump_flag_o<=($signed(reg1)<$signed(reg2))?`Enable:`Disable;
                jump_addr_o <=iq_jump_0_addr_i+imm;
            end
            {`INST_TYPE_B,`INST_BGE_3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=($signed(reg1)>=$signed(reg2))?`Disable:`Enable;
                jump_flag_o<=($signed(reg1)>=$signed(reg2))?`Enable:`Disable;
                jump_addr_o <=iq_jump_0_addr_i+imm;
            end
            {`INST_TYPE_B,`INST_BLTU_3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=($unsigned(reg1)<$unsigned(reg2))?`Disable:`Enable;
                jump_flag_o<=($unsigned(reg1)<$unsigned(reg2))?`Enable:`Disable;
                jump_addr_o <=iq_jump_0_addr_i+imm;
            end
            {`INST_TYPE_B,`INST_BGEU_3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=($unsigned(reg1)>=$unsigned(reg2))?`Disable:`Enable;
                jump_flag_o<=($unsigned(reg1)>=$unsigned(reg2))?`Enable:`Disable;
                jump_addr_o <=iq_jump_0_addr_i+imm;
            end
            {`INST_TYPE_J_JAL,funct3,funct7}:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=iq_jump_0_addr_i+rs2;
                jump_continue_o<=`Disable;
                jump_flag_o<= `Enable;
                jump_addr_o <=iq_jump_0_addr_i+imm;
            end
            default:begin
                reg_we_o<=reg_we;
                reg_waddr_o<=rd;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=`Disable;
                jump_flag_o<=`Disable;
                jump_addr_o <=`ZeroWord;
            end
        endcase
    end
    else begin
                reg_we_o<=`Disable;
                reg_waddr_o<=`ZeroWord;
                hold_flag_o<=`Disable;
                hold_addr_o<=`ZeroWord;
                
                reg_wdata_o<=`ZeroWord;
                jump_continue_o<=`Disable;
                jump_flag_o<=`Disable;
                jump_addr_o <=`ZeroWord;
    end
end


endmodule




/*wire [31:0]reg_0=reg_rdata_i[31:0];
wire [31:0]reg_1=reg_rdata_i[63:32];
wire [31:0]reg_2=reg_rdata_i[95:64];
wire [31:0]reg_3=reg_rdata_i[127:96];
wire [31:0]reg_4=reg_rdata_i[159:128];
wire [31:0]reg_5=reg_rdata_i[191:160];
wire [31:0]reg_6=reg_rdata_i[223:192];
wire [31:0]reg_7=reg_rdata_i[255:224];
wire [31:0]reg_8=reg_rdata_i[287:256];
wire [31:0]reg_9=reg_rdata_i[319:288];
wire [31:0]reg_10=reg_rdata_i[351:320];
wire [31:0]reg_11=reg_rdata_i[383:352];
wire [31:0]reg_12=reg_rdata_i[415:384];
wire [31:0]reg_13=reg_rdata_i[447:416];
wire [31:0]reg_14=reg_rdata_i[479:448];
wire [31:0]reg_15=reg_rdata_i[511:480];
wire [31:0]reg_16=reg_rdata_i[543:512];
wire [31:0]reg_17=reg_rdata_i[575:544];
wire [31:0]reg_18=reg_rdata_i[607:576];
wire [31:0]reg_19=reg_rdata_i[639:608];
wire [31:0]reg_20=reg_rdata_i[671:640];
wire [31:0]reg_21=reg_rdata_i[703:672];
wire [31:0]reg_22=reg_rdata_i[735:704];
wire [31:0]reg_23=reg_rdata_i[767:736];
wire [31:0]reg_24=reg_rdata_i[799:768];
wire [31:0]reg_25=reg_rdata_i[831:800];
wire [31:0]reg_26=reg_rdata_i[863:832];
wire [31:0]reg_27=reg_rdata_i[895:864];
wire [31:0]reg_28=reg_rdata_i[927:896];
wire [31:0]reg_29=reg_rdata_i[959:928];
wire [31:0]reg_30=reg_rdata_i[991:960];
wire [31:0]reg_31=reg_rdata_i[1023:992];*/
