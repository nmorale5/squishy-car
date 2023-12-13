module spring #(CONSTANT_SIZE, POSITION_SIZE, VELOCITY_SIZE, FORCE_SIZE)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [CONSTANT_SIZE-1:0] k,
  input  wire signed [CONSTANT_SIZE-1:0] b,
  input  wire signed [POSITION_SIZE-1:0] v1 [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2 [1:0],
  input  wire signed [POSITION_SIZE-1:0] equilibrium,
  input  wire signed [VELOCITY_SIZE-1:0] vel1_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel1_y,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_y,
  output logic signed [FORCE_SIZE - 1:0] force_x,
  output logic signed [FORCE_SIZE - 1:0] force_y,
  output logic result_valid
  
  
);
//calcultes the force from the spring on the SECOND point.
  logic divider_valid_x, divider_valid_y;
  logic [FORCE_SIZE +1 -1:0] x_quotient, y_quotient;
  logic sqrt_start, sqrt_valid; 
  logic [2 * POSITION_SIZE + 3 - 1:0] x_dividend, y_dividend, distance, distance_squared;

  assign distance_squared = (v2[0] - v1[0]) * (v2[0] - v1[0]) + (v2[1] - v1[1]) * (v2[1] - v1[1]);
  assign x_dividend = (distance - equilibrium) * (v2[0] - v1[0]);
  assign y_dividend = (distance - equilibrium) * (v2[1] - v1[1]);

  logic [1:0] divider_valids;
  logic begin_divider;
  
  divider #(.WIDTH(2 * POSITION_SIZE + 3), .OUT_SIZE(FORCE_SIZE + 1)) x_divider (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .dividend_in(x_dividend),
    .divisor_in(distance),
    .data_valid_in(begin_divider),
    .quotient_out(x_quotient),
    .data_valid_out(divider_valid_x)
  );	

  divider #(.WIDTH(2 * POSITION_SIZE + 3), .OUT_SIZE(FORCE_SIZE + 1)) y_divider (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .dividend_in(y_dividend),
    .divisor_in(distance),
    .data_valid_in(begin_divider),
    .quotient_out(y_quotient),
    .data_valid_out(divider_valid_y)
  );	

  typedef enum {IDLE = 0, DISTANCE = 1, DIVIDE = 2, FORCE=3} spring_state;
  spring_state state = IDLE;


  sqrt #(2 * POSITION_SIZE + 3) sqrt_instance (
    .clk_in(clk_in),
    .x(distance_squared),
    .valid_in(sqrt_start),
    .sqrt_x(distance),
    .result_valid(sqrt_valid)
  );

//need to subtract the equilibrium length from the vector
//only way to do this is with a square root it seems.
//for testing 
/*
logic [3 * POSITION_SIZE:0] t1, t2;
assign t1 = (v2[0] - v1[0]) * (v2[0] - v1[0]);
assign t2 = (v2[1] - v1[1]);
*/
//done testing



always_ff @(posedge clk_in) begin
    case (state)
      IDLE: begin
        result_valid <= 0;
        if (input_valid) begin
          state <= DISTANCE;
          sqrt_start <= 1;
          divider_valids[0] <= 0;
          divider_valids[1] <= 0;
        end
      end
      DISTANCE: begin
        sqrt_start <= 0;
        if (sqrt_valid) begin
          state <= DIVIDE;
          begin_divider <= 1;
        end
      end
      DIVIDE: begin
        begin_divider <= 0;
        if (divider_valid_x) begin
          divider_valids[0] <= 1;
        end
        if (divider_valid_y) begin
          divider_valids[1] <= 1;
        end

        if (divider_valids == 2'b11) begin
          state <= FORCE;
        end
      end
      FORCE: begin
        force_x <= (~x_quotient +1) * k - (vel2_x - vel1_x)  * b;
        force_y <= (~y_quotient+1) * k - (vel2_y - vel1_y)  * b;
        result_valid <= 1;
        state <= IDLE;
      end
    endcase

end



endmodule