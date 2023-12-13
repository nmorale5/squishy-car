`timescale 1ns / 1ps
`default_nettype none
//comment here
module com_tb();
  logic rst_in;

  logic clk_in;

  logic com_start, com_valid;

  localparam POSITION_SIZE = 8;
  localparam NUM_NODES = 4;

  logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  logic signed [POSITION_SIZE-1:0] com_x_out,
  logic signed [POSITION_SIZE-1:0] com_y_out,

module center_of_mass #(POSITION_SIZE=8, NUM_NODES=4)(
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
 
    output logic valid_out);
  
  center_of_mass #(POSITION_SIZE, N) sqrt_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(com_start),
    .nodes(nodes),
    .com_x_out(com_x),
    .com_y_out(com_y),
    .valid_out(com_valid)
  );


  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  

    
        

  //initial block...this is our test simulation
  initial begin
    $dumpfile("sqrt.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,sqrt_tb, sqrt_instance);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    sqrt_start = 1;
    x = 16;
    #10
    sqrt_start = 0;
    #300
    sqrt_start = 1;
    x = 150;
    #10
    sqrt_start = 0;
    #300
    sqrt_start = 0;
    #300
    sqrt_start = 1;
    x = 47665;
    #10
    sqrt_start = 0;
    #300

    #600

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire