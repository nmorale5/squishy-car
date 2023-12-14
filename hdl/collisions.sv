module collisions #(DT = 1, POSITION_SIZE=8, VELOCITY_SIZE=7, FORCE_SIZE =8, NUM_VERTICES=5, NUM_OBSTACLES=5)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire signed [POSITION_SIZE-1:0] obstacles_in [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [$clog2(NUM_VERTICES):0] all_num_vertices_in [NUM_OBSTACLES], //array of num_vertices
  input  wire [$clog2(NUM_OBSTACLES):0] num_obstacles_in,
  input  wire signed [POSITION_SIZE-1:0] pos_x_in,
  input  wire signed [POSITION_SIZE-1:0] pos_y_in,
  input  wire signed [VELOCITY_SIZE-1:0] vel_x_in,
  input  wire signed [VELOCITY_SIZE-1:0] vel_y_in,
  output logic signed [POSITION_SIZE-1:0] new_pos_x,
  output logic signed [POSITION_SIZE-1:0] new_pos_y,
  output logic signed [VELOCITY_SIZE-1:0] new_vel_x,
  output logic signed [VELOCITY_SIZE-1:0] new_vel_y,
  output logic signed [FORCE_SIZE-1:0] force_x_out,
  output logic signed [FORCE_SIZE-1:0] force_y_out,
  output logic result_out
);

  typedef enum {IDLE = 0, COLLISIONS = 1, RESULT = 2} update_state;

  update_state state = IDLE;

  //logic signed [FORCE_SIZE - 1:0] force_x, force_y;
  logic signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES]; //array of num_vertices
  logic [$clog2(NUM_OBSTACLES):0] num_obstacles;

  logic  signed [POSITION_SIZE-1:0] pos_x, pos_y;
  logic  signed [VELOCITY_SIZE-1:0] vel_x, vel_y;

  logic is_collision;
  logic signed [POSITION_SIZE-1:0] dx, dy;
  logic [$clog2(NUM_VERTICES):0] num_vertices;
  logic signed [POSITION_SIZE-1:0] x_new,y_new, x_int, y_int;
  logic signed [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES];
  logic was_collision, begin_do;
  logic any_collision;

  localparam OBSTACLE_COUNT_SIZE = 4;//$clog(NUM_OBSTACLES);
  logic [OBSTACLE_COUNT_SIZE-1:0] obstacle_num, last_obstacle_num;
  logic [OBSTACLE_COUNT_SIZE-1:0] collision_obstacle;
  logic signed [VELOCITY_SIZE-1:0] vx_new, vy_new;
  logic signed [FORCE_SIZE-1:0] force_x, force_y;
  logic signed [FORCE_SIZE-1:0] coll_force_x, coll_force_y;
  logic collision_result;

  //for testing
  logic collision_detected;
  logic coll_else;

do_collision #(DT, POSITION_SIZE,VELOCITY_SIZE, FORCE_SIZE, NUM_VERTICES) collision_doer (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_do),
    .obstacle_in(obstacle),
    .num_vertices(num_vertices),
    .pos_x_in(pos_x),
    .pos_y_in(pos_y),
    .vel_x_in(vel_x),
    .vel_y_in(vel_y),
	.dx_in(dx),
	.dy_in(dy),
    .result_out(collision_result),
    .x_new(x_new),
    .y_new(y_new),
	.vel_x_new(vx_new),
	.vel_y_new(vy_new),
	.x_int_out(x_int),
	.y_int_out(y_int),
	.acceleration_x(coll_force_x),
    .acceleration_y(coll_force_y),
	.was_collision(was_collision)
  );

  always_ff @(posedge clk_in) begin
	
	if (rst_in == 1) begin
		state <= IDLE;
	end else begin
		case (state)
			IDLE: begin
				any_collision <= 0;
				begin_do <= 0;
				result_out <= 0;
				if (begin_in == 1) begin
					state <= COLLISIONS;
					begin_do <= 1; //start the doer module					
	
					//collision variables initialization
					pos_x <= pos_x_in;
					pos_y <= pos_y_in;
					vel_x <= vel_x_in;
					vel_y <= vel_y_in;
					dx <= vel_x_in; //* DT;
					dy <= vel_y_in; //* DT;
					force_x <= 0;
					force_y <= 0;

					//store num information

					for (int i = 0; i < NUM_OBSTACLES; i = i + 1) begin
						all_num_vertices[i] <= all_num_vertices_in[i];
  					end
					//grab first obstacle
					for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
						obstacle[0][i] <= obstacles_in[0][i][0];
						obstacle[1][i] <= obstacles_in[1][i][0];
  					end
					num_obstacles <= num_obstacles_in;
				    num_vertices <= all_num_vertices_in[0];
					collision_obstacle <= 0;
					last_obstacle_num <= 0;
					obstacle_num <= 1;

					new_pos_x <= pos_x_in + vel_x_in; //* DT;
					new_pos_y <= pos_y_in + vel_y_in; //* DT;
					new_vel_x <= vel_x_in;
					new_vel_y <= vel_y_in;
				end
			end
			COLLISIONS: begin
				if (collision_result == 1) begin
					if (was_collision == 1) begin
						collision_obstacle <= last_obstacle_num;
						force_x <= force_x + coll_force_x;
						force_y <= force_y + coll_force_y;
						//set module outputs if this is the last collision
						new_pos_x <= x_new;
						new_pos_y <= y_new;
						new_vel_x <= vx_new;
						new_vel_y <= vy_new;
						any_collision <= 1;
					end
	
					if ((num_obstacles == 1) | (was_collision == 0 & obstacle_num == collision_obstacle)) begin
						//got through all obstacles without collision
						state <= RESULT;

					end else begin
						coll_else <= 1;
						begin_do <= 1;
						obstacle_num <= (obstacle_num >= num_obstacles-1)?0:obstacle_num + 1; //>= is for one obstacle
						last_obstacle_num <= obstacle_num;
						if (was_collision == 1) begin
							//inputs for next collision check
							pos_x <= x_int;
							pos_y <= y_int;
							vel_x <= vx_new;
							vel_y <= vx_new;
							dx <= x_new - x_int;
							dy <= y_new - y_int;
						end else begin
							collision_detected <= 0;
						end

						for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
							obstacle[0][i] <= obstacles_in[0][i][obstacle_num];
							obstacle[1][i] <= obstacles_in[1][i][obstacle_num];
						end
						num_vertices <= all_num_vertices[obstacle_num];
					end
				end else begin
					begin_do <= 0;
				end
			end
			RESULT: begin
				state <= IDLE;
				result_out <= 1;
				force_x_out <= force_x;
				force_y_out <= force_y;
			end
		endcase
	end
  end

endmodule