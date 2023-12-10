`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module get_obstacles_on_screen # (
  parameter WORLD_BITS = 32,
  parameter MAX_NUM_VERTICES = 8,
  parameter MAX_OBSTACLES_ON_SCREEN = 16
) (
  input wire clk_in,
  input wire valid_in,
  input wire signed [WORLD_BITS-1:0] x_in,
  input wire signed [WORLD_BITS-1:0] y_in,
  input wire signed [WORLD_BITS-1:0] screen_min_x,
  input wire signed [WORLD_BITS-1:0] screen_max_x,
  input wire signed [WORLD_BITS-1:0] screen_min_y,
  input wire signed [WORLD_BITS-1:0] screen_max_y,
  input wire done_in,
  output logic signed [WORLD_BITS-1:0] obstacle_xs_out [MAX_OBSTACLES_ON_SCREEN] [MAX_NUM_VERTICES],
  output logic signed [WORLD_BITS-1:0] obstacle_ys_out [MAX_OBSTACLES_ON_SCREEN] [MAX_NUM_VERTICES],
  output logic [$clog2(MAX_NUM_VERTICES+1)-1:0] obstacles_num_sides_out [MAX_OBSTACLES_ON_SCREEN],
  output logic [$clog2(MAX_OBSTACLES_ON_SCREEN+1)-1:0] num_obstacles_out,
  output logic done_out
);

  logic [$clog2(MAX_OBSTACLES_ON_SCREEN+1)-1:0] curr_idx;
  logic prev_valid_in;
  logic signed [WORLD_BITS-1:0] cur_min_x, cur_max_x, cur_min_y, cur_max_y;

  always_ff @(posedge clk_in) begin
    if (done_in) begin
      num_obstacles_out <= curr_idx;
      curr_idx <= 0;
      done_out <= 1;
      cur_min_x <= (1 << (WORLD_BITS - 1)) - 1; // most positive number
      cur_max_x <=  1 << (WORLD_BITS - 1);      // most negative number
      cur_min_y <= (1 << (WORLD_BITS - 1)) - 1; // most positive number
      cur_max_y <=  1 << (WORLD_BITS - 1);      // most negative number
    end
    if (done_out) begin
      done_out <= 0;
    end
    if (valid_in) begin
      if (curr_idx < MAX_OBSTACLES_ON_SCREEN) begin
        cur_min_x <= x_in < cur_min_x ? x_in : cur_min_x;
        cur_max_x <= x_in > cur_max_x ? x_in : cur_max_x;
        cur_min_y <= y_in < cur_min_y ? y_in : cur_min_y;
        cur_max_y <= y_in > cur_max_y ? y_in : cur_max_y;
        if (prev_valid_in) begin
          obstacles_num_sides_out[curr_idx] <= obstacles_num_sides_out[curr_idx] + 1;
          obstacle_xs_out[curr_idx][obstacles_num_sides_out[curr_idx]] <= x_in;
          obstacle_ys_out[curr_idx][obstacles_num_sides_out[curr_idx]] <= y_in;
        end else begin
          obstacles_num_sides_out[curr_idx] <= 1;
          obstacle_xs_out[curr_idx][0] <= x_in;
          obstacle_ys_out[curr_idx][0] <= y_in;
        end
      end
      prev_valid_in <= 1;
    end else if (prev_valid_in) begin
       if (~( // this polygon is on screen iff the following are false:
        cur_max_x < screen_min_x || // the polygon is too far left
        cur_min_x > screen_max_x || // the polygon is too far right
        cur_max_y < screen_min_y || // the polygon is too far down
        cur_min_y > screen_max_y    // the polygon is too far up
        // if more obstacles are onscreen than MAX_OBSTACLES_ON_SCREEN,
        // don't render the additional ones
      ) && curr_idx < MAX_OBSTACLES_ON_SCREEN) begin
        curr_idx <= curr_idx + 1;
      end
      cur_min_x <= (1 << (WORLD_BITS - 1)) - 1; // most positive number
      cur_max_x <=  1 << (WORLD_BITS - 1);      // most negative number
      cur_min_y <= (1 << (WORLD_BITS - 1)) - 1; // most positive number
      cur_max_y <=  1 << (WORLD_BITS - 1);      // most negative number

      prev_valid_in <= 0;
    end
  end

  logic signed [WORLD_BITS-1:0] debug;
assign debug = obstacles_num_sides_out[curr_idx];

endmodule

`default_nettype wire