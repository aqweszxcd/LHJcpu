`timescale 1ns/100ps
`include "defines.v"

module outside(
output reg re_p1_i,//read
output reg [`ADDR_LENTH-1:0] raddr_p1_i,
input wire [`LINE_SIZE-1:0] rdata_p1_o,
input wire read_hit_p1_o,
output reg re_p2_i,//read
output reg [`ADDR_LENTH-1:0] raddr_p2_i,
input wire [`LINE_SIZE-1:0] rdata_p2_o,
input wire read_hit_p2_o,
output reg we_p1_i,//write
output reg [`ADDR_LENTH-1:0] waddr_p1_i,
output reg [`LINE_SIZE-1:0] wdata_p1_i,
input wire write_hit_p1_o,

input wire clk,
output reg clk_4,
output reg clk_16,
output reg rst
);

always #40 clk_4=~clk_4;
always #160 clk_16=~clk_16;



endmodule

