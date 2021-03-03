//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/28 20:35:25
// Design Name: 
// Module Name: outside
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/100ps

module outside(
output reg clk,
output reg rst,
input wire[`SramAddrBus] pc_outside
);

reg [`SramAddrBus] pc;

always #10 clk=~clk;

initial begin
clk =1'b0;
rst = `RstDisable;
#100 rst = `RstEnable;
#100 rst = `RstDisable;
end

always@(posedge clk) pc<=pc_outside;

endmodule

