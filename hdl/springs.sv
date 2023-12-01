
module springs #(NUM_SPRINGS = 10, NUM_NODES = 10, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES],
  input  wire [$clog2(NUM_NODES)-1:0] springs [1:0][NUM_SPRINGS],
  output logic signed [FORCE_SIZE-1:0] spring_forces [1:0][NUM_NODES],
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
logic [$clog2(NUM_SPRINGS)-1:0] current_spring;
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
assign node1 = springs[0][current_spring];
assign node2 = springs[1][current_spring];
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
            
            state <= CALCULATE;
            v1[0] <= nodes[0][node1];
            v1[1] <= nodes[1][node1];
            v2[0] <= nodes[0][node2];
            v2[1] <= nodes[1][node2];

            vel1_x <= velocities[0][node1];
            vel1_y <= velocities[1][node1];
            vel2_x <= velocities[0][node2];
            vel2_y <= velocities[1][node2];
          end
        end
        CALCULATE: begin
          current_spring <= current_spring + 1;
          if (current_spring == NUM_SPRINGS) begin
            state <= RESULT;
          end else begin
            spring_forces[0][springs[0][current_spring-1]] <= spring_forces[0][springs[0][current_spring-1]] + force_x;
            spring_forces[1][springs[0][current_spring-1]] <= spring_forces[1][springs[0][current_spring-1]] + force_y;
            spring_forces[0][springs[1][current_spring-1]] <= spring_forces[0][springs[1][current_spring-1]] - force_x;
            spring_forces[1][springs[1][current_spring-1]] <= spring_forces[1][springs[1][current_spring-1]] - force_y;

            v1[0] <= nodes[0][node1];
            v1[1] <= nodes[1][node1];
            v2[0] <= nodes[0][node2];
            v2[1] <= nodes[1][node2];

            vel1_x <= velocities[0][node1];
            vel1_y <= velocities[1][node1];
            vel2_x <= velocities[0][node2];
            vel2_y <= velocities[1][node2];
          end
        end
        RESULT: begin
          state <= IDLE;
          output_valid <= 1;
        end

    endcase

end

endmodule







        
