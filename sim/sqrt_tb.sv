`timescale 1ns / 1ps
`default_nettype none
//comment here
module sqrt_tb();
  logic rst_in;

  logic clk_in;
  
  localparam WIDTH = 19;
  logic [WIDTH-1:0] x;
  logic [WIDTH-1:0] sqrt;
  logic sqrt_start, sqrt_valid;


  
  sqrt #(WIDTH) sqrt_instance (
    .clk_in(clk_in),
    .x(x),
    .valid_in(sqrt_start),
    .sqrt_x(sqrt),
    .result_valid(sqrt_valid)
  );


  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  
  always_ff @(posedge clk_in) begin

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