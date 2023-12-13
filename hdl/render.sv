`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`define BLACK 4'h0
`define GRAY 4'h1
`define WHITE 4'h2
`define RED 4'h3
`define PINK 4'h4
`define DBROWN 4'h5
`define BROWN 4'h6
`define ORANGE 4'h7
`define YELLOW 4'h8
`define DGREEN 4'h9
`define GREEN 4'hA
`define LGREEN 4'hB
`define PURPLE 4'hC
`define DBLUE 4'hD
`define BLUE 4'hE
`define LBLUE 4'hF

module render # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter SCALE_LEVEL = 0,
  parameter WORLD_BITS = 32,
  parameter MAX_OBSTACLES_ON_SCREEN = 4,
  parameter OBSTACLE_MAX_VERTICES = 8,
  parameter CAR_BODY_VERTICES = 4,
  parameter CAR_WHEEL_VERTICES = 4,
  parameter BACKGROUND_COLOR = `GRAY,
  parameter CAR_BODY_COLOR = `RED,
  parameter CAR_WHEEL_COLOR = `BROWN,
  parameter EDGE_COLOR = `BLACK,
  parameter EDGE_THICKNESS = 3
) (
  input wire rst_in,
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire signed [WORLD_BITS-1:0] camera_x_in,
  input wire signed [WORLD_BITS-1:0] camera_y_in,
  input wire signed [WORLD_BITS-1:0] car_body_xs_in [CAR_BODY_VERTICES],
  input wire signed [WORLD_BITS-1:0] car_body_ys_in [CAR_BODY_VERTICES],
  input wire signed [WORLD_BITS-1:0] car_wheel_1_xs_in [CAR_WHEEL_VERTICES],
  input wire signed [WORLD_BITS-1:0] car_wheel_1_ys_in [CAR_WHEEL_VERTICES],
  input wire signed [WORLD_BITS-1:0] car_wheel_2_xs_in [CAR_WHEEL_VERTICES],
  input wire signed [WORLD_BITS-1:0] car_wheel_2_ys_in [CAR_WHEEL_VERTICES],
  input wire signed [WORLD_BITS-1:0] obstacles_xs_in [MAX_OBSTACLES_ON_SCREEN] [OBSTACLE_MAX_VERTICES],
  input wire signed [WORLD_BITS-1:0] obstacles_ys_in [MAX_OBSTACLES_ON_SCREEN] [OBSTACLE_MAX_VERTICES],
  input wire [$clog2(OBSTACLE_MAX_VERTICES+1)-1:0] obstacles_num_sides_in [MAX_OBSTACLES_ON_SCREEN],
  input wire [$clog2(MAX_OBSTACLES_ON_SCREEN+1)-1:0] num_obstacles_in,
  input wire [3:0] colors_in [MAX_OBSTACLES_ON_SCREEN],
  output logic [23:0] color_out
);

  localparam MAX_POLYGONS_ON_SCREEN = MAX_OBSTACLES_ON_SCREEN + 3;

  logic [MAX_POLYGONS_ON_SCREEN-1:0] edge_valids, fill_valids;

  generate
    genvar ob;
    for (ob = 0; ob < MAX_OBSTACLES_ON_SCREEN; ob = ob + 1) begin
      draw_polygon # (
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .PIXEL_HEIGHT(PIXEL_HEIGHT),
        .WORLD_BITS(WORLD_BITS),
        .SCALE_LEVEL(SCALE_LEVEL),
        .EDGE_THICKNESS(EDGE_THICKNESS),
        .MAX_NUM_VERTICES(OBSTACLE_MAX_VERTICES)
      ) obstacle (
        .rst_in(rst_in),
        .clk_in(clk_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .camera_x_in(camera_x_in),
        .camera_y_in(camera_y_in),
        .xs_in(obstacles_xs_in[ob]),
        .ys_in(obstacles_ys_in[ob]),
        .num_points_in(obstacles_num_sides_in[ob]),
        .edge_out(edge_valids[ob+3]),
        .fill_out(fill_valids[ob+3])
      );
    end
  endgenerate

  draw_polygon # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .WORLD_BITS(WORLD_BITS),
    .SCALE_LEVEL(SCALE_LEVEL),
    .EDGE_THICKNESS(EDGE_THICKNESS),
    .MAX_NUM_VERTICES(CAR_WHEEL_VERTICES)
  ) wheel_1 (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .camera_x_in(camera_x_in),
    .camera_y_in(camera_y_in),
    .xs_in(car_wheel_1_xs_in),
    .ys_in(car_wheel_1_ys_in),
    .num_points_in(CAR_WHEEL_VERTICES),
    .edge_out(edge_valids[0]),
    .fill_out(fill_valids[0])
  );

  draw_polygon # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .WORLD_BITS(WORLD_BITS),
    .SCALE_LEVEL(SCALE_LEVEL),
    .EDGE_THICKNESS(EDGE_THICKNESS),
    .MAX_NUM_VERTICES(CAR_WHEEL_VERTICES)
  ) wheel_2 (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .camera_x_in(camera_x_in),
    .camera_y_in(camera_y_in),
    .xs_in(car_wheel_2_xs_in),
    .ys_in(car_wheel_2_ys_in),
    .num_points_in(CAR_WHEEL_VERTICES),
    .edge_out(edge_valids[1]),
    .fill_out(fill_valids[1])
  );

  draw_polygon # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .WORLD_BITS(WORLD_BITS),
    .SCALE_LEVEL(SCALE_LEVEL),
    .EDGE_THICKNESS(EDGE_THICKNESS),
    .MAX_NUM_VERTICES(CAR_BODY_VERTICES)
  ) body (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .camera_x_in(camera_x_in),
    .camera_y_in(camera_y_in),
    .xs_in(car_body_xs_in),
    .ys_in(car_body_ys_in),
    .num_points_in(CAR_BODY_VERTICES),
    .edge_out(edge_valids[2]),
    .fill_out(fill_valids[2])
  );

  logic [3:0] color_idx;

  always_comb begin
    color_idx = BACKGROUND_COLOR;
    for (int i = MAX_POLYGONS_ON_SCREEN - 1; i >= 0; i = i - 1) begin
      if (i < 2) begin
        color_idx = edge_valids[i] ? EDGE_COLOR : (fill_valids[i] ? CAR_WHEEL_COLOR : color_idx);
      end else if (i == 2) begin
        color_idx = edge_valids[i] ? EDGE_COLOR : (fill_valids[i] ? CAR_BODY_COLOR : color_idx);
      end else if (i < num_obstacles_in + 3) begin
        color_idx = edge_valids[i] ? EDGE_COLOR : (fill_valids[i] ? colors_in[i-3] : color_idx);
      end else begin
        color_idx = color_idx;
      end
    end
  end

  palette palette_idx_to_color (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .idx_in(color_idx),
    .color_out(color_out)
  );

endmodule

`default_nettype wire