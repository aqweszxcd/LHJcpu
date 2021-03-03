module outside(

);
reg clk;
reg rst;
wire[`SramAddrBus] pc_outside;

reg [`SramAddrBus] pc;

always #10 clk=~clk;    //50MHZ¹¤×÷ÆµÂÊ

initial begin
clk =1'b0;
rst = `Disable;
#100 rst = `Enable;
#100 rst = `Disable;
end

always@(posedge clk) pc<=pc_outside;

openriscv_core openriscv_core_0(
.clk(clk),
.rst(rst),
.pc_outside_i(pc_outside)
);

endmodule

