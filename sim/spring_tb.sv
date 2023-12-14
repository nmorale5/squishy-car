`timescale 1ns / 1ps
`default_nettype none
//comment here
module spring_tb();
  logic rst_in;

  logic clk_in;
  localparam FORCE_SIZE = 8;
  localparam POSITION_SIZE = 8;
  localparam VELOCITY_SIZE = 7;
  localparam CONSTANT_SIZE = 3;

  logic signed [CONSTANT_SIZE-1:0] k, b;
  logic signed [FORCE_SIZE-1:0] force_x_out, force_y_out;
  logic [POSITION_SIZE-1:0] equilibrium;
  assign k = 1;
  assign b = 0;

  logic signed [POSITION_SIZE-1:0] v1 [1:0];
  logic signed [POSITION_SIZE-1:0] v2 [1:0];
  logic spring_begin, spring_done;

  logic signed [VELOCITY_SIZE-1:0] vel1_x, vel1_y, vel2_x, vel2_y;
  logic signed [POSITION_SIZE-1:0] x_1,y_1,x_2,y_2;
  assign x_1 = v1[0];
  assign y_1 = v1[1];
  assign x_2 = v2[0];
  assign y_2 = v2[1];

  
  spring #(CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE) spring_instance (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .input_valid(spring_begin),
    .k(k),
    .b(b),
    .v1(v1),
    .v2(v2),
    .equilibrium(equilibrium),
    .vel1_x(vel1_x),
    .vel1_y(vel1_y),
    .vel2_x(vel2_x),
    .vel2_y(vel2_y),
    .force_x(force_x_out),
    .force_y(force_y_out),
    .result_valid(spring_done)
    //
  );


  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
    
        

  //initial block...this is our test simulation
  initial begin
    $dumpfile("spring.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,spring_tb, spring_instance, spring_instance.sqrt_instance, spring_instance.x_divider);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    spring_begin = 1;
    v1[0] = 2;
    v1[1] = 2;
    v2[0] = 2;
    v2[1] = 4;
    vel1_x = 0;
    vel1_y = 0;
    vel2_x = 0; 
    vel2_y = 0;
    equilibrium = 2;
    #10
    spring_begin = 0;
    #800

    spring_begin = 1;
    v1[0] = 2;
    v1[1] = 2;
    v2[0] = 2;
    v2[1] = 5;
    vel1_x = 0;
    vel1_y = 0;
    vel2_x = 0; 
    vel2_y = 0;

    equilibrium = 2;
    #10
    spring_begin = 0;
    #800

    spring_begin = 1;
    v1[0] = 2;
    v1[1] = 2;
    v2[0] = 5;
    v2[1] = 6;
    vel1_x = 0;
    vel1_y = 0;
    vel2_x = 0; 
    vel2_y = 0;

    equilibrium = 2;
    #10
    spring_begin = 0;
    #800

    spring_begin = 1;
    v1[0] = -13;
    v1[1] = -8;
    v2[0] = 98;
    v2[1] = 111;
    
    vel1_x = 0;
    vel1_y = 0;
    vel2_x = 0; 
    vel2_y = 0;

    equilibrium = 0;
    #10
    spring_begin = 0;
    #1000

    spring_begin = 1;
    v1[0] = -1;
    v1[1] = -8;
    v2[0] = 8;
    v2[1] = 11;
    
    vel1_x = 5;
    vel1_y = 6;
    vel2_x = -5; 
    vel2_y = 6;

    equilibrium = 0;
    #10
    spring_begin = 0;
    #500
    #6000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire