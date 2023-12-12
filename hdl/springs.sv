
module springs #(NUM_SPRINGS, NUM_NODES, CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire [CONSTANT_SIZE-1:0] k,
  input  wire [CONSTANT_SIZE-1:0] b,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES],
  input  wire [$clog2(NUM_NODES):0] springs [1:0][NUM_SPRINGS],
  input  wire [POSITION_SIZE-1:0] equilibriums [NUM_SPRINGS],
  output logic signed [FORCE_SIZE-1:0] spring_force_x,
  output logic signed [FORCE_SIZE-1:0] spring_force_y,
  output logic spring_force_valid,
  output logic output_valid
  
);


logic [FORCE_SIZE-1:0] spring_forces [1:0] [NUM_NODES];
logic [$clog2(NUM_NODES):0] spring_out_num;

typedef enum {IDLE = 0, CALCULATE = 1, RESULT = 2} springs_state;

springs_state state = IDLE;
logic signed [POSITION_SIZE-1:0] v1 [1:0];
logic signed [POSITION_SIZE-1:0] v2 [1:0];
logic signed [VELOCITY_SIZE-1:0] vel1_x;
logic signed [VELOCITY_SIZE-1:0] vel1_y;
logic signed [VELOCITY_SIZE-1:0] vel2_x;
logic signed [VELOCITY_SIZE-1:0] vel2_y;
logic signed [FORCE_SIZE - 1:0] force_x;
logic signed [FORCE_SIZE - 1:0] force_y;
logic [POSITION_SIZE-1:0] equilibrium;
logic [$clog2(NUM_SPRINGS):0] current_spring;
logic begin_spring, spring_valid;

spring #(CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE) spring_instance (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .input_valid(begin_spring),
    .k(k),
    .b(b),
    .v1(v1),
    .v2(v2),
    .equilibrium(equilibrium),
    .vel1_x(vel1_x),
    .vel1_y(vel1_y),
    .vel2_x(vel2_x),
    .vel2_y(vel2_y),
    .force_x(force_x),
    .force_y(force_y),
    .result_valid(spring_valid)
  );

logic [$clog2(NUM_NODES):0] node1,node2;

assign node1 = springs[0][current_spring];
assign node2 = springs[1][current_spring];
logic [$clog2(NUM_NODES)-1:0] current_node;

//for testing
logic [FORCE_SIZE-1:0] tf1, tf2;
logic [$clog2(NUM_SPRINGS):0] test_num;
assign test_num = 0;
assign tf1 = spring_forces[0][test_num];
assign tf2 = spring_forces[1][test_num];

//end testing

//springs: list of indeces of nodes connected by a spring
//ex) [(3,1),(5,7),(8,9)]
//logic [FORCE_SIZE-1:0] spring_forces [NUM_SPRINGS];
always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin
          output_valid <= 0;
          if (input_valid == 1) begin
            current_spring <= 1;
            state <= CALCULATE;
            v1[0] <= nodes[0][node1];
            v1[1] <= nodes[1][node1];
            v2[0] <= nodes[0][node2];
            v2[1] <= nodes[1][node2];

            vel1_x <= velocities[0][node1];
            vel1_y <= velocities[1][node1];
            vel2_x <= velocities[0][node2];
            vel2_y <= velocities[1][node2];

            for (int i = 0; i< NUM_NODES; i = i + 1) begin
              spring_forces[0][i] <= 0;
              spring_forces[1][i] <= 0;
            end

            equilibrium <= equilibriums[0];
            begin_spring <= 1;
          end else begin
            current_spring <= 0;
          end
        end
        CALCULATE: begin
          if (spring_valid) begin
            current_spring <= current_spring + 1;
            if (current_spring == NUM_SPRINGS) begin
              state <= RESULT;
              spring_out_num <= 0;
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

              equilibrium <= equilibriums[current_spring];
              begin_spring <= 1;
            end
          end else begin
            begin_spring <= 0;
          end
        end
        RESULT: begin
          spring_out_num <= spring_out_num + 1;
          if (spring_out_num == NUM_NODES) begin
            output_valid <= 1;
            state <= IDLE;
            spring_force_valid <= 0;
          end else begin
            spring_force_x <= spring_forces[0][spring_out_num];
            spring_force_y <= spring_forces[1][spring_out_num];
            spring_force_valid <= 1;

          end
        end

    endcase

end

endmodule







        
