`include "defines.v"
// excute and writeback module 执行与写回单元 ex_i负责RV32I部分的不涉及jump以及mem的部分
module ex_i (
    
    //不光立即数需要补位，执行部分中的结果也需要按照reference card的注释进行补位
    //部位分为msb extends（MSB是Most Significant Bit的缩写,指最高有效位）和zero extends，前者补最高有效位，后者补0
    
    input wire clk,
    input wire rst,
    // id
    input iq_int_en_i,
    input wire [31:0] iq_int_addr_i,
    input wire [71:0] iq_int_inst_i,
    // regs cpu核心运行寄存器
    input wire[1023:0] reg_rdata_i,       // reg read data
    output reg[`RegBus] reg_wdata_o,        // reg write data
    output reg reg_we_o,                     // reg write enable
    output reg[`RegAddrBus] reg_waddr_o     // reg write addr
    
//      下级流水线
//    input iq_jump_0_en_i,
//    input wire [71:0] iq_jump_0_inst_i,

);

//DECODE={{inst_valid},{opcode},{funct3},{funct7},{rd},{rs1},{rs2},{reg_we},{reg1_re},{reg2_re},{sram_re},{sram_we},{imm},{inst_type}};
//                   72                71:65        64:62     61:55   54:50       44:40                38             37             36             35               34:3    2:0
//                                                                                              49:45        39
wire [6:0]opcode=iq_int_inst_i[71:65];
wire [2:0]funct3=iq_int_inst_i[64:62];
wire [6:0]funct7=iq_int_inst_i[61:55];
wire [4:0]rd=iq_int_inst_i[54:50];
wire [4:0]rs1=iq_int_inst_i[49:45];
wire [4:0]rs2=iq_int_inst_i[44:40];
wire reg_we=iq_int_inst_i[39];
//wire reg1_re=iq_int_inst_i[38];
//wire reg2_re=iq_int_inst_i[37];
//wire sram_re=iq_int_inst_i[36];
//wire sram_we=iq_int_inst_i[35];
wire [31:0]imm=iq_int_inst_i[34:3];


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
always@(negedge clk) begin//negedge clk
reg1=reg_rdata(rs1);
reg2=reg_rdata(rs2);
end


//wire [`DoubleRegBus] mul_result = $signed(reg1_rdata_i) * $signed(reg2_rdata_i);
function[`DoubleRegBus] mul_result;
input [`RegBus] reg1_rdata,reg2_rdata;
begin
mul_result = $signed(reg1_rdata) * $signed(reg2_rdata);
end
endfunction

//wire [`RegBus] op1_mul = (reg1_rdata_i[31] == 1'b1)? (~reg1_rdata_i + 1): reg1_rdata_i;
//wire [`DoubleRegBus] mulsu_result = (reg1_rdata_i[31] == 1'b1) ? ((~(op1_mul * reg2_rdata_i))+1) : (op1_mul * reg2_rdata_i);
function[`DoubleRegBus] mulsu_result;
input [`RegBus] reg1_rdata,reg2_rdata;
reg [`RegBus] op1_mul;
begin
op1_mul = (reg1_rdata[31] == 1'b1)? (~reg1_rdata + 1): reg1_rdata;
mulsu_result = (reg1_rdata[31] == 1'b1) ? ((~(op1_mul * reg2_rdata))+1) : (op1_mul * reg2_rdata);
end
endfunction

//wire [`DoubleRegBus] mulu_result = $unsigned(reg1_rdata_i) * $unsigned(reg2_rdata_i);
function[`DoubleRegBus] mulu_result;
input [`RegBus] reg1_rdata,reg2_rdata;
begin
mulu_result = $unsigned(reg1_rdata) * $unsigned(reg2_rdata);
end
endfunction

//wire [`RegBus] div_result = $signed(reg1_rdata_i) / $signed(reg2_rdata_i);
function[`RegBus] div_result;
input [`RegBus] reg1_rdata,reg2_rdata;
begin
div_result = $signed(reg1_rdata) / $signed(reg2_rdata);
//(reg2==`ZeroWord)?(`ZeroWord):($signed(reg1_rdata) / $signed(reg2_rdata));
//$signed(reg1_rdata) / $signed(reg2_rdata);
end
endfunction

//wire [`RegBus] divu_result = $unsigned(reg1_rdata_i) / $unsigned(reg2_rdata_i);
function[`RegBus] divu_result;
input [`RegBus] reg1_rdata,reg2_rdata;
begin
divu_result = $unsigned(reg1_rdata) / $unsigned(reg2_rdata);
//
//$unsigned(reg1_rdata) / $unsigned(reg2_rdata);
end
endfunction

//wire [`RegBus] rem_result = $signed(reg1_rdata_i) % $signed(reg2_rdata_i);
function[`RegBus] rem_result;
input [`RegBus] reg1_rdata,reg2_rdata;
begin
rem_result = $signed(reg1_rdata) % $signed(reg2_rdata);//(reg2==`ZeroWord)?(`ZeroWord):($signed(reg1_rdata) % $signed(reg2_rdata));
end
endfunction

//wire [`RegBus] remu_result = $unsigned(reg1_rdata_i) % $unsigned(reg2_rdata_i);
function[`RegBus] remu_result;
input [`RegBus] reg1_rdata,reg2_rdata;
begin
remu_result = $unsigned(reg1_rdata) % $unsigned(reg2_rdata);
end
endfunction

wire[`DoubleRegBus] mul;
wire[`DoubleRegBus] mulsu;
wire[`DoubleRegBus] mulu;
wire[`RegBus] div;
wire[`RegBus] divu;
wire[`RegBus] rem;
wire[`RegBus] remu;

/*
wire [`DoubleRegBus] mul = $signed(reg1) * $signed(reg2);
wire [`RegBus] op1_mul = (reg1[31] == 1'b1)? (~reg1 + 1): reg1;
wire [`DoubleRegBus] mulsu = (reg1[31] == 1'b1) ? ((~(op1_mul * reg2))+1) : (op1_mul * reg2);
wire [`DoubleRegBus] mulu = $unsigned(reg1) * $unsigned(reg2);

assign div = reg2==`ZeroWord? `ZeroWord:(($signed(reg1) / $signed(reg2));
wire [`RegBus] divu = $unsigned(reg1) / $unsigned(reg2);
wire [`RegBus] rem= $signed(reg1) % $signed(reg2);
wire [`RegBus] remu = $unsigned(reg1) % $unsigned(reg2);*/


assign mul=mul_result(reg1,reg2);
assign mulsu=mulsu_result(reg1,reg2);
assign mulu=mulu_result(reg1,reg2);
//assign div=div_result(reg1,reg2);
//assign div=(reg2==`ZeroWord)?`OneWord32:div_result(reg1,reg2);
//assign divu=divu_result(reg1,reg2);
//assign divu=(reg2==`ZeroWord)?`OneWord32:($signed(reg2)<`ZeroWord)?`ZeroWord:divu_result(reg1,reg2);
//assign rem=rem_result(reg1,reg2);
//assign remu=remu_result(reg1,reg2);



        
always @ (posedge clk) begin
    if (rst == `Enable) begin
                reg_we_o<=`Disable;                     // reg write enable
                reg_waddr_o<=`ZeroWord;     // reg write addr
                reg_wdata_o<=`ZeroWord;        // reg write data
    end
    else if (iq_int_en_i == `Enable) begin
        case({opcode,funct3,funct7})
            {`INST_TYPE_R,`INST_ADD_3,`INST_ADD_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 + reg2;        // reg write data
            end
            {`INST_TYPE_R,`INST_SUB_3,`INST_SUB_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 - reg2;        // reg write data
            end
            {`INST_TYPE_R,`INST_XOR_3,`INST_XOR_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 ^ reg2;        // reg write data
            end
            {`INST_TYPE_R,`INST_OR_3,`INST_OR_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 | reg2;        // reg write data
            end
            {`INST_TYPE_R,`INST_AND_3,`INST_AND_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 & reg2;        // reg write data
            end
            {`INST_TYPE_R,`INST_SLL_3,`INST_SLL_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o<=reg1 << reg2[4:0];        // reg write data
            end
            {`INST_TYPE_R,`INST_SRL_3,`INST_SRL_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o<=reg1 >> reg2[4:0];        // reg write data
            end
            {`INST_TYPE_R,`INST_SRA_3,`INST_SRA_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= {{32{reg1[31]}},reg1} >> $signed(reg2[4:0]);        // reg write data
            end
            {`INST_TYPE_R,`INST_SLT_3,`INST_SLT_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= {{31{1'b0}},{($signed(reg1) < $signed(reg2)) ? 1:0}};        // reg write data
            end
            {`INST_TYPE_R,`INST_SLTU_3,`INST_SLTU_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= {{31{1'b0}},{($unsigned(reg1) < $unsigned(reg2)) ? 1:0}};        // reg write data
            end
            {`INST_TYPE_R,`INST_MUL_3,`INST_MUL_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= mul[31:0];        // reg write data
            end
            {`INST_TYPE_R,`INST_MULH_3,`INST_MULH_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= mul[63:32];        // reg write data
            end
            {`INST_TYPE_R,`INST_MULSU_3,`INST_MULSU_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= mulsu[63:32];        // reg write data
            end
            {`INST_TYPE_R,`INST_MULU_3,`INST_MULU_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= mulu[63:32];        // reg write data
            end
            {`INST_TYPE_R,`INST_DIV_3,`INST_DIV_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= (reg2==`ZeroWord)?`OneWord32:div_result(reg1,reg2);        // reg write data
            end
            {`INST_TYPE_R,`INST_DIVU_3,`INST_DIVU_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= (reg2==`ZeroWord)?`OneWord32:divu_result(reg1,reg2);        // reg write data
            end
            {`INST_TYPE_R,`INST_REM_3,`INST_REM_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= (reg2==`ZeroWord)?reg1:rem_result(reg1,reg2);        // reg write data
            end
            {`INST_TYPE_R,`INST_REMU_3,`INST_REMU_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= (reg2==`ZeroWord)?reg1:remu_result(reg1,reg2);        // reg write data
            end
            {`INST_TYPE_I,`INST_ADDI_3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 + imm;        // reg write data
            end
            {`INST_TYPE_I,`INST_XORI_3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 ^ imm;        // reg write data
            end
            {`INST_TYPE_I,`INST_ORI_3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 | imm;        // reg write data
            end
            {`INST_TYPE_I,`INST_ANDI_3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 & imm;        // reg write data
            end
            {`INST_TYPE_I,`INST_SLLI_3,`INST_SLLI_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 << imm[4:0];        // reg write data
            end
            {`INST_TYPE_I,`INST_SRLI_3,`INST_SRLI_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr
                
                reg_wdata_o<=reg1 >> imm[4:0];        // reg write data
            end
            {`INST_TYPE_I,`INST_SRAI_3,`INST_SRAI_7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= {{32{reg1[31]}},reg1} >> $signed(imm[4:0]);        // reg write data
            end
            {`INST_TYPE_I,`INST_SLTI_3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= {{31{1'b0}},{($signed(reg1) < $signed(imm)) ? 1:0}};        // reg write data
            end
            {`INST_TYPE_I,`INST_SLTIU_3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= {{31{1'b0}},{($unsigned(reg1) < $unsigned(imm)) ? 1:0}};        // reg write data
            end
            {`INST_TYPE_U_LUI,funct3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= imm;        // reg write data
            end
            {`INST_TYPE_U_AUIPC,funct3,funct7}:begin
                reg_we_o<=`Enable;                     // reg write enable
                reg_waddr_o<=rd;     // reg write addr

                reg_wdata_o <= imm+iq_int_addr_i;        // reg write data
            end
            default:begin
                reg_we_o<=`Disable;                     // reg write enable
                reg_waddr_o<=`ZeroWord;     // reg write addr
                reg_wdata_o<=`ZeroWord;        // reg write data
            end
        endcase
    end
    else begin
                reg_we_o<=`Disable;                     // reg write enable
                reg_waddr_o<=`ZeroWord;     // reg write addr
                reg_wdata_o<=`ZeroWord;        // reg write data
    end
end


endmodule
