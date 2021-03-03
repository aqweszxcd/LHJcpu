
`include "defines.v"
//负责mem读取en和addr的输出
module mem (
    
    //不光立即数需要补位，执行部分中的结果也需要按照reference card的注释进行补位
    //部位分为msb extends（MSB是Most Significant Bit的缩写,指最高有效位）和zero extends，前者补最高有效位，后者补0
    
    input wire clk,
    input wire rst,
    // iq 流水线上级
    input wire iq_mem_en_i,
    input wire [31:0] iq_mem_addr_i,
    input wire [71:0] iq_mem_inst_i,
    // ex_a 流水线下级
    output reg mem_mem_en_o,
    output reg [31:0] mem_mem_addr_o,
    output reg [71:0] mem_mem_inst_o,
    // regs cpu核心运行寄存器
    input wire [1023:0] reg_rdata_i,       // reg read data
    // L1D
//    output wire re_o,                  // read enable
//    output wire [`SramBus] raddr_o      // read addr
    output reg re_o,                  // read enable
    output reg[`SramBus] raddr_o      // read addr
);
    
//DECODE={{inst_valid},{opcode},{funct3},{funct7},{rd},{rs1},{rs2},{reg_we},{reg1_re},{reg2_re},{sram_re},{sram_we},{imm},{inst_type}};
//                   72                71:65        64:62     61:55   54:50       44:40                38             37             36             35               34:3    2:0
//                                                                                              49:45        39
wire [6:0]opcode=iq_mem_inst_i[71:65];
wire [2:0]funct3=iq_mem_inst_i[64:62];
wire [6:0]funct7=iq_mem_inst_i[61:55];
//wire [4:0]rd=iq_mem_inst_i[54:50];
wire [4:0]rs1=iq_mem_inst_i[49:45];
wire [4:0]rs2=iq_mem_inst_i[44:40];
//wire reg_we=iq_mem_inst_i[39];
//wire reg1_re=iq_mem_inst_i[38];
//wire reg2_re=iq_mem_inst_i[37];
//wire sram_re=iq_mem_inst_i[36];
//wire sram_we=iq_mem_inst_i[35];
wire [31:0]imm=iq_mem_inst_i[34:3];


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

//assign re_o=(rst == `Enable || iq_mem_en_i == `Disable)?`Disable:`Enable;
//assign raddr_o=(rst == `Enable || iq_mem_en_i == `Disable)?`ZeroWord:(reg1+imm);

reg wait_mem_en;
reg [31:0] wait_mem_addr;
reg [71:0] wait_mem_inst;

always @ (posedge clk) begin
wait_mem_en<=iq_mem_en_i;
wait_mem_addr<=iq_mem_addr_i;
wait_mem_inst<=iq_mem_inst_i;
mem_mem_en_o<=wait_mem_en;
mem_mem_addr_o<=wait_mem_addr;
mem_mem_inst_o<=wait_mem_inst;
    if (rst == `Enable) begin
                re_o<=`Disable;                  // read enable
                raddr_o<=`ZeroWord;      // read addr
    end
    else if (iq_mem_en_i == `Enable) begin
        case({opcode,funct3,funct7})
            {`INST_TYPE_I_L,`INST_LB_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
            {`INST_TYPE_I_L,`INST_LH_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
            {`INST_TYPE_I_L,`INST_LW_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
            {`INST_TYPE_I_L,`INST_LBU_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
            {`INST_TYPE_I_L,`INST_LHU_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
            {`INST_TYPE_S,`INST_SB_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
            {`INST_TYPE_S,`INST_SH_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
            {`INST_TYPE_S,`INST_SW_3,funct7}:begin
                re_o<=`Enable;                  // read enable
                raddr_o<=reg1+imm;      // read addr
            end
        endcase
    end
    else begin
                re_o<=`Disable;                  // read enable
                raddr_o<=`ZeroWord;      // read addr
    end
end

    
endmodule
