`timescale 1ns / 1ps
`default_nettype none
//comment here
module do_collision_tb();
  logic rst_in;

  logic clk_in;
  
  localparam POSITION_SIZE = 15;
  localparam VELOCITY_SIZE = 10;
  localparam NUM_VERTICES = 4;
  localparam NUM_OBSTACLES = 2;
  localparam DT = 1;
  localparam FORCE_SIZE = 8;


  //obstacles must be oriented clockwise
  //obstacle 1
  assign obstacle[0][0] = -100; //point 1
  assign obstacle[1][0] = -100;        
  assign obstacle[0][1] = 100; //point 2
  assign obstacle[1][1] = -100;  
  assign obstacle[0][2] = 150;  //point 3
  assign obstacle[1][2] = -150;
  assign obstacle[0][3] = -150;  //point 4
  assign obstacle[1][3] = -150;

  logic signed [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES];
  logic [$clog2(NUM_VERTICES):0] num_vertices;
  logic signed [POSITION_SIZE-1:0] pos_x, pos_y, x_new, y_new, x_int, y_int, dx, dy;
  logic signed [VELOCITY_SIZE-1:0] vel_x, vel_y, vx_new, vy_new;
  logic signed [FORCE_SIZE-1:0] force_x, force_y;

  assign num_vertices = 4;
  
  logic begin_update, result_out, was_collision;


do_collision #(DT, POSITION_SIZE,VELOCITY_SIZE, FORCE_SIZE, NUM_VERTICES) collision_doer (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_update),
    .obstacle_in(obstacle),
    .num_vertices(num_vertices),
    .pos_x_in(pos_x),
    .pos_y_in(pos_y),
    .vel_x_in(vel_x),
    .vel_y_in(vel_y),
	.dx_in(dx),
	.dy_in(dy),
    .result_out(result_out),
    .x_new(x_new),
    .y_new(y_new),
	.vel_x_new(vx_new),
	.vel_y_new(vy_new),
	.x_int_out(x_int),
	.y_int_out(y_int),
	.acceleration_x(force_x),
    .acceleration_y(force_y),
	.was_collision(was_collision)
  );




  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end

  //initial block...this is our test simulation
  initial begin
    $dumpfile("do_collision.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,do_collision_tb,collision_doer);//update_point_tb,point_update, point_update.collision_doer, point_update.collision_doer.collision_check, point_update.collision_doer.new_values);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    begin_update = 1;
    pos_x = 40;
    pos_y = -70;
    vel_x = 5;
    vel_y = 5;
    dx = 3;
    dy = 7;
    #10
    begin_update = 0;

    #300
    begin_update = 1;
    pos_x = 40;
    pos_y = -85;
    vel_x = 5;
    vel_y = -5;
    dx = 10;
    dy = -20;
    #10
    begin_update = 0;

    #30000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire