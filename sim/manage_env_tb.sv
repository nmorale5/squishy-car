`timescale 1ns / 1ps
`default_nettype none

module manage_env_tb;

  //make logics for inputs and outputs!
  logic clk_in;
  logic rst_in;
  logic start_in;

  manage_environment # (
    .WORLD_BITS(32),
    .MAX_NUM_VERTICES(8),
    .MAX_POLYGONS_ON_SCREEN(8)
  ) uut (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .start_in(start_in),
    .positions_out(),
    .done_out()
  );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("manage_env.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,manage_env_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        start_in = 0;
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in = 0;
        #10;
        start_in = 1;
        #10;
        start_in = 0;
        #1000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule

`default_nettype wire

