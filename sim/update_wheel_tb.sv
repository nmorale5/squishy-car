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


  logic signed [POSITION_SIZE-1:0] new_nodes [1:0][NUM_NODES];
  logic signed [VELOCITY_SIZE-1:0] new_velocities [1:0][NUM_NODES];
  logic signed [POSITION_SIZE-1:0] new_node_x, new_node_y;
  logic signed [VELOCITY_SIZE-1:0] new_velocity_x, new_velocity_y;
  logic signed [FORCE_SIZE-1:0] axle_force_x, axle_force_y;
  logic new_node_valid, new_velocity_valid;
  logic [POSITION_SIZE-1:0] equilibriums [NUM_SPRINGS];
  logic [CONSTANT_SIZE-1:0] constants [4];

  assign constants[0] = 1; //springs_k
  assign constants[1] = 0; //springs_b

  // Instantiate the update_wheel module
  update_wheel #(
    .NUM_SPRINGS(NUM_SPRINGS),
    .NUM_NODES(NUM_NODES),
    .NUM_VERTICES(NUM_VERTICES),
    .NUM_OBSTACLES(NUM_OBSTACLES),
    .CONSTANT_SIZE(CONSTANT_SIZE),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .TORQUE(TORQUE),
    .GRAVITY(GRAVITY),
    .DT(DT)
  ) wheel_updater (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_update),
    .constants(constants),
    .drive(drive),
    .ideal(ideal),
    .obstacles(obstacles),
    .all_num_vertices(all_num_vertices),
    .num_obstacles(num_obstacles),
    .nodes_in(nodes),
    .velocities_in(velocities),
    .springs(springs),
    .equilibriums(equilibriums),
    .axle(axle),
    .axle_velocity(axle_velocity),
    .node_out_x(new_node_x),
    .node_out_y(new_node_y),
    .node_out_valid(new_node_valid),
    .velocity_out_x(new_velocity_x),
    .velocity_out_y(new_velocity_y),
    .velocity_out_valid(new_velocity_valid),
    .axle_force_x(axle_force_x),
    .axle_force_y(axle_force_y),
    .states(wheel_states),
    .result_out(result_out)
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

  logic [POSITION_SIZE-1:0] equ;
  assign equ = equilibriums[0];


  always_ff @(posedge clk_in) begin
    if (new_node_valid == 1) begin
      new_node_count <= new_node_count + 1;
      new_nodes[0][new_node_count] <= new_node_x;
      new_nodes[1][new_node_count] <= new_node_y;
    end

    if (new_velocity_valid == 1) begin
      new_velocity_count <= new_velocity_count + 1;
      new_velocities[0][new_velocity_count] <= new_velocity_x;
      new_velocities[1][new_velocity_count] <= new_velocity_y;
    end

    if (result_out == 1) begin
      new_node_count <= 0;
      new_velocity_count <= 0;
      nodes[0][0] <= new_nodes[0][0];
      nodes[1][0] <= new_nodes[1][0];
      nodes[0][1] <= new_nodes[0][1];
      nodes[1][1] <= new_nodes[1][1];
      nodes[0][2] <= new_nodes[0][2];
      nodes[1][2] <= new_nodes[1][3];
      nodes[0][3] <= new_nodes[0][3];
      nodes[1][3] <= new_nodes[1][3];

      velocities[0][0] <= new_velocities[0][0];
      velocities[1][0] <= new_velocities[1][0];
      velocities[0][1] <= new_velocities[0][1];
      velocities[1][1] <= new_velocities[1][1];
      velocities[0][2] <= new_velocities[0][2];
      velocities[1][2] <= new_velocities[1][2];
      velocities[0][3] <= new_velocities[0][3];
      velocities[1][3] <= new_velocities[1][3];
      begin_update <= 1;
    end else begin
      begin_update <= 0;
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
    nodes[0][0] = 3;
     nodes[1][0] = -2;
     nodes[0][1] = -2;
     nodes[1][1] = 2;
     nodes[0][2] = 2;
     nodes[1][2] = 2;
     nodes[0][3] = 3;
     nodes[1][3] = -2;

     velocities[0][0] = 0;
     velocities[1][0] = 0;
     velocities[0][1] = 0;
     velocities[1][1] = 0;
     velocities[0][2] = 0;
     velocities[1][2] = 0;
     velocities[0][3] = 0;
     velocities[1][3] = 0;

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