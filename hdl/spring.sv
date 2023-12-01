module spring #(POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  //input  wire input_valid,
  input  wire signed [FORCE_SIZE-1:0] k,
  input  wire signed [FORCE_SIZE-1:0] b,
  input  wire signed [POSITION_SIZE-1:0] v1 [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2 [1:0],
  input  wire signed [VELOCITY_SIZE-1:0] vel1_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel1_y,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_y,
  output logic signed [FORCE_SIZE - 1:0] force_x,
  output logic signed [FORCE_SIZE - 1:0] force_y
  
);

always_comb begin
    force_x = (~(v2[0] - v1[0]) + 1) * k - (vel2_x - vel1_x)  * b;
    force_y = (~(v2[1] - v1[1]) + 1) * k - (vel2_y - vel1_y)  * b;
end

endmodule