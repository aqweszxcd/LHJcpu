
`include "defines.v"
// excute and writeback module 执行与写回单元
module ex_a (
    
    //不光立即数需要补位，执行部分中的结果也需要按照reference card的注释进行补位
    //部位分为msb extends（MSB是Most Significant Bit的缩写,指最高有效位）和zero extends，前者补最高有效位，后者补0
    
    input wire clk,
    input wire rst,
    // mem 流水线上级
    input wire mem_mem_en_i,
    input wire [31:0] mem_mem_addr_i,
    input wire [71:0] mem_mem_inst_i,
    // regs cpu核心运行寄存器
    input wire[1023:0] reg_rdata_i,       // reg read data
    output reg reg_we_o,                     // reg write enable
    output reg[`RegAddrBus] reg_waddr_o,     // reg write addr
    output reg[`RegBus] reg_wdata_o,        // reg write data
    // L1D
    input wire re_i,                  // read enable
    input wire[`SramBus] rdata_i,      // read data
    output reg we_o,                     // write enable
    output reg[`SramAddrBus] waddr_o,    // write addr
    output reg[`SramBus] wdata_o        // write data
);

//DECODE={{inst_valid},{opcode},{funct3},{funct7},{rd},{rs1},{rs2},{reg_we},{reg1_re},{reg2_re},{sram_re},{sram_we},{imm},{inst_type}};
//                   72                71:65        64:62     61:55   54:50       44:40                38             37             36             35               34:3    2:0
//                                                                                              49:45        39
wire [6:0]opcode=mem_mem_inst_i[71:65];
wire [2:0]funct3=mem_mem_inst_i[64:62];
wire [6:0]funct7=mem_mem_inst_i[61:55];
wire [4:0]rd=mem_mem_inst_i[54:50];
wire [4:0]rs1=mem_mem_inst_i[49:45];
wire [4:0]rs2=mem_mem_inst_i[44:40];
wire reg_we=mem_mem_inst_i[39];
//wire reg1_re=mem_mem_inst_i[38];
//wire reg2_re=mem_mem_inst_i[37];
//wire sram_re=mem_mem_inst_i[36];
//wire sram_we=mem_mem_inst_i[35];
wire [31:0]imm=mem_mem_inst_i[34:3];

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

wire [`SramAddrBus]raddr;
assign raddr=reg1+imm;

        
always @ (posedge clk) begin
if (rst == `Enable) begin
                // regs
                reg_we_o<=`Disable;                     // reg write enable
                reg_waddr_o<=`ZeroWord;    // reg write addr
                reg_wdata_o<=`ZeroWord;        // reg write data
                // L1D
                we_o<=`Disable;                     // write enable
                waddr_o<=`ZeroWord;    // write addr
                wdata_o<=`ZeroWord;        // write data
end
else if (mem_mem_en_i == `Enable) begin
        //if((we_o==`Enable)&&(waddr_o[31:2]==raddr[31:2]))begin
        case({opcode,funct3,funct7})
                {`INST_TYPE_I_L,`INST_LB_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[7]}},{rdata_i[7:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[15]}},{rdata_i[15:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[23]}},{rdata_i[23:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b11)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[31]}},{rdata_i[31:24]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_I_L,`INST_LH_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{rdata_i[15]}},{rdata_i[15:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{rdata_i[23]}},{rdata_i[23:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{rdata_i[31]}},{rdata_i[31:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_I_L,`INST_LW_3,funct7}:begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<=rdata_i[31:0];        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
            end
            {`INST_TYPE_I_L,`INST_LBU_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[7:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[15:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[23:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b11)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[31:24]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_I_L,`INST_LHU_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{1'b0}},{rdata_i[15:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{1'b0}},{rdata_i[23:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{1'b0}},{rdata_i[31:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_S,`INST_SB_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:8]},{reg2[7:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:16]},{reg2[7:0]},{rdata_i[7:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:24]},{reg2[7:0]},{rdata_i[15:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b11)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{reg2[7:0]},{rdata_i[23:0]}};        // write data
                        end
            end
            {`INST_TYPE_S,`INST_SH_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:16]},{reg2[15:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:24]},{reg2[15:0]},{rdata_i[7:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{reg2[15:0]},{rdata_i[15:0]}};        // write data
                        end
            end
            {`INST_TYPE_S,`INST_SW_3,funct7}:begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<=reg2[31:0];        // write data
            end
        endcase
end
/*        else begin
        case({opcode,funct3,funct7})
                {`INST_TYPE_I_L,`INST_LB_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[7]}},{rdata_i[7:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[15]}},{rdata_i[15:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[23]}},{rdata_i[23:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b11)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{rdata_i[31]}},{rdata_i[31:24]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_I_L,`INST_LH_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{rdata_i[15]}},{rdata_i[15:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{rdata_i[23]}},{rdata_i[23:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{rdata_i[31]}},{rdata_i[31:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_I_L,`INST_LW_3,funct7}:begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<=rdata_i[31:0];        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
            end
            {`INST_TYPE_I_L,`INST_LBU_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[7:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[15:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[23:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b11)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{24{1'b0}},{rdata_i[31:24]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_I_L,`INST_LHU_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{1'b0}},{rdata_i[15:0]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{1'b0}},{rdata_i[23:8]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Enable;                     // reg write enable
                                reg_waddr_o<=rd;    // reg write addr
                                reg_wdata_o<={{16{1'b0}},{rdata_i[31:16]}};        // reg write data
                                // L1D
                                we_o<=`Disable;                     // write enable
                                waddr_o<=`ZeroWord;    // write addr
                                wdata_o<=`ZeroWord;        // write data
                        end
            end
            {`INST_TYPE_S,`INST_SB_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:8]},{reg2[7:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:16]},{reg2[7:0]},{rdata_i[7:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:24]},{reg2[7:0]},{rdata_i[15:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b11)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{reg2[7:0]},{rdata_i[23:0]}};        // write data
                        end
            end
            {`INST_TYPE_S,`INST_SH_3,funct7}:begin
                        if(raddr[1:0]==2'b00)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:8]},{reg2[15:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b01)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{rdata_i[31:24]},{reg2[15:0]},{rdata_i[7:0]}};        // write data
                        end
                        else if(raddr[1:0]==2'b10)begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<={{reg2[15:0]},{rdata_i[15:0]}};        // write data
                        end
            end
            {`INST_TYPE_S,`INST_SW_3,funct7}:begin
                                // regs
                                reg_we_o<=`Disable;                     // reg write enable
                                reg_waddr_o<=`ZeroWord;    // reg write addr
                                reg_wdata_o<=`ZeroWord;        // reg write data
                                // L1D
                                we_o<=`Enable;                     // write enable
                                waddr_o<=reg1+imm;    // write addr
                                wdata_o<=reg2[31:0];        // write data
            end
        endcase
        end
end*/
else begin
                // regs
                reg_we_o<=`Disable;                     // reg write enable
                reg_waddr_o<=`ZeroWord;    // reg write addr
                reg_wdata_o<=`ZeroWord;        // reg write data
                // L1D
                we_o<=`Disable;                     // write enable
                waddr_o<=`ZeroWord;    // write addr
                wdata_o<=`ZeroWord;        // write data
end
end


endmodule
