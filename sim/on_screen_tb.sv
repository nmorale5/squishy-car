`timescale 1ns / 1ps
`default_nettype none

module on_screen_tb;

  //make logics for inputs and outputs!
  logic clk_in;
  logic rst_in;
  logic valid_in;
  localparam WORLD_BITS = 32;
  logic signed [WORLD_BITS-1:0] x_in;
  logic signed [WORLD_BITS-1:0] y_in;
  logic done_in;

  get_obstacles_on_screen # (
    .WORLD_BITS(WORLD_BITS),
    .MAX_NUM_VERTICES(8),
    .MAX_OBSTACLES_ON_SCREEN(8)
  ) uut (
    .clk_in(clk_in),
    .valid_in(valid_in),
    .x_in(x_in),
    .y_in(y_in),
    .done_in(done_in)
  );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("on_screen.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,on_screen_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in = 0;
        #10;
        done_in = 1;
        #10;
        done_in = 0;
        #10;
        valid_in = 1;
        x_in = 8'hAA;
        y_in = 8'hBB;
        #10;
        x_in = 8'hCC;
        y_in = 8'hDD;
        #10;
        x_in = 8'hEE;
        y_in = 8'hFF;
        #10;
        x_in = 8'h88;
        y_in = 8'h99;
        #10;
        valid_in = 0;
        #10;
        #10;
        #10;
        valid_in = 1;
        x_in = 8'hA0;
        y_in = 8'hB0;
        #10;
        x_in = 8'hC0;
        y_in = 8'hD0;
        #10;
        x_in = 8'hE0;
        y_in = 8'hF0;
        #10;
        x_in = 8'h80;
        y_in = 8'h90;
        #10;
        x_in = 8'h60;
        y_in = 8'h70;
        #10;
        valid_in = 0;
        #10;
        done_in = 1;
        #10;
        done_in = 0;
        #100;
        valid_in = 1;
        x_in = 8'hA0;
        y_in = 8'hB0;
        #10;
        x_in = 8'hC0;
        y_in = 8'hD0;
        #10;
        x_in = 8'hE0;
        y_in = 8'hF0;
        #10;
        valid_in = 0;
        #10;
        #10;
        #10;
        done_in = 1;
        #10;
        done_in = 0;
        #100;
        
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule

`default_nettype wire
