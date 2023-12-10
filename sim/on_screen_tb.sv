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
    .MAX_OBSTACLES_ON_SCREEN(2)
  ) uut (
    .clk_in(clk_in),
    .valid_in(valid_in),
    .x_in(x_in),
    .y_in(y_in),
    .screen_min_x(0),
    .screen_max_x(100),
    .screen_min_y(0),
    .screen_max_y(100),
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
        x_in = 150;
        y_in = 50;
        #10;
        x_in = 50;
        y_in = -1;
        #10;
        x_in = 20;
        y_in = 20;
        #10;
        x_in = 300;
        y_in = 300;
        #10;
        valid_in = 0;
        #10;
        #10;
        #10;
        valid_in = 1;
        x_in = 200;
        y_in = 200;
        #10;
        x_in = 300;
        y_in = 300;
        #10;
        x_in = 400;
        y_in = 400;
        #10;
        x_in = 500;
        y_in = 500;
        #10;
        x_in = 600;
        y_in = 600;
        #10;
        valid_in = 0;
        #10;
        done_in = 1;
        #10;
        done_in = 0;
        #100;
        valid_in = 1;
        x_in = 20;
        y_in = 200;
        #10;
        x_in = 500;
        y_in = 500;
        #10;
        x_in = 30;
        y_in = 30;
        #10;
        valid_in = 0;
        #10;
        #10;
        #10;
        valid_in = 1;
        x_in = 40;
        y_in = 40;
        #10;
        x_in = 50;
        y_in = 50;
        #10;
        x_in = 60;
        y_in = 60;
        #10;
        valid_in = 0;
        #10;
        #10;
        #10;
        valid_in = 1;
        x_in = 20;
        y_in = 20;
        #10;
        x_in = 500;
        y_in = 500;
        #10;
        x_in = 300;
        y_in = 30;
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
