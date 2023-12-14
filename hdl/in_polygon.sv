`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module in_polygon # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter WORLD_BITS = 32,
  parameter MAX_NUM_VERTICES = 32
) (
  input wire clk_in, // the faster clock
  input wire signed [WORLD_BITS-1:0] x_in,
  input wire signed [WORLD_BITS-1:0] y_in,
  input wire signed [WORLD_BITS-1:0] poly_xs_in [MAX_NUM_VERTICES],
  input wire signed [WORLD_BITS-1:0] poly_ys_in [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES+1)-1:0] num_points_in,
  output logic out
);

  localparam MAX_DELAY = 4; // multiplication takes 3 cycles, but round up since we need an even number

  logic [MAX_NUM_VERTICES-1:0] intersections;
  logic signed [WORLD_BITS-1:0] Hx [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] Hy [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] Lx [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] Ly [MAX_NUM_VERTICES];
  logic signed [2*WORLD_BITS-1:0] mul [MAX_NUM_VERTICES][2];
  logic [MAX_NUM_VERTICES-1:0] in_bounds [MAX_DELAY];

  logic parity;
  initial begin
    parity = 0;
  end

  logic [WORLD_BITS-1:0] mul_arg_a [MAX_NUM_VERTICES];
  logic [WORLD_BITS-1:0] mul_arg_b [MAX_NUM_VERTICES];
  logic [2*WORLD_BITS:0] one_cycle_mul_delay [MAX_NUM_VERTICES];

  generate
    for (genvar v = 0; v < MAX_NUM_VERTICES; v = v + 1) begin
      multiplier_sim multiply1 (
        .CLK(clk_in),
        .A(mul_arg_a[v]),
        .B(mul_arg_b[v]),
        .P(one_cycle_mul_delay[v])
      );

      assign mul_arg_a[v] = parity ? Ly[v] - Hy[v] : Lx[v] - Hx[v];
      assign mul_arg_b[v] = parity ? x_in - Hx[v] : y_in - Hy[v];

      always_comb begin
        if (poly_ys_in[v] > poly_ys_in[v + 1 < num_points_in ? v + 1 : 0]) begin
          Hx[v] = poly_xs_in[v];
          Hy[v] = poly_ys_in[v];
          Lx[v] = poly_xs_in[v + 1 < num_points_in ? v + 1 : 0];
          Ly[v] = poly_ys_in[v + 1 < num_points_in ? v + 1 : 0];
        end else begin
          Hx[v] = poly_xs_in[v + 1 < num_points_in ? v + 1 : 0];
          Hy[v] = poly_ys_in[v + 1 < num_points_in ? v + 1 : 0];
          Lx[v] = poly_xs_in[v];
          Ly[v] = poly_ys_in[v];
        end
      end
    end
  endgenerate

  always_ff @(posedge clk_in) begin
    for (int v = 0; v < MAX_NUM_VERTICES; v = v + 1) begin
      mul[v][parity] <= one_cycle_mul_delay[v];
      if (parity) begin
        in_bounds[0][v] <= (Hy[v] > y_in) && (y_in >= Ly[v]);
        intersections[v] <= in_bounds[MAX_DELAY-1][v] && (mul[v][0] - mul[v][1] <= 0);
      end
    end
  end

  logic odd_intersections;
  always_comb begin
    odd_intersections = 0;
    for (int i = 0; i < MAX_NUM_VERTICES; i = i + 1) begin
      odd_intersections ^= i < num_points_in && intersections[i];
    end
  end

  always_ff @(posedge clk_in) begin
    out <= odd_intersections;
    parity <= parity ^ 1;
    if (parity) begin
      for (int i=1; i<MAX_DELAY; i=i+1) begin
        in_bounds[i] <= in_bounds[i-1];
      end
    end
  end

endmodule

`default_nettype wire