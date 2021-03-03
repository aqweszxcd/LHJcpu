`include "defines.v"

// pc reg module
module pc_if (

    input wire clk,
    input wire rst,

    input wire jump_flag_i,
    input wire [`RegBus] jump_addr_i,
    input wire hold_flag_i,
    input wire [`RegBus] hold_addr_i,

	output reg re_o,
	output reg [`SramAddrBus] pc_o,
	input wire re_i,
	input wire [`DoubleSramBus] inst_i,//从指令L1cache的输入
	input wire [`SramAddrBus] inst_addr_i,
	
	output wire [`SramBusx4] fb_o,//Fetch Buffer x4
	output wire [`SramAddrBusx4] fb_addr_o,//Fetch Buffer x4
	output wire [3:0] fb_en_o,//Fetch Buffer Enable x4
	input wire full_flag_i
);


reg[`HalfSramBus] inst_front;//上次输入的指令的最高16位
reg [1:0] inst_front_type;//上次输入的指令的最高16位的enable

reg[`SramAddrBus] fb[3:0];//Fetch Buffer
reg fb_en[3:0];//Fetch Buffer Enable
reg[`SramBus] fb_addr[3:0];
//inst_i //inst_addr_i

reg[`SramAddrBus] jump_record;//记录本次jump地址
reg[`SramAddrBus] offset;//pc_o的下次输出


assign fb_o={{fb[3]},{fb[2]},{fb[1]},{fb[0]}};//output
assign fb_en_o={{fb_en[3]},{fb_en[2]},{fb_en[1]},{fb_en[0]}};
assign fb_addr_o={{fb_addr[3]},{fb_addr[2]},{fb_addr[1]},{fb_addr[0]}};

wire [15:0] inst [4:0];                                                //input
wire [1:0] inst_type[4:0];//01:16   10:32   00:空
assign inst[0]=inst_front;
assign inst[1]=inst_i[15:0];
assign inst[2]=inst_i[31:16];
assign inst[3]=inst_i[47:32];
assign inst[4]=inst_i[63:48];
assign inst_type[0]=inst_front_type;
assign inst_type[1]=(inst_i[1:0]==2'b11) ? 2'b10:2'b01;
assign inst_type[2]=(inst_i[17:16]==2'b11) ? 2'b10:2'b01;
assign inst_type[3]=(inst_i[33:32]==2'b11) ? 2'b10:2'b01;
assign inst_type[4]=(inst_i[49:48]==2'b11) ? 2'b10:2'b01;



integer i,j,k,n;
always@(posedge clk)begin

if(rst == `Enable || jump_flag_i == `Enable)begin
inst_front<=`ZeroWord;
inst_front_type<=`ZeroWord;

fb[0]<=`ZeroWord;
fb[1]<=`ZeroWord;
fb[2]<=`ZeroWord;
fb[3]<=`ZeroWord;
fb_en[0]<=`ZeroWord;
fb_en[1]<=`ZeroWord;
fb_en[2]<=`ZeroWord;
fb_en[3]<=`ZeroWord;
fb_addr[0]<=`ZeroWord;
fb_addr[1]<=`ZeroWord;
fb_addr[2]<=`ZeroWord;
fb_addr[3]<=`ZeroWord;
end

else if(re_i==`Enable) begin
        for(i=0,j=0,k=0,n=1;i<5;i=i+1)begin//判断指令是否在已jump地址的后面 inst_addr_i+((i-1)*2)>=jump_record
                if(inst_addr_i+((i-1)*2)>=jump_record&&inst_type[i]==2'b01&&k==1'b0) begin//16位指令 不在上条32位指令范围内
                        fb_en[j]<=`Enable;
                        fb_addr[j]<=inst_addr_i+((i-1)*2);
                        fb[j]<={16'h0000,{inst[i]}};
                        j=j+1;
                        k=0;
                end
                else if(inst_addr_i+((i-1)*2)>=jump_record&&inst_type[i]==2'b10&&i<4&&k==1'b0) begin//32位指令 不在上条32位指令范围内
                        fb_en[j]<=`Enable;
                        fb_addr[j]<=inst_addr_i+((i-1)*2);
                        fb[j]<={{inst[i+1]},{inst[i]}};
                        j=j+1;
                        k=1;
                end
                else if(inst_addr_i+((i-1)*2)>=jump_record&&inst_type[i]==2'b10&&i==4&&k==1'b0) begin//最高16位如果是32位指令的前半部分 将这16位存起来
                        inst_front<=inst[i];
                        inst_front_type<=2'b10;
                        n=n-1;
                        k=0;
                end
                else if(k==1'b1) begin//伪16位指令 在上条32位指令范围内//伪32位指令 在上条32位指令范围内//伪最高16位 在上条32位指令范围内
                        k=0;
                end
        end

if(j==0)begin
fb[0]<=`ZeroWord;fb_en[0]<=`Disable;fb_addr[0]<=`ZeroWord;
fb[1]<=`ZeroWord;fb_en[1]<=`Disable;fb_addr[1]<=`ZeroWord;
fb[2]<=`ZeroWord;fb_en[2]<=`Disable;fb_addr[2]<=`ZeroWord;
fb[3]<=`ZeroWord;fb_en[3]<=`Disable;fb_addr[3]<=`ZeroWord;
end
else if(j==1)begin
fb[1]<=`ZeroWord;fb_en[1]<=`Disable;fb_addr[1]<=`ZeroWord;
fb[2]<=`ZeroWord;fb_en[2]<=`Disable;fb_addr[2]<=`ZeroWord;
fb[3]<=`ZeroWord;fb_en[3]<=`Disable;fb_addr[3]<=`ZeroWord;
end
else if(j==2)begin
fb[2]<=`ZeroWord;fb_en[2]<=`Disable;fb_addr[2]<=`ZeroWord;
fb[3]<=`ZeroWord;fb_en[3]<=`Disable;fb_addr[3]<=`ZeroWord;
end
else if(j==3)begin
fb[3]<=`ZeroWord;fb_en[3]<=`Disable;fb_addr[3]<=`ZeroWord;
end

if(n==1)begin
inst_front<=`ZeroWord;
inst_front_type<=2'b00;
end

end

else begin
fb[0]<=`ZeroWord;fb_en[0]<=`Disable;fb_addr[0]<=`ZeroWord;
fb[1]<=`ZeroWord;fb_en[1]<=`Disable;fb_addr[1]<=`ZeroWord;
fb[2]<=`ZeroWord;fb_en[2]<=`Disable;fb_addr[2]<=`ZeroWord;
fb[3]<=`ZeroWord;fb_en[3]<=`Disable;fb_addr[3]<=`ZeroWord;
end


end
    
    
    

    always @ (posedge clk) begin
        if (rst == `Enable) begin
            pc_o <= `ZeroWord;
            offset <= `ZeroWord;
            re_o <= `Disable;
            jump_record<=`ZeroWord;
        end else if (jump_flag_i == `Enable && full_flag_i == `Enable) begin
            pc_o <= `ZeroWord;
            offset <= {{jump_addr_i>>3},{3{1'b0}}};
            re_o <= `Disable;
            jump_record<=jump_addr_i;
        end else if (jump_flag_i == `Enable && full_flag_i == `Disable) begin
            pc_o <= {{jump_addr_i>>3},{3{1'b0}}};
            offset <= {{jump_addr_i>>3},{3{1'b0}}} +8;
            re_o <= `Enable;
            jump_record<=jump_addr_i;
        end else if (jump_flag_i == `Disable && full_flag_i == `Enable) begin
            pc_o <= `ZeroWord;
            offset <= offset;
            re_o <= `Disable;
//        end else if (hold_flag_i == `Enable) begin
//            pc_o <= hold_addr_i;
//            offset <= hold_addr_i;
//            re_o <= `Disable;
        end else begin
            pc_o <= offset;
            offset <= offset + 8;
            re_o <= `Enable;
        end
    end

endmodule





    /*
    reg[`HalfSramBus] inst_front;//上次输入的指令的最高16位
    reg inst_front_en;//上次输入的指令的最高16位的enable
    reg[`SramAddrBus] fb_0,fb_1,fb_2,fb_3;//Fetch Buffer
	reg fb_en_0,fb_en_1,fb_en_2,fb_en_3;//Fetch Buffer Enable
	reg[`SramBus] fb_0_addr_o,fb_1_addr_o,fb_2_addr_o,fb_3_addr_o;
	
	assign fb_o={{fb_3},{fb_2},{fb_1},{fb_0}};
	assign fb_en_o={{fb_en_3},{fb_en_2},{fb_en_1},{fb_en_0}};
	assign fb_addr_o={{fb_3_addr_o},{fb_2_addr_o},{fb_1_addr_o},{fb_0_addr_o}};
    
    always@(posedge clk)begin
    if(rst == `Enable||jump_flag_i == `Enable)begin
            fb_0 <= `ZeroWord;
            fb_1 <= `ZeroWord;
            fb_2 <= `ZeroWord;
            fb_3 <= `ZeroWord;
            fb_en_0 <= `Disable;//Fetch Buffer Disable
            fb_en_1 <= `Disable;
            fb_en_2 <= `Disable;
            fb_en_3 <= `Disable;
            fb_0_addr_o <= `ZeroWord;
            fb_1_addr_o <= `ZeroWord;
            fb_2_addr_o <= `ZeroWord;
            fb_3_addr_o <= `ZeroWord;
            inst_front_en<=`Disable;
            inst_front<=`ZeroWord;
            //inst_addr_front<=`ZeroWord;
    end
    else if(re_i==`Enable)begin// && inst_addr_i!=inst_addr_front
            //inst_addr_front<=inst_addr_i;
            if(inst_front_en)begin 
                    fb_0<={{inst_i[15:0]},{inst_front}}; fb_en_0<=`Enable;
                    fb_0_addr_o <= inst_addr_i - 2;
                    if(inst_i[17:16]!=2'b11)begin
                            fb_1<=inst_i[31:16]; fb_en_1<=`Enable;
                            fb_1_addr_o <= inst_addr_i + 2;
                            if(inst_i[33:32]!=2'b11)begin
                                    fb_2<=inst_i[47:32]; fb_en_2<=`Enable;
                                    fb_2_addr_o <= inst_addr_i + 4;
                                    if(inst_i[49:48]!=2'b11)begin
                                        fb_3<=inst_i[63:48]; fb_en_3<=`Enable;
                                        fb_3_addr_o <= inst_addr_i + 6;
                                        inst_front<=`ZeroWord;inst_front_en<=`Disable;
                                    end
                                    else begin
                                        fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                        fb_3_addr_o <= `ZeroWord;
                                        inst_front<=inst_i[63:48];inst_front_en<=`Enable;
                                    end
                            end
                            else begin
                                fb_2<=inst_i[63:32]; fb_en_2<=`Enable;
                                fb_2_addr_o <= inst_addr_i + 4;
                                fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                fb_3_addr_o <= `ZeroWord;
                                inst_front<=`ZeroWord;inst_front_en<=`Disable;
                            end
                    end
                    else begin
                            fb_1<=inst_i[47:16]; fb_en_1<=`Enable;
                            fb_1_addr_o <= inst_addr_i + 2;
                            if(inst_i[49:48]!=2'b11)begin
                                    fb_2<=inst_i[63:48]; fb_en_2<=`Enable;
                                    fb_2_addr_o <= inst_addr_i + 6;
                                    fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                    fb_3_addr_o <= `ZeroWord;
                                    inst_front<=`ZeroWord;inst_front_en<=`Disable;
                            end
                            else begin
                                    fb_2<=`ZeroWord; fb_en_2<=`Disable;
                                    fb_2_addr_o <= `ZeroWord;
                                    fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                    fb_3_addr_o <= `ZeroWord;
                                    inst_front<=inst_i[63:48];inst_front_en<=`Enable;
                            end
                    end
            end
            else begin
                    if(inst_i[1:0]!=2'b11)begin
                            fb_0<=inst_i[15:0]; fb_en_0<=`Enable;
                            fb_0_addr_o <= inst_addr_i;
                            if(inst_i[17:16]!=2'b11)begin
                                    fb_1<=inst_i[31:16]; fb_en_1<=`Enable;
                                    fb_1_addr_o <= inst_addr_i + 2;
                                    if(inst_i[33:32]!=2'b11)begin
                                            fb_2<=inst_i[47:32]; fb_en_2<=`Enable;
                                            fb_2_addr_o <= inst_addr_i + 4;
                                            if(inst_i[49:48]!=2'b11)begin
                                                    fb_3<=inst_i[63:48]; fb_en_3<=`Enable;
                                                    fb_3_addr_o <= inst_addr_i + 6;
                                                    inst_front<=`ZeroWord;inst_front_en<=`Disable;
                                            end
                                            else begin
                                                    fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                                    fb_3_addr_o <= `ZeroWord;
                                                    inst_front<=inst_i[63:48];inst_front_en<=`Enable;
                                            end
                                    end
                                    else begin
                                            fb_2<=inst_i[63:32]; fb_en_2<=`Enable;
                                            fb_2_addr_o <= inst_addr_i + 4;
                                            fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                            fb_3_addr_o <= `ZeroWord;
                                            inst_front<=`ZeroWord;inst_front_en<=`Disable;
                                    end
                            end
                            else begin
                                    fb_1<=inst_i[47:16]; fb_en_1<=`Enable;
                                    fb_1_addr_o <= inst_addr_i + 2;
                                    if(inst_i[49:48]!=2'b11)begin
                                            fb_2<=inst_i[63:48]; fb_en_2<=`Enable;
                                            fb_2_addr_o <= inst_addr_i + 6;
                                            fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                            fb_3_addr_o <= `ZeroWord;
                                            inst_front<=`ZeroWord;inst_front_en<=`Disable;
                                    end
                                    else begin
                                            fb_2<=`ZeroWord; fb_en_2<=`Disable;
                                            fb_2_addr_o <= `ZeroWord;
                                            fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                            fb_3_addr_o <= `ZeroWord;
                                            inst_front<=inst_i[63:48];inst_front_en<=`Enable;
                                    end
                            end
                    end
                    else begin
                            fb_0<=inst_i[31:0]; fb_en_0<=`Enable;
                            fb_0_addr_o <= inst_addr_i;
                            if(inst_i[33:32]!=2'b11)begin
                                    fb_1<=inst_i[47:32]; fb_en_1<=`Enable;
                                    fb_1_addr_o <= inst_addr_i + 4;
                                    if(inst_i[49:48]!=2'b11)begin
                                            fb_2<=inst_i[63:48]; fb_en_2<=`Enable;
                                            fb_2_addr_o <= inst_addr_i + 6;
                                            fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                            fb_3_addr_o <= `ZeroWord;
                                            inst_front<=`ZeroWord;inst_front_en<=`Disable;
                                    end
                                    else begin
                                            fb_2<=`ZeroWord; fb_en_2<=`Disable;
                                            fb_2_addr_o <= `ZeroWord;
                                            fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                            fb_3_addr_o <= `ZeroWord;
                                            inst_front<=inst_i[63:48];inst_front_en<=`Enable;
                                    end
                            end
                            else begin
                                    fb_1<=inst_i[63:32]; fb_en_1<=`Enable;
                                    fb_1_addr_o <= inst_addr_i + 4;
                                    fb_2<=`ZeroWord; fb_en_2<=`Disable;
                                    fb_2_addr_o <= `ZeroWord;
                                    fb_3<=`ZeroWord; fb_en_3<=`Disable;
                                    fb_3_addr_o <= `ZeroWord;
                                    inst_front<=`ZeroWord;inst_front_en<=`Disable;
                            end
                    end
            end
    end
    else begin
            fb_0 <= `ZeroWord;
            fb_1 <= `ZeroWord;
            fb_2 <= `ZeroWord;
            fb_3 <= `ZeroWord;
            fb_en_0 <= `Disable;//Fetch Buffer Disable
            fb_en_1 <= `Disable;
            fb_en_2 <= `Disable;
            fb_en_3 <= `Disable;
            fb_0_addr_o <= `ZeroWord;
            fb_1_addr_o <= `ZeroWord;
            fb_2_addr_o <= `ZeroWord;
            fb_3_addr_o <= `ZeroWord;
            inst_front_en<=`Disable;
            inst_front<=`ZeroWord;
            //inst_addr_front<=`ZeroWord;
    end
    end
    */
