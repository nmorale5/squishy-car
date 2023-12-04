
module ideal_springs #(NUM_NODES = 10, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] ideal_nodes [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] axle_velocity [1:0],
  output logic signed [FORCE_SIZE-1:0] spring_forces [1:0][NUM_NODES],
  output logic signed [FORCE_SIZE-1:0] axle_force [1:0],
  output logic output_valid
  
);

typedef enum {IDLE = 0, CALCULATE = 1, RESULT = 2} springs_state;

springs_state state = IDLE;
logic signed [FORCE_SIZE-1:0] k;
logic signed [FORCE_SIZE-1:0] b;
logic signed [POSITION_SIZE-1:0] v1 [1:0];
logic signed [POSITION_SIZE-1:0] v2 [1:0];
logic signed [VELOCITY_SIZE-1:0] vel1_x;
logic signed [VELOCITY_SIZE-1:0] vel1_y;
logic signed [VELOCITY_SIZE-1:0] vel2_x;
logic signed [VELOCITY_SIZE-1:0] vel2_y;
logic signed [FORCE_SIZE - 1:0] force_x;
logic signed [FORCE_SIZE - 1:0] force_y;
logic [$clog2(NUM_NODES):0] current_spring;
 

spring #(POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE) spring_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .k(k),
    .b(b),
    .v1(v1),
    .v2(v2),
    .vel1_x(vel1_x),
    .vel1_y(vel1_y),
    .vel2_x(vel2_x),
    .vel2_y(vel2_y),
    .force_x(force_x),
    .force_y(force_y)
  );

assign k = 5;
assign b = 1;
logic [$clog2(NUM_NODES)-1:0] current_node;
//springs: list of indeces of nodes connected by a spring
//ex) [(3,1),(5,7),(8,9)]
//logic [FORCE_SIZE-1:0] spring_forces [NUM_SPRINGS];
always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin
          output_valid <= 0;
          current_spring <= 1;
          if (input_valid == 1) begin
            axle_force[0] <= 0;
            axle_force[1] <= 0;
            state <= CALCULATE;
            v1[0] <= nodes[0][0];
            v1[1] <= nodes[1][0];
            v2[0] <= ideal_nodes[0][0];
            v2[1] <= ideal_nodes[1][0];

            vel1_x <= velocities[0][0];
            vel1_y <= velocities[1][0];
            vel2_x <= axle_velocity[0];
            vel2_y <= axle_velocity[1];
          end
        end
        CALCULATE: begin
          current_spring <= current_spring + 1;
          if (current_spring == NUM_NODES) begin
            state <= RESULT;
          end else begin
            spring_forces[0][current_spring-1] <= force_x;
            spring_forces[1][current_spring-1] <= force_y;
            axle_force[0] <= axle_force[0] - force_x;
            axle_force[1] <= axle_force[1] - force_y;

            v1[0] <= nodes[0][current_spring];
            v1[1] <= nodes[1][current_spring];
            v2[0] <= ideal_nodes[0][current_spring];
            v2[1] <= ideal_nodes[1][current_spring];

            vel1_x <= velocities[0][current_spring];
            vel1_y <= velocities[1][current_spring];
          end
        end
        RESULT: begin
          state <= IDLE;
          output_valid <= 1;
        end

    endcase

end

endmodule







        
