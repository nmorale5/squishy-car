module update_body #(NUM_SPRINGS, NUM_NODES, NUM_VERTICES, NUM_OBSTACLES, CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE, GRAVITY,DT)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire [CONSTANT_SIZE-1:0] constants [4],
  input wire signed [POSITION_SIZE-1:0] com_x,
  input wire signed [POSITION_SIZE-1:0] com_y,
  input  wire signed [POSITION_SIZE-1:0] ideal [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES], //array of num_vertices
  input  wire [$clog2(NUM_OBSTACLES):0] num_obstacles,
  input  wire signed [POSITION_SIZE-1:0] nodes_in [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities_in [1:0][NUM_NODES],
  input  wire [$clog2(NUM_NODES):0] springs [1:0][NUM_SPRINGS],
  input  wire [POSITION_SIZE-1:0] equilibriums [NUM_SPRINGS],
  input  wire signed [FORCE_SIZE-1:0] laxle_force_x,
  input  wire signed [FORCE_SIZE-1:0] laxle_force_y,
  input  wire laxle_force_valid,
  input  wire signed [FORCE_SIZE-1:0] raxle_force_x,
  input  wire signed [FORCE_SIZE-1:0] raxle_force_y,
  input  wire raxle_force_valid,
  output logic signed [POSITION_SIZE-1:0] laxle [1:0], 
  output logic signed [VELOCITY_SIZE-1:0] laxle_velocity [1:0],
  output logic laxle_valid,
  output logic signed [POSITION_SIZE-1:0] raxle [1:0], 
  output logic signed [VELOCITY_SIZE-1:0] raxle_velocity [1:0],
  output logic raxle_valid,
  output logic signed [POSITION_SIZE-1:0] node_out_x,
  output logic signed [POSITION_SIZE-1:0] node_out_y,
  output logic node_out_valid,
  output logic node_out_done,
  output logic signed [VELOCITY_SIZE-1:0] velocity_out_x,
  output logic signed [VELOCITY_SIZE-1:0] velocity_out_y,
  output logic velocity_out_valid,
  output logic result_out
  
);




  logic signed [POSITION_SIZE-1:0] com  [1:0];
  assign com[0] = com_x;
  assign com[1] = com_y;

//done for testing

  typedef enum {IDLE = 0, COLLISIONS = 1, FORCES = 2, VELOCITY = 3, RESULT=4} body_state;
  body_state state = IDLE;


  //internal variables
  logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES];
  logic signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES];
//for submodules, there should be a copy of everything in the order, collisions, springs, ideal
  //submodule controls
  logic begin_collisions, begin_ideal, begin_com, begin_springs;
  logic ideal_done, com_done, springs_done; //maybe a done signal for collisions
  logic [3:0] forces_ready = 0;

  //submodule inputs
  logic signed [POSITION_SIZE-1:0] point_pos_y, point_pos_x, point_new_pos_x, point_new_pos_y;
  logic signed [VELOCITY_SIZE-1:0] point_vel_x, point_vel_y, point_new_vel_x, point_new_vel_y;

  //submodule outputs
  logic signed [FORCE_SIZE-1:0] point_force_x, springs_force_x, ideal_force_x;
  logic signed [FORCE_SIZE-1:0] point_force_y, springs_force_y, ideal_force_y;
  logic collision_force_valid, springs_force_valid, ideal_force_valid;


  //force holders and controls
  logic signed [FORCE_SIZE-1:0] collisions_forces [1:0][NUM_NODES];
  logic signed [FORCE_SIZE-1:0] springs_forces [1:0] [NUM_NODES];
  logic signed [FORCE_SIZE-1:0] ideal_forces [1:0][NUM_NODES];

  logic [$clog2(NUM_NODES):0] collision_node, springs_force_count, ideal_force_count;

  logic signed [FORCE_SIZE-1:0] total_forces [1:0][NUM_NODES];


  //output controls
  logic [$clog2(NUM_NODES):0] velocity_out_num;

 
  collisions #(
    .DT(DT),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .NUM_VERTICES(NUM_VERTICES),
    .NUM_OBSTACLES(NUM_OBSTACLES)
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
    .force_x_out(point_force_x),
    .force_y_out(point_force_y),
    .new_pos_x(point_new_pos_x),
    .new_pos_y(point_new_pos_y),
    .new_vel_x(point_new_vel_x),
    .new_vel_y(point_new_vel_y),
    .result_out(collision_force_valid)
  );

  logic [CONSTANT_SIZE-1:0] springs_k, springs_b, ideal_k, ideal_b; 
  assign springs_k = constants[0];
  assign springs_b = constants[1];
  assign ideal_k = constants[2];
  assign ideal_b = constants[3];

  // Instantiate the springs module
  springs #(
    .NUM_SPRINGS(NUM_SPRINGS),
    .NUM_NODES(NUM_NODES),
    .CONSTANT_SIZE(CONSTANT_SIZE),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE)
  ) springs_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .k(springs_k),
    .b(springs_b),
    .input_valid(begin_springs),
    .nodes(nodes),
    .velocities(velocities),
    .springs(springs),
    .equilibriums(equilibriums),
    .spring_force_x(springs_force_x),
    .spring_force_y(springs_force_y),
    .spring_force_valid(springs_force_valid),
    .output_valid(springs_done)
  );

  logic signed [VELOCITY_SIZE-1:0] com_velocity [1:0];
  assign com_velocity[0] = 0;
  assign com_velocity[1] = 0;

  // Instantiate the ideal module
  ideal #(
    .NUM_NODES(NUM_NODES),
    .CONSTANT_SIZE(CONSTANT_SIZE),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE)
  ) ideal_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .input_valid(begin_ideal),
    .k(ideal_k),
    .b(ideal_b),
    .axle(com),
    .axle_velocity(com_velocity),
    .nodes(nodes),
    .ideal(ideal),
    .velocities(velocities),
    .force_x_out(ideal_force_x),
    .force_y_out(ideal_force_y),
    .force_out_valid(ideal_force_valid),
    //.axle_force_x(axle_force_x),
    //.axle_force_y(axle_force_y),
    .output_valid(ideal_done)
  );



//do gravity here
logic [FORCE_SIZE-1:0] gravity_force;
assign gravity_force = GRAVITY;

/*states will be attached to lights for debugging
bit  value
0-2    state
3-5    forces_ready
  3      springs_force
  4      ideal_force
*/


always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin

            result_out <= 0;
            node_out_done <= 0;
            if (begin_in == 1) begin
                state <= COLLISIONS;
                begin_collisions <= 1;
                collision_node <= 1;
                //add gravity to total forces
                for (integer i = 0; i< NUM_NODES; i = i + 1) begin
                  total_forces[0][i] <= gravity_force;
                  total_forces[1][i] <= gravity_force;
                end

                point_pos_x <= nodes_in[0][0];
                point_pos_y <= nodes_in[1][0];
                point_vel_x <= velocities_in[0][0];
                point_vel_y <= velocities_in[1][0];
            end else begin
              begin_collisions <= 0;
            end
        end
        COLLISIONS: begin
          begin_collisions <= 0;

          if (collision_force_valid == 1) begin
            //positions won't change more this time step, so output node positions.
            node_out_x <= point_new_pos_x;
            node_out_y <= point_new_pos_y;
            node_out_valid <= 1;

            if (collision_node == 0) begin
                laxle[0] <= point_new_pos_x;
                laxle[1] <= point_new_pos_y;
                laxle_velocity[0] <= point_new_vel_x;
                laxle_velocity[1] <= point_new_vel_y;
                laxle_valid <= 1;
            end else begin
              laxle_valid <= 0;
            end

            if (collision_node == 2) begin
                raxle[0] <= point_new_pos_x;
                raxle[1] <= point_new_pos_y;
                raxle_velocity[0] <= point_new_vel_x;
                raxle_velocity[1] <= point_new_vel_y;
                raxle_valid <= 1;
            end else begin
              raxle_valid <= 0;
            end


            nodes[0][collision_node -1] <= point_new_pos_x;
            nodes[1][collision_node -1] <= point_new_pos_y;
            velocities[0][collision_node -1] <= point_new_vel_x;
            velocities[1][collision_node -1] <= point_new_vel_y;

            total_forces[0][collision_node-1] <= total_forces[0][collision_node-1] + point_force_x;
            total_forces[1][collision_node-1] <= total_forces[1][collision_node-1] + point_force_y;

            if (collision_node == NUM_NODES) begin
              state <= FORCES;
              node_out_done <= 1;
              begin_springs <= 1;
              begin_ideal <= 1;
              begin_com <= 1;
              springs_force_count <= 0;
              ideal_force_count <= 0;
            end else begin
              begin_collisions <= 1;
              collision_node <= collision_node + 1;
              //add forces to total forces
              //update positions and velocities
              point_pos_x <= nodes_in[0][collision_node];
              point_pos_y <= nodes_in[1][collision_node];
              point_vel_x <= velocities_in[0][collision_node];
              point_vel_y <= velocities_in[1][collision_node];
            end

          end else begin
            begin_collisions <= 0;
            node_out_valid <= 0;
          end
        end
        FORCES: begin
            node_out_done <= 0;
            node_out_valid <= 0;
            begin_springs <= 0;
            begin_ideal <= 0;
            begin_com <= 0;
            if (springs_force_valid == 1) begin
              springs_force_count <= springs_force_count + 1;
              springs_forces[0][springs_force_count] <= springs_force_x;
              springs_forces[1][springs_force_count] <= springs_force_y;
            end

            if (ideal_force_valid == 1) begin
              ideal_force_count <= ideal_force_count + 1;
              ideal_forces[0][ideal_force_count] <= ideal_force_x;
              ideal_forces[1][ideal_force_count] <= ideal_force_y;
            end


            if (springs_done == 1) begin
                forces_ready[0] <= 1;
            end
            if (ideal_done == 1) begin
                forces_ready[1] <= 1;
            end

            if (laxle_force_valid) begin
              total_forces[0][0] <= total_forces[0][0] + laxle_force_x;
              total_forces[1][0] <= total_forces[1][0] + laxle_force_y;
              forces_ready[2] <= 1;
            end
            
            if (raxle_force_valid) begin
              total_forces[0][0] <= total_forces[0][0] + raxle_force_x;
              total_forces[1][0] <= total_forces[1][0] + raxle_force_y;
              forces_ready[3] <= 1;
            end
            


            if (forces_ready == 4'b1111) begin
              //genvar i;
              //generate
                for (integer i = 0; i< NUM_NODES; i = i + 1) begin
                  total_forces[0][i] <= total_forces[0][i] + springs_forces[0][i] + ideal_forces[0][i];
                  total_forces[1][i] <= total_forces[1][i] + springs_forces[1][i] + ideal_forces[1][i];
                end
                
              //endgenerate
              state <= VELOCITY;

            end
        end
        VELOCITY: begin
            //do this for every point
            //new_vel_x <= new_vel_x + acceleration_x * DT;
            ///new_vel_y <= new_vel_y + acceleration_y * DT;
            for (integer i = 0; i< NUM_NODES; i = i + 1) begin
              velocities[0][i] <= velocities[0][i] + (total_forces[0][i] >>> DT);// * DT;//add divide by mass later
              velocities[1][i] <= velocities[1][i] + (total_forces[1][i] >>> DT);// * DT; 
            end
            velocity_out_num <= 0;


            //endgenerate
            //if (com_done) begin
                //state <= RESULT;
            //end
            state <= RESULT;
        end
        RESULT: begin
          velocity_out_num <= velocity_out_num + 1;
          if (velocity_out_num == NUM_NODES) begin
            result_out <= 1;
            state <= IDLE;
            velocity_out_valid <= 0;
            forces_ready <= 0;
          end else begin
            
            velocity_out_x <= velocities[0][velocity_out_num];
            velocity_out_y <= velocities[1][velocity_out_num];
            velocity_out_valid <= 1;

          end
        end


    endcase


end

endmodule

  