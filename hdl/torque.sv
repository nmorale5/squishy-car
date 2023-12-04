module torque #(NUM_NODES = 10, POSITION_SIZE=8, FORCE_SIZE=8, TORQUE=4)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire signed [2:0] drive,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] axle [1:0], 
  output logic signed [FORCE_SIZE-1:0] torque_forces [1:0][NUM_NODES],
  output logic result_out

);

//axle will be center of ideal shape and ideal will pull wheel towards axle
//alternately, the forces on the axle are all added to the forces on the wheel

//force needs to go in direction perpendicular the line connecting the point
//and the axle

always_comb begin
  integer i;

  //generate
    for (i = 0; i< NUM_NODES; i = i + 1) begin
      torque_forces[0][i] = (axle[1] - nodes[1][i]) * drive * TORQUE;
      torque_forces[1][i] = (nodes[0][i] - axle[0]) * drive * TORQUE;
    end
  //endgenerate
end

always_ff @(posedge clk_in) begin
  if (begin_in) begin
    result_out <= 1;
  end else begin
    result_out <= 0;
  end

end



endmodule