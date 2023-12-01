`timescale 1ns / 1ps
`default_nettype none
//comment here
module springs_tb();
  logic rst_in;
  logic clk_in;
  
  parameter POSITION_SIZE = 8;
  parameter VELOCITY_SIZE = 8;
  parameter num_vert = 8;
  parameter num_obst = 1;
  parameter dt = 1;
  parameter ACCELERATION_SIZE = 8;
  parameter NUM_SPRINGS = 3;
  parameter NUM_NODES = 3;
  parameter FORCE_SIZE = 8;





logic begin_calc;
logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES];
logic signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES];
logic [$clog2(NUM_NODES)-1:0] springs [1:0][NUM_SPRINGS];
logic signed [FORCE_SIZE-1:0] spring_forces [1:0][NUM_NODES];
logic springs_done;

// Instantiate the springs module
springs #(NUM_SPRINGS, NUM_NODES, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE) springs_instance (
  .clk_in(clk_in),
  .rst_in(rst_in),
  .input_valid(begin_calc),
  .nodes(nodes),
  .velocities(velocities),
  .springs(springs),
  .spring_forces(spring_forces),
  .output_valid(springs_done)
);

  assign nodes[0][0] = 3; //point 1
  assign nodes[1][0] = 4;        
  assign nodes[0][1] = 6; //point 2
  assign nodes[1][1] = 8;  
  assign nodes[0][2] = 12;  //point 3
  assign nodes[1][2] = -2;

  assign velocities[0][0] = 1; //point 1
  assign velocities[1][0] = 2;        
  assign velocities[0][1] = -2; //point 2
  assign velocities[1][1] = -3;  
  assign velocities[0][2] = 5;  //point 3
  assign velocities[1][2] = 8;

  assign springs[0][0] = 0; //spring 1
  assign springs[1][0] = 1;        
  assign springs[0][1] = 1; //spring 2
  assign springs[1][1] = 2;  
  assign springs[0][2] = 2;  //spring 3
  assign springs[1][2] = 0;


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
  //initial block...this is our test simulation
  initial begin
    $dumpfile("vsg.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,springs_tb,springs_instance, springs_instance.spring_instance);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #10
    begin_calc = 1;
    #10
    begin_calc = 0;
    #30000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire