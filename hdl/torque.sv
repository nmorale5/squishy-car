module torque #(NUM_NODES = 10, POSITION_SIZE=8, FORCE_SIZE=8, TORQUE=1)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire signed [2:0] drive,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire signed [POSITION_SIZE-1:0] axle [1:0], 
  output logic signed [FORCE_SIZE-1:0] force_x_out,
  output logic signed [FORCE_SIZE-1:0] force_y_out,
  output logic force_out_valid,
  output logic result_out

);

//axle will be center of ideal shape and ideal will pull wheel towards axle
//alternately, the forces on the axle are all added to the forces on the wheel

//force needs to go in direction perpendicular the line connecting the point
//and the axle
typedef enum {IDLE = 0, RESULT=1} torque_state;
torque_state state = IDLE;

logic [$clog2(NUM_NODES):0] current_node;



always_ff @(posedge clk_in) begin
  case(state)
    IDLE: begin
      result_out <= 0;
      if (begin_in) begin
        state <= RESULT;
        current_node <= 0;
      end 
    end
    RESULT: begin
      if (current_node == NUM_NODES) begin
        state <= IDLE;
        result_out <= 1;
        force_out_valid <= 0;
      end else begin
        current_node <= current_node + 1;
        force_x_out <= ((axle[1] - nodes[1][current_node]) * drive) << TORQUE;
        force_y_out <= ((nodes[0][current_node] - axle[0]) * drive) << TORQUE;
        force_out_valid <= 1;
      end
    end
  endcase

end



endmodule