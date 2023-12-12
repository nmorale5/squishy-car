`timescale 1ns / 1ps
`default_nettype none
//divider is taking a long time, can improve with powers.
module springs_tb();
  logic rst_in;
  logic clk_in;
  
  parameter POSITION_SIZE = 8;
  parameter VELOCITY_SIZE = 8;
  parameter FORCE_SIZE = 5;
  parameter num_vert = 8;
  parameter num_obst = 1;
  parameter dt = 1;
  parameter ACCELERATION_SIZE = 8;
  parameter NUM_SPRINGS = 2;
  parameter NUM_NODES = 3;
  parameter CONSTANT_SIZE = 4;





logic begin_calc;
logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES];
logic signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES];
logic [$clog2(NUM_NODES):0] springs [1:0][NUM_SPRINGS];
logic [POSITION_SIZE-1:0] equilibriums [NUM_SPRINGS];
logic [FORCE_SIZE-1:0] force_x_out, force_y_out;
logic [CONSTANT_SIZE-1:0] k,b;
assign k = 2;
assign b = 1;


logic signed [FORCE_SIZE-1:0] spring_forces [1:0][NUM_NODES];
logic springs_done, force_valid;

// Instantiate the springs module
springs #(NUM_SPRINGS, NUM_NODES, CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE) springs_instance (
  .clk_in(clk_in),
  .rst_in(rst_in),
  .input_valid(begin_calc),
  .k(k),
  .b(b),
  .nodes(nodes),
  .velocities(velocities),
  .springs(springs),
  .equilibriums(equilibriums),
  .spring_force_x(force_x_out),
  .spring_force_y(force_y_out),
  .spring_force_valid(force_valid),
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
  //assign springs[0][2] = 2;  //spring 3
  //assign springs[1][2] = 0;

  assign equilibriums[0] = 0;
  assign equilibriums[1] = 0;
  //assign equilibriums[2] = 0;


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
    $dumpfile("springs.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,springs_tb,springs_instance, springs_instance.spring_instance, springs_instance.spring_instance.y_divider);

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
    #3000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire