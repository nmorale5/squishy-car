`timescale 1ns / 1ps
`default_nettype none
//comment here
module collision_new_values_tb();
  logic rst_in;

  logic clk_in;
  
  localparam POSITION_SIZE = 15;
  localparam VELOCITY_SIZE = 10;
  localparam NUM_VERTICES = 4;
  localparam NUM_OBSTACLES = 2;
  localparam DT = 1;
  localparam ACCELERATION_SIZE = 8;


  //obstacles must be oriented clockwise
  //obstacle 1
  assign obstacle[0][0] = -100; //point 1
  assign obstacle[1][0] = -100;        
  assign obstacle[0][1] = 100; //point 2
  assign obstacle[1][1] = -100;  
  assign obstacle[0][2] = 100;  //point 3
  assign obstacle[1][2] = 100;
  assign obstacle[0][3] = -100;  //point 4
  assign obstacle[1][3] = 100;

  logic signed [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES];
  logic [$clog2(NUM_VERTICES):0] num_vertices;
  logic signed [POSITION_SIZE-1:0] pos_x, pos_y, x_new, y_new, x_int, y_int, dx, dy;
  logic signed [VELOCITY_SIZE-1:0] vel_x, vel_y, vx_new, vy_new;
  logic signed [ACCELERATION_SIZE-1:0] force_x, force_y;

  assign num_vertices = 4;
  
  logic begin_update, result_out, collision;

  logic signed [POSITION_SIZE-1:0] v1 [1:0];
  logic signed [POSITION_SIZE-1:0] v2 [1:0];

collision_new_values #(POSITION_SIZE, VELOCITY_SIZE, ACCELERATION_SIZE, DT) new_values (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .input_valid(begin_update),
    .v1_in(v1),
    .v2_in(v2),
    .pos_x(pos_x),
    .pos_y(pos_y),
    .vel_x(vel_x),
    .vel_y(vel_y),
    .dx(dx),
    .dy(dy),
    .x_new_out(x_new),
    .y_new_out(y_new),
    .vx_new_out(vx_new),
    .vy_new_out(vy_new),
    .x_int_out(x_int),
    .y_int_out(y_int),
    .acceleration_x_out(force_x),
    .acceleration_y_out(force_y),
	.collision(collision),
    .output_valid(result_out)
  );




  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end



  //initial block...this is our test simulation
  initial begin
    $dumpfile("collision_new_values.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,collision_new_values_tb,new_values);//update_point_tb,point_update, point_update.collision_doer, point_update.collision_doer.collision_check, point_update.collision_doer.new_values);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    begin_update = 1;
    v1[0] = -100;
    v1[1] = -100;
    v2[0] = 100;
    v2[1] = -100;
    pos_x = 40;
    pos_y = -70;
    vel_x = 5;
    vel_y = 5;
    dx = 3;
    dy = 7;
    #10
    begin_update = 0;

    #100
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