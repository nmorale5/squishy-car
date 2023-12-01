module ideal #(NUM_NODES = 10, POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input wire [POSITION_SIZE-1:0] com_x,
  input wire [POSITION_SIZE-1:0] com_y,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] ideal [1:0][NUM_NODES],
  input  wire signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES],
  output logic signed [FORCE_SIZE-1:0] ideal_forces [1:0][NUM_NODES],
  output logic output_valid
  
);




typedef enum {IDLE = 0, CALCULATE = 1, RESULT = 2} ideal_state;

  input  wire [$clog2(NUM_NODES)-1:0] springs [1:0][NUM_SPRINGS],

logic signed [FORCE_SIZE-1:0] k;
logic signed [FORCE_SIZE-1:0] b;

assign k = 5;
assign b = 1;

assign cross_product = actual_node[0] * ideal_node[1] - actual_node[1] * ideal_node[0];
assign dot_product = actual_node[0] * ideal_node[0] + actual_node[1] * ideal_node[1];
logic [$clog2(NUM_NODES)-1:0] current_node;
//calculate tan(theta), rotate, springs
always_ff @(posedge clk_in) begin
    case(state)
        IDLE: begin
        
          output_valid <= 1;
          if (input_valid == 1) begin
            state <= THETA
            current_node <= 1;
            cross_sum <= 0;
            dot_sum <= 0;
            actual_node[0] <= nodes[0][0];
            actual_node[1] <= nodes[1][0];
            ideal_node[0] <= ideal[0][1] + com_x;
            ideal_node[1] <= ideal[1][1] + com_y;

          end
        end
        THETA: begin
            current_node <= current_node + 1;
            if (current_node == NUM_NODES) begin
                state <= ROTATION;
            end else begin
                cross_sum <= cross_sum + cross_product;
                dot_sum <= dot_sum + dot_product;
                
                actual_node[0] <= nodes[0][current_node];
                actual_node[1] <= nodes[1][current_node];
                ideal_node[0] <= ideal[0][current_node] + com_x;
                ideal_node[1] <= ideal[1][current_node] + com_y;
            end
        end
        ROTATION: begin
            //rotate the ideal shape


        end
        SPRINGS:
            //apply the spring forces
        RESULT: begin
          state <= IDLE;
          output_valid <= 1;
        end

    endcase

end
endmodule


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