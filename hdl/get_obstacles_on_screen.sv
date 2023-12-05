`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module get_obstacles_on_screen # (
  parameter WORLD_BITS = 32,
  parameter MAX_NUM_VERTICES = 8,
  parameter MAX_OBSTACLES_ON_SCREEN = 16
) (
  input wire clk_in,
  input wire rst_in,
  input wire next_in,
  input wire done_in,
  output logic signed [WORLD_BITS-1:0] obstacles_out [MAX_OBSTACLES_ON_SCREEN] [MAX_NUM_VERTICES],
  output logic [$clog2(MAX_NUM_VERTICES+1)-1:0] obstacles_num_sides_out [MAX_OBSTACLES_ON_SCREEN],
  output logic [$clog2(MAX_OBSTACLES_ON_SCREEN+1)-1:0] num_obstacles_out,
);



endmodule

`default_nettype wire