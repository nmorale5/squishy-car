`timescale 1ns / 1ps
`default_nettype none

module update_point_tb();
  logic rst_in;

  logic clk_in;



  
  parameter POSITION_SIZE = 8;
  parameter VELOCITY_SIZE = 8;
  parameter num_vert = 4;
  parameter num_obst = 1;
  parameter dt = 1;
  logic signed [POSITION_SIZE-1:0] obstacles [1:0][num_vert][num_obst];
  assign obstacles[0][0][0] = -10;
  assign obstacles[1][0][0] = -10;        // Assuming POSITION_SIZE is 8
  assign obstacles[0][1][0] = -10;
  assign obstacles[1][1][0] = 10;
  assign obstacles[0][2][0] = 10;
  assign obstacles[1][2][0] = 10;
  assign obstacles[0][3][0] = 10;
  assign obstacles[1][3][0] = -10;


  logic [POSITION_SIZE-1:0] num_vertices [num_obst];
  assign num_vertices[0] = num_vert;
  logic [POSITION_SIZE-1:0] num_obstacles;
  assign num_obstacles = num_obst;

  logic signed [POSITION_SIZE-1:0] pos_x, pos_y, new_pos_x, new_pos_y;
  logic signed [VELOCITY_SIZE-1:0]vel_x, vel_y, new_vel_x, new_vel_y;
  logic begin_update, result_out;

  update_point #(dt, POSITION_SIZE,VELOCITY_SIZE, 8, num_vert, num_obst) point_update (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_update),
    .obstacles_in(obstacles),
    .all_num_vertices_in({num_vertices[0]}),
    .num_obstacles_in(num_obstacles),
    .pos_x_in(pos_x),
    .pos_y_in(pos_y),
    .vel_x_in(vel_x),
    .vel_y_in(vel_y),
    .new_pos_x(new_pos_x),
    .new_pos_y(new_pos_y),
    .new_vel_x(new_vel_x),
    .new_vel_y(new_vel_y),
    .result_out(result_out)
  );




  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  always begin
    #10
    if (result_out == 1) begin
      pos_x <= new_pos_x;
      pos_y <= new_pos_y;
      vel_x <= new_vel_x;
      vel_y <= new_vel_y;
      begin_update <= 1;
      #10
      begin_update <= 0;
    end
        
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("vsg.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,update_point_tb,point_update, point_update.collision_doer, point_update.collision_doer.collision_check);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    begin_update = 1;
    pos_x = 2;
    pos_y = 3;
    vel_x = -2;
    vel_y = 0;
    #10
    begin_update = 0;

    #30000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire