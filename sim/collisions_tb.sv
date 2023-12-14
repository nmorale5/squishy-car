`timescale 1ns / 1ps
`default_nettype none
//comment here
module collisions_tb();
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
  assign obstacles[0][0][0] = -100; //point 1
  assign obstacles[1][0][0] = -100;        
  assign obstacles[0][1][0] = 100; //point 2
  assign obstacles[1][1][0] = -100;  
  assign obstacles[0][2][0] = 150;  //point 3
  assign obstacles[1][2][0] = -150;
  assign obstacles[0][3][0] = -150;  //point 4
  assign obstacles[1][3][0] = -150;

  assign obstacles[0][0][1] = -200; //point 1
  assign obstacles[1][0][1] = -100;        
  assign obstacles[0][1][1] = -150; //point 2
  assign obstacles[1][1][1] = -150;  
  assign obstacles[0][2][1] = -200;  //point 3
  assign obstacles[1][2][1] = -150;


  logic signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES];
  logic [$clog2(NUM_OBSTACLES):0] num_obstacles;
  logic signed [POSITION_SIZE-1:0] pos_x, pos_y, new_pos_x, new_pos_y;
  logic signed [VELOCITY_SIZE-1:0] vel_x, vel_y, new_vel_x, new_vel_y;
  logic signed [FORCE_SIZE-1:0] force_x, force_y;

  assign all_num_vertices[0] = 4;
  assign all_num_vertices[1] = 3;
  assign num_obstacles = 2;
  
  logic begin_update, result_out;


  collisions #(DT, POSITION_SIZE,VELOCITY_SIZE, FORCE_SIZE, NUM_VERTICES, NUM_OBSTACLES) collider (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_update),
    .obstacles_in(obstacles),
    .all_num_vertices_in(all_num_vertices),
    .num_obstacles_in(num_obstacles),
    .pos_x_in(pos_x),
    .pos_y_in(pos_y),
    .vel_x_in(vel_x),
    .vel_y_in(vel_y),
    .new_pos_x(new_pos_x),
    .new_pos_y(new_pos_y),
    .new_vel_x(new_vel_x),
    .new_vel_y(new_vel_y),
    .force_x_out(force_x),
    .force_y_out(force_y),
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
      //vel_x <= new_vel_x + acceleration_x * DT;
      //new_vel_y <= new_vel_y + acceleration_y * DT;
      begin_update <= 1;
      #10
      begin_update <= 0;
    end
        
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("collisions.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,collisions_tb,collider, collider.collision_doer);//update_point_tb,point_update, point_update.collision_doer, point_update.collision_doer.collision_check, point_update.collision_doer.new_values);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    begin_update = 1;
    pos_x = -4;
    pos_y = -7;
    vel_x = 5;
    vel_y = -6;
    #10
    begin_update = 0;

    #60000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire