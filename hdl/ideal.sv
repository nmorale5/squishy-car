module ideal #(NUM_NODES = 10, CONSTANT_SIZE, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [CONSTANT_SIZE-1:0] k,
  input  wire signed [CONSTANT_SIZE-1:0] b,
  input  wire signed [POSITION_SIZE-1:0] axle [1:0],
  input  wire signed [VELOCITY_SIZE-1:0] axle_velocity [1:0],
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] ideal [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES],
  output logic signed [FORCE_SIZE-1:0] force_x_out,
  output logic signed [FORCE_SIZE-1:0] force_y_out,
  output logic force_out_valid,
  output logic signed [FORCE_SIZE-1:0] axle_force_x,
  output logic signed [FORCE_SIZE-1:0] axle_force_y,
  output logic output_valid
  
);

//logic signed [FORCE_SIZE-1:0] spring_forces [1:0][NUM_NODES];
logic signed [FORCE_SIZE-1:0] spring_force_x;
logic signed [FORCE_SIZE-1:0] spring_force_y;
logic begin_springs, springs_done;
logic [$clog2(NUM_NODES)-1:0] springs [1:0][NUM_NODES];
logic signed [POSITION_SIZE-1:0] rotated_ideal [1:0][NUM_NODES];
logic signed [FORCE_SIZE-1:0] ideal_forces [1:0][NUM_NODES];
logic springs_force_valid;



//might have force go the opposite way
ideal_springs #(NUM_NODES, CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE) springs_instance (
  .clk_in(clk_in),
  .rst_in(rst_in),
  .input_valid(begin_springs),
  .k(k),
  .b(b),
  .nodes(nodes),
  .ideal_nodes(rotated_ideal),
  .velocities(velocities),
  .axle_velocity(axle_velocity),
  .force_y_out(spring_force_x),
  .force_x_out(spring_force_y),
  .force_out_valid(springs_force_valid),
  .axle_force_x(axle_force_x),
  .axle_force_y(axle_force_y),
  .output_valid(springs_done)
);

typedef enum {IDLE = 0, THETA = 1, ROTATION = 2, SPRINGS = 3, RESULT=4} ideal_state;
ideal_state state = IDLE;
logic [POSITION_SIZE-1:0] actual_node;
logic [POSITION_SIZE-1:0] ideal_node;
logic [POSITION_SIZE * NUM_NODES-1:0] cross_sum; //fix size later
logic [POSITION_SIZE * NUM_NODES-1:0] dot_sum; //fix size later
logic [2 * POSITION_SIZE+1-1:0] cross_product, dot_product;

//assign cross_product = actual_node[0] * ideal_node[1] - actual_node[1] * ideal_node[0];
//assign dot_product = actual_node[0] * ideal_node[0] + actual_node[1] * ideal_node[1];
logic [$clog2(NUM_NODES):0] current_node;

//for testing
logic [POSITION_SIZE-1:0] ax, ay, bx, by;
assign ax = actual_node[0];
assign ay = actual_node[1];
assign bx = nodes[0][3];
assign by = nodes[1][3];
assign rotated_ideal = ideal;

//calculate tan(theta), rotate, springs
always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin
        
          output_valid <= 0;
          if (input_valid == 1) begin
            state <= THETA;
            current_node <= 1;
            cross_sum <= 0;
            dot_sum <= 0;
            actual_node[0] <= nodes[0][0];
            actual_node[1] <= nodes[1][0];
            ideal_node[0] <= ideal[0][1] + axle[0];
            ideal_node[1] <= ideal[1][1] + axle[1];

          end
        end
        /*
        MULTIPLY: begin
          mult_count <= mult_count + 1;
          case (mult_count)

          endcase 

        end */
        THETA: begin
          state <= ROTATION;

            /*
            current_node <= current_node + 1;
            if (current_node == NUM_NODES) begin
                state <= ROTATION;
            end else begin
                cross_sum <= cross_sum + cross_product;
                dot_sum <= dot_sum + dot_product;
                
                actual_node[0] <= nodes[0][current_node];
                actual_node[1] <= nodes[1][current_node];
                ideal_node[0] <= ideal[0][current_node] + axle[0];
                ideal_node[1] <= ideal[1][current_node] + axle[1];
                state <= MULTIPLY;
            end
            */

        end
        ROTATION: begin
            //rotate the ideal shape
            state <= SPRINGS;
            begin_springs <= 1;


        end
        SPRINGS: begin
            //apply the spring forces with ideal shifted to axle position
            //ideal should have a com of 0
            if (springs_force_valid == 1) begin
              force_x_out <= spring_force_x;
              force_y_out <= spring_force_y;
              force_out_valid <= 1;
            end else begin
              force_out_valid <= 0;
            end
            
            begin_springs <= 0;
            if (springs_done) begin
              state <= RESULT;
            end

        end
        RESULT: begin
            output_valid <= 1;
            state <= IDLE;
        end

    endcase

end
endmodule

/*
module InverseSqrtInteger (
  input wire signed [WIDTH-1:0] x,
  output wire signed [WIDTH-1:0] result
);

  // Constants
  parameter WIDTH = 32;
  localparam EXPONENT_BITS = 8;

  // Fixed-point representation
  wire signed [2*WIDTH+EXPONENT_BITS-1:0] fixed_x = {x, {EXPONENT_BITS{1'b0}}};

  // Calculate magnitude squared
  wire signed [2*WIDTH+EXPONENT_BITS-1:0] magnitude_squared = fixed_x * fixed_x;

  // Fast inverse square root algorithm
  wire signed [WIDTH+EXPONENT_BITS-1:0] fast_inverse_sqrt;
  assign fast_inverse_sqrt = $signed({WIDTH+EXPONENT_BITS{1'b0}}, EXPONENT_BITS'b0111111111111111) - (magnitude_squared >> 1);

  // Result
  assign result = fast_inverse_sqrt;

endmodule


module find_theta #(NUM_NODES = 10, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] ideal [1:0][NUM_NODES],
  output logic output_valid
  
);

always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin
          output_valid <= 0;
          if (input_valid == 1) begin
            state <= THETA
            current_node <= 0;
            node1[0] <= nodes[0][current_node];
            node1[1] <= nodes[1][current_node];
            node2[0] <= nodes[0][current_node+1];
            node2[1] <= nodes[1][current_node+1];
          end
        end
        THETA: begin
          
          current_node
          current_spring <= current_spring + 1;

        end
        RESULT: begin
          state <= IDLE;
          output_valid <= 1;
        end

    endcase

end

endmodule
*/