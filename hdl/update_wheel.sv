module update_wheel #(NUM_SPRINGS = 10, NUM_NODES = 10, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8, TORQUE=4, GRAVITY=-1)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  inout  wire [2:0] drive,
  input  wire [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [$clog2(NUM_VERTICES)-1:0] all_num_vertices [NUM_OBSTACLES], //array of num_vertices
  input  wire [$clog2(NUM_OBSTACLES)-1:0] num_obstacles,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES],
  input  wire [$clog2(NUM_NODES)-1:0] springs [1:0][NUM_SPRINGS],
  input  wire signed [POSITION_SIZE-1:0] com_x, 
  input  wire signed [POSITION_SIZE-1:0] com_y,
  output logic output_valid
  
);

  logic signed [FORCE_SIZE-1:0] total_forces [1:0][NUM_NODES];

//collisions, forces with new positions/velocities, update velocity
  // Instantiate the update_point module
  collisions #(
    .DT(DT),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .NUM_VERTICES(NUM_VERTICES),
    .NUM_OBSTACLES(NUM_OBSTACLES),
    .ACCELERATION_SIZE(FORCE_SIZE)
  ) point_updater (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_collisions),
    .obstacles_in(obstacles),
    .all_num_vertices_in(all_num_vertices),
    .num_obstacles_in(num_obstacles),
    .pos_x_in(point_pos_x),
    .pos_y_in(point_pos_y),
    .vel_x_in(point_vel_x),
    .vel_y_in(point_vel_y_in),
    .acceleration_x(point_force_x),
    .acceleration_y(point_force_y),
    .new_pos_x(point_new_pos_x),
    .new_pos_y(point_new_pos_y),
    .new_vel_x(point_new_vel_x),
    .new_vel_y(point_new_vel_y),
    .result_out(collision_done)
  );

  logic begin_springs;
  logic signed [FORCE_SIZE-1:0] springs_forces [1:0][NUM_NODES];
  logic springs_done;

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

  logic ideal_begin;

  logic signed [FORCE_SIZE-1:0] ideal_forces [1:0][NUM_NODES];
  logic ideal_done;

  // Instantiate the ideal module
  ideal #(
    .NUM_NODES(NUM_NODES),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE)
  ) ideal_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .input_valid(ideal_begin),
    .com_x(com_x),
    .com_y(com_y),
    .nodes(nodes),
    .ideal(ideal),
    .velocities(velocities),
    .ideal_forces(ideal_forces),
    .output_valid(ideal_done)
  );

//do torque here, nvm do need torque module
torque_force = TORQUE * drive
//do gravity here
gravity_force = GRAVITY;

always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin
            if (begin_in == 1) begin
                state <= COLLISIONS;
                begin_collisions <= 1;
                //add gravity to total forces
            end
        end
        COLLISIONS: begin
            begin_collisions <= 0;
            if (collision_done == 1) begin
                //add forces to total forces
                //update positions and velocities
                state <= FORCES;
                begin_springs <= 1;
                begin_ideal <= 1;
                begin_torque <= 1;
                begin_com <= 1;
            end
        end
        FORCES: begin
            begin_springs <= 0;
            begin_ideal <= 0;
            begin_torque <= 0;
            begin_com <= 0
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
                //add three forces
                state <= VELOCITY;
            end
        end
        VELOCITY: begin
            //do this for every point
            new_vel_x <= new_vel_x + acceleration_x * DT;
            new_vel_y <= new_vel_y + acceleration_y * DT;
            if (com_done) begin
                state <= RESULT;
            end
        end
        RESULT: begin
            result_out <= 1;
        end


    endcase


end

endmodule

  