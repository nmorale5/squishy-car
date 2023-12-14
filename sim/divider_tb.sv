`timescale 1ns / 1ps
`default_nettype none
//comment here
module divider_tb();
  logic rst_in;

  logic clk_in;
  
  parameter WIDTH = 17;
  parameter OUT_SIZE = 9;

  logic signed [WIDTH-1:0] dividend, divisor;
  logic signed [OUT_SIZE-1:0] quotient;
  logic divider_in_valid, divider_output_valid;
  
  divider #(WIDTH, OUT_SIZE) divider_instance (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .dividend_in(dividend),
    .divisor_in(divisor),
    .data_valid_in(divider_in_valid),
    .quotient_out(quotient),
    .data_valid_out(divider_output_valid)
    //
  );


  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  
  always_ff @(posedge clk_in) begin

  end
    
        

  //initial block...this is our test simulation
  initial begin
    $dumpfile("divider.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,divider_tb, divider_instance);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    divider_in_valid = 1;
    dividend = 300;
    divisor = 15;
    #10
    divider_in_valid = 0;
    #400
    divider_in_valid = 1;
    dividend = -300;
    divisor = 15;
    #10
    divider_in_valid = 0;
    #400
    divider_in_valid = 1;
    dividend = -300;
    divisor = -15;
    #10
    divider_in_valid = 0;
    #400


    #6000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire