`timescale 1ns / 1ps
`default_nettype none
//all works!
module ideal_springs_tb();
  logic rst_in;
  logic clk_in;
  
  parameter POSITION_SIZE = 8;
  parameter VELOCITY_SIZE = 8;
  parameter FORCE_SIZE = 7;
  parameter num_vert = 8;
  parameter num_obst = 1;
  parameter dt = 1;
  parameter ACCELERATION_SIZE = 8;
  parameter NUM_SPRINGS = 2;
  parameter NUM_NODES = 3;
  parameter CONSTANT_SIZE = 5;





logic begin_calc;
logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES];
logic signed [POSITION_SIZE-1:0] ideal_nodes [1:0][NUM_NODES];
logic signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES];
logic signed [VELOCITY_SIZE-1:0] axle_velocity [1:0];
logic signed [FORCE_SIZE-1:0] axle_force_x, axle_force_y;
logic signed [FORCE_SIZE-1:0] force_x_out, force_y_out;
logic signed [CONSTANT_SIZE-1:0] k,b;
assign k = 1;
assign b = 0;



logic ideal_springs_done, force_valid;

// Instantiate the springs module
ideal_springs #(NUM_NODES, CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE) ideal_springs_instance (
  .clk_in(clk_in),
  .rst_in(rst_in),
  .input_valid(begin_calc),
  .k(k),
  .b(b),
  .nodes(nodes),
  .ideal_nodes(ideal_nodes),
  .velocities(velocities),
  .axle_velocity(axle_velocity),
  .force_x_out(force_x_out),
  .force_y_out(force_y_out),
  .force_out_valid(force_valid),
  .axle_force_x(axle_force_x),
  .axle_force_y(axle_force_y),
  .output_valid(ideal_springs_done)
);



  assign velocities[0][0] = 1; //point 1
  assign velocities[1][0] = 2;        
  assign velocities[0][1] = -2; //point 2
  assign velocities[1][1] = -3;  
  assign velocities[0][2] = 5;  //point 3
  assign velocities[1][2] = 8;

  assign ideal_nodes[0][0] = 3; //point 1
  assign ideal_nodes[1][0] = 4;        
  assign ideal_nodes[0][1] = 6; //point 2
  assign ideal_nodes[1][1] = 8;  
  assign ideal_nodes[0][2] = 12;  //point 3
  assign ideal_nodes[1][2] = -2;


  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  always begin
    #10;
    /*
    if (result_out == 1) begin
      pos_x <= new_pos_x;
      pos_y <= new_pos_y;
      vel_x <= new_vel_x;
      vel_y <= new_vel_y;
      begin_update <= 1;
      #10
      begin_update <= 0;
    end */
        
  end

always_ff @(posedge clk_in) begin


end

  //initial block...this is our test simulation
  initial begin
    $dumpfile("ideal_springs.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,ideal_springs_tb, ideal_springs_tb.ideal_springs_instance);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10
    begin_calc = 1;
    nodes[0][0] = 3; //point 1
    nodes[1][0] = 4;        
    nodes[0][1] = 6; //point 2
    nodes[1][1] = 8;  
    nodes[0][2] = 12;  //point 3
    nodes[1][2] = -2;
    #10
    begin_calc = 0;
    #3000
    begin_calc = 1;
    nodes[0][0] = 3; //point 1
    nodes[1][0] = 5;        
    nodes[0][1] = 6; //point 2
    nodes[1][1] = 9;  
    nodes[0][2] = 12;  //point 3
    nodes[1][2] = -1;
    #10
    begin_calc = 0;
    #3000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire