module manage_car #(NUM_WHEEL_NODES, NUM_BODY_NODES, NUM_VERTICES, NUM_OBSTACLES, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_update,
  input  wire [CONSTANT_SIZE-1:0] wheel_constants [4],
  input  wire [CONSTANT_SIZE-1:0] body_constants [4],
  input  wire signed [2:0] drive,
  input  wire signed [POSITION_SIZE-1:0] wheel_ideal [1:0][NUM_WHEEL_NODES],
  input  wire signed [POSITION_SIZE-1:0] body_ideal [1:0][NUM_BODY_NODES],
  input  wire signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES], //array of num_vertices
  input  wire [$clog2(NUM_OBSTACLES):0] num_obstacles,
  input  wire [3:0] debug_switches,
  output logic signed [POSITION_SIZE-1:0] left_wheel_x,
  output logic signed [POSITION_SIZE-1:0] left_wheel_y,
  output logic left_wheel_valid,
  output logic signed [POSITION_SIZE-1:0] right_wheel_x,
  output logic signed [POSITION_SIZE-1:0] right_wheel_y,
  output logic right_wheel_valid,
  output logic signed [POSITION_SIZE-1:0] body_x,
  output logic signed [POSITION_SIZE-1:0] body_y,
  output logic body_valid,
  output logic [5:0] states,
  output logic signed [POSITION_SIZE-1:0] com_x_out, 
  output logic signed [POSITION_SIZE-1:0] com_y_out,
  output logic com_out_valid,
  output logic all_done
  
);

  logic begin_body, begin_wheel, wheel_result, body_result;
  logic [$clog2(NUM_NODES):0] left_wheel_springs [1:0][NUM_WHEEL_SPRINGS];
  logic [$clog2(NUM_NODES):0] right_wheel_springs [1:0][NUM_WHEEL_SPRINGS];
  logic [$clog2(NUM_NODES):0] body_springs [1:0][NUM_BODY_SPRINGS];
  logic signed [POSITION_SIZE-1:0] wheel_ideal [1:0][NUM_WHEEL_NODES];
  //logic signed [POSITION_SIZE-1:0] right_wheel_ideal [1:0][NUM_WHEEL_NODES];
  logic signed [POSITION_SIZE-1:0] body_ideal [1:0][NUM_BODY_NODES];
  logic signed [POSITION_SIZE-1:0] left_wheel_nodes [1:0][NUM_WHEEL_NODES];
  logic signed [POSITION_SIZE-1:0] right_wheel_nodes [1:0][NUM_WHEEL_NODES];
  logic signed [POSITION_SIZE-1:0] body_nodes [1:0][NUM_BODY_NODES];
  logic signed [VELOCITY_SIZE-1:0] left_wheel_velocities [1:0][NUM_WHEEL_NODES];
  logic signed [VELOCITY_SIZE-1:0] right_wheel_velocities [1:0][NUM_WHEEL_NODES];
  logic signed [VELOCITY_SIZE-1:0] body_velocities [1:0][NUM_BODY_NODES];
  logic [POSITION_SIZE-1:0] wheel_equilibriums [NUM_WHEEL_SPRINGS];
  logic [POSITION_SIZE-1:0] body_equilibriums [NUM_WHEEL_SPRINGS];

  logic signed [POSITION_SIZE-1:0] left_wheel_new_node_x, left_wheel_new_node_y, right_wheel_new_node_x, right_wheel_new_node_y, body_new_node_x, body_new_node_y;
  logic signed [VELOCITY_SIZE-1:0]   left_wheel_new_velocity_x, left_wheel_new_velocity_y, right_wheel_new_velocity_x, right_wheel_new_velocity_y, body_new_velocity_x, body_new_velocity_y;
  logic wheel_node_valid, wheel_velocity_valid, body_node_valid, body_velocity_valid;
  logic [$clog2(NUM_WHEEL_NODES):0] wheel_node_count, wheel_velocity_count;
  logic [$clog2(NUM_BODY_NODES):0] body_node_count, body_node_count;
  logic body_nodes_done;



  //logic signed [VELOCITY_SIZE-1:0] new_velocities [1:0][NUM_NODES];
  //logic signed [POSITION_SIZE-1:0] new_nodes [1:0][NUM_NODES];

  //axle stuff
  logic signed [POSITION_SIZE-1:0] left_axle [1:0];
  logic signed [POSITION_SIZE-1:0] right_axle [1:0];
  logic signed [FORCE_SIZE-1:0] left_axle_force [1:0];
  logic signed [FORCE_SIZE-1:0] right_axle_force [1:0];
  logic signed [VELOCITY_SIZE-1:0] left_axle_velocity [1:0];
  logic signed [VELOCITY_SIZE-1:0] right_axle_velocity [1:0];
  logic signed [FORCE_SIZE-1:0] left_axle_force_x, left_axle_force_y, right_axle_force_x, right_axle_force_y;


  center_of_mass #(POSITION_SIZE, NUM_NODES) com (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .x_in(body_new_node_x),
    .y_in(body_new_node_y),
    .valid_in(body_node_valid),
    .tabulate_in(body_nodes_done),
    .x_out(com_x_out),
    .y_out(com_y_out),
    .valid_out(com_out_valid));

  update_wheel #(
    .NUM_SPRINGS(NUM_WHEEL_SPRINGS),
    .NUM_NODES(NUM_WHEEL_NODES),
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
    .begin_in((begin_update || begin_wheel) && debug_switches[3]),
    .constants(wheel_constants),
    .drive(drive),
    .ideal(wheel_ideal),
    .obstacles(obstacles),
    .all_num_vertices(all_num_vertices),
    .num_obstacles(num_obstacles),
    .nodes_in(wheel_nodes),
    .velocities_in(wheel_velocities),
    .springs(wheel_springs),
    .equilibriums(wheel_equilibriums),
    .axle(axle),
    .axle_velocity(axle_velocity),
    .node_out_x(wheel_new_node_x),
    .node_out_y(wheel_new_node_y),
    .node_out_valid(wheel_node_valid),
    //.node_out_done(new_node_done),
    .velocity_out_x(wheel_new_velocity_x),
    .velocity_out_y(wheel_new_velocity_y),
    .velocity_out_valid(wheel_velocity_valid),
    .axle_force_x(axle_force_x),
    .axle_force_y(axle_force_y),
    .axle_out_valid(axle_valid)
    .states(wheel_states),
    .result_out(wheel_result)
  );

  assign states = wheel_states;

  //0 is left, 1 is right
  logic wheel_choice;

  if (wheel_choice ==0 ) begin
    wheel_nodes = left_wheel_nodes;
    wheel_velocities = left_wheel_velocities;
    axle = left_axle;
    axle_velocity = left_axle_velocity;

  end else begin
    wheel_nodes = right_wheel_nodes;
    wheel_velocities = right_wheel_velocities;
    axle = right_axle;
    axle_velocity = right_axle_velocity;
  end
  



/*

      update_late <= 0;
      update_done_yet <= 0;
            axle_velocity[0] <= 0;
      axle_velocity[1] <= 0;
      axle[0] <= 5;
      axle[1] <= 2;
            nodes_done_count <= 0;
    */

    logic [5:0] wheel_states;
      assign states = wheel_states;

    logic [3:0] dones;
    assign all_done = & dones;

    logic [POSITION_SIZE-1:0] node1 [1:0];
     logic [POSITION_SIZE-1:0] node2 [1:0];
    always_comb begin

        for (int i = 0; i < NUM_SPRINGS; i = i + 1) begin
            node1[0] = wheel_ideal[wheel_springs[0][i]][0];
            node2[0] = wheel_ideal[wheel_springs[1][i]][0];
            node1[1] = wheel_ideal[wheel_springs[0][i]][1];
            node2[1] = wheel_ideal[wheel_springs[1][i]][1];
            wheel_equilibriums[i] = $sqrt((node2[1]-node1[1]) * (node2[1]-node1[1]) + (node2[0]-node1[0]) * (node2[0]-node1[0]));
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

    end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin //initialize everything
      body_node_count <= 0;
      body_velocity_count <= 0;
      wheel_node_count <= 0;
      wheel_velocity_count <= 0;


      for (int i = 0; i<NUM_WHEEL_NODES; i = i + 1) begin
        body_nodes[0][i] <= body_ideal[0][i];
        body_nodes[1][i] <= body_ideal[1][i];

        left_wheel_nodes[0][i] <= wheel_ideal[0][i] - 30;
        left_wheel_nodes[1][i] <= wheel_ideal[1][i] - 10;

        right_wheel_nodes[0][i] <= wheel_ideal[0][i] + 30;
        right_wheel_nodes[1][i] <= wheel_ideal[1][i] - 10;

        left_wheel_velocities[0][i] <= 0;
        left_wheel_velocities[1][i] <= 0;
        right_wheel_velocities[0][i] <= 0;
        right_wheel_velocities[1][i] <= 0;
      end
    end else begin


        if (body_node_valid == 1) begin
            body_node_count <= body_node_count + 1;
            body_nodes[0][body_node_count] <= body_new_node_x;
            body_nodes[1][body_node_count] <= body_new_node_y;
            body_x <= body_new_node_x;
            body_y <= body_new_node_y;
            body_valid <= 1;
        end else begin
            body_valid <= 0;

        end

        if (axle_valid) begin
            if (wheel_choice == 0) begin
                left_axle_force_x <= axle_force_x;
                left_axle_force_y <= axle_force_y;
            end else begin
                right_axle_force_x <= axle_force_x;
                right_axle_force_y <= axle_force_y;
            end
        end

      if (wheel_node_valid == 1) begin
        wheel_node_count <= wheel_node_count + 1;
        if (wheel_choice == 0) begin
            left_wheel_nodes[0][wheel_node_count] <= wheel_new_node_x;
            left_wheel_nodes[1][wheel_node_count] <= wheel_new_node_y;
            left_wheel_x <= wheel_new_node_x;
            left_wheel_y <= wheel_new_node_y;
            left_wheel_valid <= 1;
        end else begin
            right_wheel_nodes[0][wheel_node_count] <= wheel_new_node_x;
            right_wheel_nodes[1][wheel_node_count] <= wheel_new_node_y;
            right_wheel_x <= wheel_new_node_x;
            right_wheel_y <= wheel_new_node_y;
            right_wheel_valid <= 1;
        end

      end else begin
        left_wheel_valid <= 0;
        right_wheel_valid <= 0;
      end

      if (wheel_velocity_valid == 1) begin
        wheel_velocity_count <= wheel_velocity_count + 1;
        if (wheel_choice == 0) begin
            left_wheel_velocities[0][wheel_velocity_count] <= wheel_new_velocity_x;
            left_wheel_velocities[1][wheel_velocity_count] <= wheel_new_velocity_y;
        end else begin
            right_wheel_velocities[0][wheel_velocity_count] <= wheel_new_velocity_x;
            right_wheel_velocities[1][wheel_velocity_count] <= wheel_new_velocity_y;
        end

      end

      if (body_result == 1) begin
        body_node_count <= 0;
        body_velocity_count <= 0;
        dones[2] <= 1;
      end

      if (wheel_result == 1) begin
        wheel_node_count <= 0;
        wheel_velocity_count <= 0;

        if (wheel_choice == 0) begin
            begin_wheel <= 1;
            dones[0] <= 1;
            wheel_choice <= 1;
        end else begin
            dones[1] <= 1;
            wheel_choice <= 0;
        end
      end else begin
        begin_wheel <= 0;

      end

      if (all_done == 1) begin
        dones <= 0;
      end
    end
  end




endmodule