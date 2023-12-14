`timescale 1ns / 1ps
`default_nettype none
//comment here
module update_wheel_tb();
  logic rst_in;

  logic clk_in;
  
  parameter POSITION_SIZE = 17;
  parameter VELOCITY_SIZE = 12;
  parameter NUM_VERTICES = 8;
  parameter NUM_OBSTACLES = 8;
  parameter NUM_NODES = 4;
  parameter NUM_SPRINGS = 6;
  parameter DT = 1;
  parameter ACCELERATION_SIZE = 8;
  parameter FORCE_SIZE = 8;
  parameter GRAVITY = -1;
  parameter TORQUE = 4;
  parameter CONSTANT_SIZE = 8;

  logic begin_update, result_out;
  logic signed [2:0] drive = 0;
  logic [$clog2(NUM_NODES):0] springs [1:0][NUM_SPRINGS];
  logic signed [POSITION_SIZE-1:0] ideal [1:0][NUM_NODES];
  logic signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES];
  logic [$clog2(NUM_OBSTACLES):0] num_obstacles;
  logic [POSITION_SIZE-1:0] axle [1:0];
  
  logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES];
  logic signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES];
  logic signed [VELOCITY_SIZE-1:0] axle_velocity [1:0];

  //logic signed [POSITION_SIZE-1:0] com [1:0];

  assign axle[0] = 5;
  assign axle[1] = 2;
  assign axle_velocity[0] = 0;
  assign axle_velocity[1] = 0;
  //obstacles must be oriented clockwise
  //obstacle 1
  assign obstacles[0][0][0] = -100; //point 1
  assign obstacles[1][0][0] = -100;        
  assign obstacles[0][1][0] = 100; //point 2
  assign obstacles[1][1][0] = -100;  
  assign obstacles[0][2][0] = 100;  //point 3
  assign obstacles[1][2][0] = 100;
  assign obstacles[0][3][0] = -100;  //point 4
  assign obstacles[1][3][0] = 100;

  /*
  
  assign obstacles[0][4][0] = 150;  //point 5
  assign obstacles[1][4][0] = -150;
  assign obstacles[0][5][0] = -150;  //point 6
  assign obstacles[1][5][0] = -150;
  assign obstacles[0][6][0] = -150;  //point 7
  assign obstacles[1][6][0] = 100;
  assign obstacles[0][7][0] = -100;  //point 8
  assign obstacles[1][7][0] = 100; */


  assign all_num_vertices[0] = 4;
  assign num_obstacles = 1;

always_comb begin
  ideal[0][0] = -30;
  ideal[1][0] = -20;
  ideal[0][1] = -20;
  ideal[1][1] = 20;
  ideal[0][2] = 20;
  ideal[1][2] = 20;
  ideal[0][3] = 30;
  ideal[1][3] = -20;


  nodes[0][0] = -50;
  nodes[1][0] = -30;
  nodes[0][1] = -30;
  nodes[1][1] = 10;
  nodes[0][2] = 10;
  nodes[1][2] = 10;
  nodes[0][3] = 20;
  nodes[1][3] = -30;

  velocities[0][0] = 0;
  velocities[1][0] = 0;
  velocities[0][1] = 0;
  velocities[1][1] = 0;
  velocities[0][2] = 0;
  velocities[1][2] = 0;
  velocities[0][3] = 0;
  velocities[1][3] = 0;

  springs[0][0] = 0;
  springs[1][0] = 1;
  springs[0][1] = 1;
  springs[1][1] = 2;
  springs[0][2] = 2;
  springs[1][2] = 3;
  springs[0][3] = 3;
  springs[1][3] = 0;
  springs[0][4] = 0;
  springs[1][4] = 2;
  springs[0][5] = 1;
  springs[1][5] = 3;
end


  //Physics
  localparam NUM_WHEEL_SPRINGS = 6;
  localparam NUM_BODY_SPRINGS = 6;
  localparam NUM_WHEEL_NODES = 4;
  localparam NUM_BODY_NODES = 3;
  localparam NUM_VERTICES = 4;
  localparam NUM_OBSTACLES = 2;
  localparam POSITION_SIZE = 17;
  localparam VELOCITY_SIZE = 15;
  localparam FORCE_SIZE = 15;
  localparam TORQUE = 4;
  localparam GRAVITY = -1;
  localparam DT = 3;
  localparam CONSTANT_SIZE = 3;

  assign begin_update = got_all_obstacles;

  logic begin_update;
  logic [CONSTANT_SIZE-1:0] wheel_constants [4];
  logic [CONSTANT_SIZE-1:0] body_constants [4];
  logic signed [2:0] drive;
  logic signed [POSITION_SIZE-1:0] wheel_ideal [1:0][NUM_WHEEL_NODES];
  logic signed [POSITION_SIZE-1:0] body_ideal [1:0][NUM_BODY_NODES];
  logic [$clog2(NUM_WHEEL_NODES):0] wheel_springs [1:0][NUM_WHEEL_SPRINGS];
  logic [$clog2(NUM_BODY_NODES):0] body_springs [1:0][NUM_BODY_SPRINGS];
  logic [POSITION_SIZE-1:0] wheel_equilibriums [NUM_WHEEL_SPRINGS];
  logic [POSITION_SIZE-1:0] body_equilibriums [NUM_WHEEL_SPRINGS];
  logic signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES]; //might be replaced
  logic [$clog2(NUM_OBSTACLES):0] num_obstacles; //might get replaced
  logic signed [POSITION_SIZE-1:0] left_wheel_x;
  logic signed [POSITION_SIZE-1:0] left_wheel_y;
  logic left_wheel_valid;
  logic signed [POSITION_SIZE-1:0] right_wheel_x;
  logic signed [POSITION_SIZE-1:0] right_wheel_y;
  logic right_wheel_valid;
  logic signed [POSITION_SIZE-1:0] body_x;
  logic signed [POSITION_SIZE-1:0] body_y;
  logic body_valid;
  logic [5:0] states;
  logic [POSITION_SIZE-1:0] com_x, com_y;
  logic com_valid;
  logic all_done;



    manage_car #(
    .DT(DT),
    .NUM_WHEEL_NODES(NUM_WHEEL_NODES),
    .NUM_BODY_NODES(NUM_BODY_NODES),
    .NUM_WHEEL_SPRINGS(NUM_WHEEL_SPRINGS),
    .NUM_BODY_SPRINGS(NUM_BODY_NODES),
    .NUM_VERTICES(NUM_VERTICES),
    .NUM_OBSTACLES(NUM_OBSTACLES),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .CONSTANT_SIZE(CONSTANT_SIZE),
    .TORQUE(TORQUE),
    .GRAVITY(GRAVITY)
  ) car_instance (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .begin_update(begin_update),
    .wheel_constants(wheel_constants),
    .body_constants(body_constants),
    .drive(drive),
    .wheel_ideal(wheel_ideal),
    .body_ideal(body_ideal),
    .wheel_springs(wheel_springs),
    .body_springs(body_springs),
    .wheel_equilibriums(wheel_equilibriums),
    .body_equilibriums(body_equilibriums),
    .obstacles(obstacles),
    .all_num_vertices(all_num_vertices), //num_sides_each_poly
    .num_obstacles(num_obstacles), //num_polys_on_screen
    .debug_switches(debug_switches),
    .left_wheel_x(left_wheel_x),
    .left_wheel_y(left_wheel_y),
    .left_wheel_valid(left_wheel_valid),
    .right_wheel_x(right_wheel_x),
    .right_wheel_y(right_wheel_y),
    .right_wheel_valid(right_wheel_valid),
    .body_x(body_x),
    .body_y(body_y),
    .body_valid(body_valid),
    .states(states),
    .com_x_out(com_x),
    .com_y_out(com_y),
    .com_out_valid(com_valid),
    .all_done(all_done)
  );

  logic [5:0] wheel_states;

  //logic signed [POSITION_SIZE-1:0] new_com [1:0];

  logic signed [POSITION_SIZE-1:0] node_x;
  logic signed [VELOCITY_SIZE-1:0] velocity_x;
  logic signed [POSITION_SIZE-1:0] node_y;
  logic signed [VELOCITY_SIZE-1:0] velocity_y, new_velocities_x, new_velocities_y;

  assign node_x = nodes[0][0];
  assign velocity_x = velocities[0][0];
  assign node_y = nodes[1][0];
  assign velocity_y = velocities[1][0];
  assign new_velocities_x = new_velocities[0][0];
  assign new_velocities_y = new_velocities[1][0];

  logic [$clog2(NUM_NODES):0] new_node_count, new_velocity_count;

  //assign new_nodes[0][0] = 0;

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end

  logic [POSITION_SIZE-1:0] node1 [1:0];
  logic [POSITION_SIZE-1:0] node2 [1:0];
  
  always_comb begin
    for (int i = 0; i < NUM_SPRINGS; i = i + 1) begin
      node1[0] = ideal[springs[0][i]][0];
      node2[0] = ideal[springs[1][i]][0];
      node1[1] = ideal[springs[0][i]][1];
      node2[1] = ideal[springs[1][i]][1];
      equilibriums[i] = $sqrt((node2[1]-node1[1]) * (node2[1]-node1[1]) + (node2[0]-node1[0]) * (node2[0]-node1[0]));
    end

  end

logic [3:0] debug_switches;
  assign sw[15:12] = states;

  logic forward, backward;
  always_comb begin

      for (int i = 0; i < NUM_WHEEL_SPRINGS; i = i + 1) begin
          wheel_equilibriums[i] = 10;//$sqrt((wheel_ideal[wheel_springs[1][i]][1] - wheel_ideal[wheel_springs[0][i]][1]) * (wheel_ideal[wheel_springs[1][i]][1] - wheel_ideal[wheel_springs[0][i]][1]) + (wheel_ideal[wheel_springs[1][i]][0] - wheel_ideal[wheel_springs[0][i]][0]) * (wheel_ideal[wheel_springs[1][i]][0] - wheel_ideal[wheel_springs[0][i]][0]));
      end

      for (int i = 0; i < NUM_BODY_SPRINGS; i = i + 1) begin
          body_equilibriums[i] = 10;//$sqrt((body_ideal[body_springs[1][i]][1] - body_ideal[body_springs[0][i]][1]) * (body_ideal[body_springs[1][i]][1] - body_ideal[body_springs[0][i]][1]) + (body_ideal[body_springs[1][i]][0] - body_ideal[body_springs[0][i]][0]) * (body_ideal[body_springs[1][i]][0] - body_ideal[body_springs[0][i]][0]));
      end

      body_ideal[0][0] = -30;
      body_ideal[1][0] = -20;
      body_ideal[0][1] = -20;
      body_ideal[1][1] = 20;
      body_ideal[0][2] = 20;
      body_ideal[1][2] = 20;
      body_ideal[0][3] = 30;
      body_ideal[1][3] = -20;

      body_springs[0][0] = 0;
      body_springs[1][0] = 1;
      body_springs[0][1] = 1;
      body_springs[1][1] = 2;
      body_springs[0][2] = 2;
      body_springs[1][2] = 3;
      body_springs[0][3] = 3;
      body_springs[1][3] = 0;
      body_springs[0][4] = 0;
      body_springs[1][4] = 2;
      body_springs[0][5] = 1;
      body_springs[1][5] = 3;

      wheel_ideal[0][0] = -30;
      wheel_ideal[1][0] = -20;
      wheel_ideal[0][1] = -20;
      wheel_ideal[1][1] = 20;
      wheel_ideal[0][2] = 20;
      wheel_ideal[1][2] = 20;
      wheel_ideal[0][3] = 30;
      wheel_ideal[1][3] = -20;

      wheel_springs[0][0] = 0;
      wheel_springs[1][0] = 1;
      wheel_springs[0][1] = 1;
      wheel_springs[1][1] = 2;
      wheel_springs[0][2] = 2;
      wheel_springs[1][2] = 3;
      wheel_springs[0][3] = 3;
      wheel_springs[1][3] = 0;
      wheel_springs[0][4] = 0;
      wheel_springs[1][4] = 2;
      wheel_springs[0][5] = 1;
      wheel_springs[1][5] = 3;


      //constants do shifts
      wheel_constants[0] = 1; //spring_k
      wheel_constants[1] = 0; //spring_b
      wheel_constants[2] = 1; //ideal_k
      wheel_constants[3] = 0; //ideal_b

      body_constants[0] = 1; //spring_k
      body_constants[1] = 0; //spring_b
      body_constants[2] = 1; //ideal_k
      body_constants[3] = 0; //ideal_b

      forward = sw[1];
      backward = sw[2];
      drive = forward - backward;

      for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
        for (int j = 0; j < NUM_OBSTACLES; j = j + 1) begin
          obstacles[0][i][j] = on_screen_xs[j][i];
          obstacles[1][i][j] = on_screen_ys[j][i];
        end
      end

  end

  //recieving the new positions and velocities from manage_car
  logic [$clog2(NUM_WHEEL_NODES):0] left_wheel_count, right_wheel_count;
  logic [$clog2(NUM_BODY_NODES):0] body_count;


  always_ff @(posedge clk_pixel) begin
    if (com_valid) begin
      camera_x <= com_x;
      camera_y <= com_y;
    end

    if (left_wheel_valid) begin
      left_wheel_count <= (left_wheel_count == NUM_WHEEL_NODES-1)?0: left_wheel_count + 1;
      car_wheel_1_x[left_wheel_count] <= left_wheel_x;
      car_wheel_1_y[left_wheel_count] <= left_wheel_y;
    end
    if (right_wheel_valid) begin
      right_wheel_count <= (right_wheel_count == NUM_WHEEL_NODES-1)?0: right_wheel_count + 1;
      car_wheel_2_x[right_wheel_count] <= right_wheel_x;
      car_wheel_2_y[right_wheel_count] <= right_wheel_y;
    end
    if (body_count) begin
      body_count <= (body_count == NUM_WHEEL_NODES-1)?0: body_count + 1;
      car_body_x[body_count] <= body_x;
      car_body_y[body_count] <= body_y;
    end

  end
    
        

  //initial block...this is our test simulation
  initial begin
    $dumpfile("update_wheel.vcd"); //file to store value change dump (vcd)
    $dumpvars(1,update_wheel_tb,wheel_updater,wheel_updater.collider, wheel_updater.collider.collision_doer, wheel_updater.ideal_instance, wheel_updater.ideal_instance.springs_instance, wheel_updater.springs_instance, wheel_updater.springs_instance.spring_instance);

    $display("Starting Sim"); //print nice message at start
    clk_in = 1;
    rst_in = 0;
    begin_update = 0;
    #10;
    rst_in = 1;
    
    #10;
    rst_in = 0;
    begin_update = 1;

     new_node_count = 0;
     new_velocity_count = 0;
    #10

    begin_update = 0;

    #30000

    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire