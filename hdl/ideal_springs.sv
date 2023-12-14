
module ideal_springs #(NUM_NODES = 10, CONSTANT_SIZE =4, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [CONSTANT_SIZE-1:0] k,
  input  wire signed [CONSTANT_SIZE-1:0] b,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] ideal_nodes [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] axle_velocity [1:0],
  output logic signed [FORCE_SIZE-1:0] force_x_out,
  output logic signed [FORCE_SIZE-1:0] force_y_out,
  output logic force_out_valid,
  output logic signed [FORCE_SIZE-1:0] axle_force_x,
  output logic signed [FORCE_SIZE-1:0] axle_force_y,
  output logic output_valid
  
);

typedef enum {IDLE = 0, CALCULATE = 1, RESULT = 2, MULTIPLY=3} springs_state;

springs_state state = IDLE;
logic signed [POSITION_SIZE-1:0] v1 [1:0];
logic signed [POSITION_SIZE-1:0] v2 [1:0];
logic signed [VELOCITY_SIZE-1:0] vel1_x;
logic signed [VELOCITY_SIZE-1:0] vel1_y;
//logic signed [VELOCITY_SIZE-1:0] vel2_x;
//logic signed [VELOCITY_SIZE-1:0] vel2_y;
logic signed [FORCE_SIZE - 1:0] force_x;
logic signed [FORCE_SIZE - 1:0] force_y;
logic [$clog2(NUM_NODES):0] current_spring;

assign force_x = ((v2[0] - v1[0]) <<< k) - (vel1_x <<< b);
assign force_y = ((v2[1] - v1[1]) <<< k) - (vel1_y <<< b);

//springs: list of indeces of nodes connected by a spring
//ex) [(3,1),(5,7),(8,9)]
//logic [FORCE_SIZE-1:0] spring_forces [NUM_SPRINGS];
always_ff @(posedge clk_in) begin
  if (rst_in) begin
    axle_force_x <= 0;
    axle_force_y <= 0;
  end else begin
    case(state)
        IDLE: begin
          output_valid <= 0;
          current_spring <= 1;
          if (input_valid == 1) begin
            axle_force_x <= 0;
            axle_force_y <= 0;
            state <= CALCULATE;

            v1[0] <= nodes[0][0];
            v1[1] <= nodes[1][0];
            v2[0] <= ideal_nodes[0][0];
            v2[1] <= ideal_nodes[1][0];

            vel1_x <= velocities[0][0];
            vel1_y <= velocities[1][0];
          end
        end
        CALCULATE: begin
          force_x_out <= force_x;
          force_y_out <= force_y;
          force_out_valid <= 1;
          axle_force_x <= axle_force_x - force_x;
          axle_force_y <= axle_force_y - force_y;

          if (current_spring == NUM_NODES) begin
            state <= RESULT;
          end else begin
            v1[0] <= nodes[0][current_spring];
            v1[1] <= nodes[1][current_spring];
            v2[0] <= ideal_nodes[0][current_spring];
            v2[1] <= ideal_nodes[1][current_spring];

            vel1_x <= velocities[0][current_spring];
            vel1_y <= velocities[1][current_spring];

            current_spring <= current_spring + 1;
          end
        end
        RESULT: begin
          force_out_valid <= 0;
          state <= IDLE;
          output_valid <= 1;
        end

    endcase
  end

end

endmodule







        
