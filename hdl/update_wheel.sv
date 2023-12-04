module update_wheel #(NUM_SPRINGS = 10, NUM_NODES = 10, NUM_VERTICES =8, NUM_OBSTACLES=6, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8, TORQUE=4, GRAVITY=-1,DT)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  //input wire axle_valid,
  input  wire signed [2:0] drive,
  input  wire signed [POSITION_SIZE-1:0] ideal [1:0][NUM_NODES],
  input  wire [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES], //array of num_vertices
  input  wire [$clog2(NUM_OBSTACLES)-1:0] num_obstacles,
  input  wire signed [POSITION_SIZE-1:0] nodes_in [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities_in [1:0][NUM_NODES],
  input  wire [$clog2(NUM_NODES)-1:0] springs [1:0][NUM_SPRINGS],
  input  wire signed [POSITION_SIZE-1:0] axle [1:0], 
  input  wire signed [VELOCITY_SIZE-1:0] axle_velocity [1:0],
  output logic signed [POSITION_SIZE-1:0] nodes_out [1:0][NUM_NODES],
  output logic signed [VELOCITY_SIZE-1:0] velocities_out [1:0][NUM_NODES],
  output logic signed [FORCE_SIZE-1:0] axle_force [1:0],
  //output logic signed [POSITION_SIZE-1:0] com_out [1:0], 
  output logic result_out
  
);
//for testing
logic [$clog2(NUM_VERTICES):0] nv;
assign nv = all_num_vertices[0];
logic [POSITION_SIZE-1:0] ax, ay;
assign ax = nodes_in[0][0];
assign ay = nodes_in[1][0];

//done for testing

  typedef enum {IDLE = 0, COLLISIONS = 1, FORCES = 2, VELOCITY = 3, RESULT=4} wheel_state;
  wheel_state state = IDLE;

  logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES];
  logic signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES];
  logic begin_collisions, begin_ideal, begin_torque, begin_com, begin_springs;
  logic collisions_done, ideal_done, torque_done, com_done, springs_done;
  logic [2:0] forces_ready = 0;


  logic signed [FORCE_SIZE-1:0] total_forces [1:0][NUM_NODES];
  logic signed [POSITION_SIZE-1:0] point_pos_x, point_pos_y, point_new_pos_x, point_new_pos_y;
  logic signed [VELOCITY_SIZE-1:0] point_vel_x, point_vel_y, point_new_vel_x, point_new_vel_y;
  logic signed [FORCE_SIZE-1:0] point_force_x, point_force_y;

//collisions, forces with new positions/velocities, update velocity
  // Instantiate the update_point module

logic signed [FORCE_SIZE-1:0] collisions_forces [1:0][NUM_NODES];

  collisions #(
    .DT(DT),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .NUM_VERTICES(NUM_VERTICES),
    .NUM_OBSTACLES(NUM_OBSTACLES),
    .ACCELERATION_SIZE(FORCE_SIZE)
  ) collider (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_collisions),
    .obstacles_in(obstacles),
    .all_num_vertices_in(all_num_vertices),
    .num_obstacles_in(num_obstacles),
    .pos_x_in(point_pos_x),
    .pos_y_in(point_pos_y),
    .vel_x_in(point_vel_x),
    .vel_y_in(point_vel_y),
    .acceleration_x_out(point_force_x),
    .acceleration_y_out(point_force_y),
    .new_pos_x(point_new_pos_x),
    .new_pos_y(point_new_pos_y),
    .new_vel_x(point_new_vel_x),
    .new_vel_y(point_new_vel_y),
    .result_out(collision_done)
  );

  logic signed [FORCE_SIZE-1:0] springs_forces [1:0][NUM_NODES];

  // Instantiate the springs module
  springs #(
    .NUM_SPRINGS(NUM_SPRINGS),
    .NUM_NODES(NUM_NODES),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE)
  ) uut (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .input_valid(begin_springs),
    .nodes(nodes),
    .velocities(velocities),
    .springs(springs),
    .spring_forces(springs_forces),
    .output_valid(springs_done)
  );

  logic signed [FORCE_SIZE-1:0] ideal_forces [1:0][NUM_NODES];

  // Instantiate the ideal module
  ideal #(
    .NUM_NODES(NUM_NODES),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE)
  ) ideal_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .input_valid(begin_ideal),
    .axle(axle),
    .axle_velocity(axle_velocity)
,    .nodes(nodes),
    .ideal(ideal),
    .velocities(velocities),
    .ideal_forces(ideal_forces),
    .axle_force(axle_force),
    .output_valid(ideal_done)
  );


logic signed [FORCE_SIZE-1:0] torque_forces [1:0][NUM_NODES];

//do torque here
torque #(
    .NUM_NODES(NUM_NODES),
    .POSITION_SIZE(POSITION_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .TORQUE(TORQUE)
) torque_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_torque),
    .drive(drive),
    .nodes(nodes),
    .axle(axle),
    .torque_forces(torque_forces),
    .result_out(torque_done)
  );


//do gravity here
logic [FORCE_SIZE-1:0] gravity_force;
assign gravity_force = GRAVITY;

logic [$clog2(NUM_NODES):0] collision_node;
always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin
            begin_collisions <= 0;
            result_out <= 0;
            if (begin_in == 1) begin
                state <= COLLISIONS;
                begin_collisions <= 1;
                collision_node <= 1;
                //add gravity to total forces
                //genvar i;
                //generate

                  for (integer i = 0; i< NUM_NODES; i = i + 1) begin
                    total_forces[0][i] <= total_forces[0][i] + gravity_force;
                    total_forces[1][i] <= total_forces[1][i] + gravity_force;
                  end
                //endgenerate

                point_pos_x <= nodes_in[0][0];
                point_pos_y <= nodes_in[1][0];
                point_vel_x <= velocities_in[0][0];
                point_vel_y <= velocities_in[1][0];
            end
        end
        COLLISIONS: begin
          begin_collisions <= 0;
          if (collision_done == 1) begin
            begin_collisions <= 1;
            collision_node <= collision_node + 1;
            //add forces to total forces
            //update positions and velocities
            point_pos_x <= nodes_in[0][collision_node];
            point_pos_y <= nodes_in[1][collision_node];
            point_vel_x <= velocities_in[0][collision_node];
            point_vel_y <= velocities_in[1][collision_node];

            nodes[0][collision_node -1] <= point_new_pos_x;
            nodes[1][collision_node -1] <= point_new_pos_y;
            velocities[0][collision_node -1] <= point_new_vel_x;
            velocities[1][collision_node -1] <= point_new_vel_y;

            total_forces[0][collision_node-1] <= total_forces[0][collision_node-1] + point_force_x;
            total_forces[1][collision_node-1] <= total_forces[1][collision_node-1] + point_force_y;
            if (collision_node == NUM_NODES) begin
              state <= FORCES;
              begin_springs <= 1;
              begin_ideal <= 1;
              begin_torque <= 1;
              begin_com <= 1;
            end 

          end else begin
            begin_collisions <= 0;
          end
        end
        FORCES: begin
            begin_springs <= 0;
            begin_ideal <= 0;
            begin_torque <= 0;
            begin_com <= 0;
            if (springs_done == 1) begin
                forces_ready[0] <= 1;
            end
            if (ideal_done == 1) begin
                forces_ready[1] <= 1;
            end
            if (torque_done == 1) begin
                forces_ready[2] <= 1;
            end

            if (forces_ready == 3'b111) begin
              //genvar i;
              //generate
                for (integer i = 0; i< NUM_NODES; i = i + 1) begin
                  total_forces[0][i] <= total_forces[0][i] + springs_forces[0][i] + ideal_forces[0][i] + torque_forces[0][i];
                  total_forces[1][i] <= total_forces[1][i] + springs_forces[1][i] + ideal_forces[1][i] + torque_forces[1][i];
                end
              //endgenerate
              state <= VELOCITY;
            end
        end
        VELOCITY: begin
            //do this for every point
            //new_vel_x <= new_vel_x + acceleration_x * DT;
            ///new_vel_y <= new_vel_y + acceleration_y * DT;
            //genvar i;
            //generate
              for (integer i = 0; i< NUM_NODES; i = i + 1) begin
                velocities_out[0][i] <= velocities[0][i] + total_forces[0][i] * DT;//add divide by mass later
                velocities_out[1][i] <= velocities[1][i] + total_forces[1][i] * DT;
              end
            //endgenerate
            //if (com_done) begin
                //state <= RESULT;
            //end
            state <= RESULT;
        end
        RESULT: begin
            result_out <= 1;
            state <= IDLE;
        end


    endcase


end

endmodule

  