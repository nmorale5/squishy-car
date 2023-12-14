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

module top_level(
  input wire clk_100mhz, //crystal reference clock
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
  output logic hdmi_clk_p, hdmi_clk_n //differential hdmi clock
  );
 
  //assign led = sw; //to verify the switch values
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;
  /* have btnd control system reset */
  logic sys_rst;
  assign sys_rst = btn[0];
 
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)
  logic clk_good;
  BUFG mbf (.I(clk_100mhz), .O(clk_good));
  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
      .reset(0),
      .locked(locked),
      .clk_ref(clk_good),
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x));
 
  logic [10:0] hcount; //hcount of system!
  logic [9:0] vcount; //vcount of system!
  logic hor_sync; //horizontal sync signal
  logic vert_sync; //vertical sync signal
  logic active_draw; //ative draw! 1 when in drawing region.0 in blanking/sync
  logic new_frame; //one cycle active indicator of new frame of info!
  logic [5:0] frame_count; //0 to 59 then rollover frame counter
 
  //written by you! (make sure you include in your hdl)
  //default instantiation so making signals for 720p
  video_sig_gen mvg(
      .clk_pixel_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));
 
	logic [23:0] color_out;
  logic [7:0] red, green, blue; //red green and blue pixel values for output

  ////////////////////////////////////////////
  //
  //               Environment
  //
  ////////////////////////////////////////////

  logic signed [WORLD_BITS-1:0] env_stream_x, env_stream_y;
  logic env_stream_valid, env_stream_done;

  logic signed [WORLD_BITS-1:0] screen_min_x, screen_max_x, screen_min_y, screen_max_y;

  pixel_to_world # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .WORLD_BITS(WORLD_BITS),
    .SCALE_LEVEL(SCALE_LEVEL)
  ) get_min_screen_coords (
    .clk_in(clk_pixel),
    .camera_x_in(camera_x),
    .camera_y_in(camera_y),
    .hcount_in(0), 
    .vcount_in(PIXEL_HEIGHT), // higher v-counts are lower on screen
    .world_x_out(screen_min_x),
    .world_y_out(screen_min_y)
  );

  pixel_to_world # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .WORLD_BITS(WORLD_BITS),
    .SCALE_LEVEL(SCALE_LEVEL)
  ) get_max_screen_coords (
    .clk_in(clk_pixel),
    .camera_x_in(camera_x),
    .camera_y_in(camera_y),
    .hcount_in(PIXEL_WIDTH), 
    .vcount_in(0), // lower v-counts are higher on screen
    .world_x_out(screen_max_x),
    .world_y_out(screen_max_y)
  );  

  manage_environment # (
    .WORLD_BITS(WORLD_BITS),
    .MAX_NUM_VERTICES(MAX_NUM_VERTICES)
  ) env (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .start_in(new_frame),
    .valid_out(env_stream_valid),
    .x_out(env_stream_x),
    .y_out(env_stream_y),
    .done_out(env_stream_done)
  );

  logic signed [WORLD_BITS-1:0] on_screen_xs [MAX_OBSTACLES_ON_SCREEN] [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] on_screen_ys [MAX_OBSTACLES_ON_SCREEN] [MAX_NUM_VERTICES];
  logic [$clog2(MAX_NUM_VERTICES+1)-1:0] num_sides_each_poly [MAX_OBSTACLES_ON_SCREEN];
  logic [$clog2(MAX_OBSTACLES_ON_SCREEN+1)-1:0] num_polys_on_screen;
  logic [3:0] obstacle_colors [MAX_OBSTACLES_ON_SCREEN];
  logic got_all_obstacles;

  get_obstacles_on_screen # (
    .WORLD_BITS(WORLD_BITS),
    .MAX_NUM_VERTICES(MAX_NUM_VERTICES),
    .MAX_OBSTACLES_ON_SCREEN(MAX_OBSTACLES_ON_SCREEN)
  ) on_screen (
    .clk_in(clk_pixel),
    .valid_in(env_stream_valid),
    .x_in(env_stream_x),
    .y_in(env_stream_y),
    .screen_min_x(screen_min_x),
    .screen_max_x(screen_max_x),
    .screen_min_y(screen_min_y),
    .screen_max_y(screen_max_y),
    .done_in(env_stream_done),
    .obstacle_xs_out(on_screen_xs),
    .obstacle_ys_out(on_screen_ys),
    .obstacles_num_sides_out(num_sides_each_poly),
    .num_obstacles_out(num_polys_on_screen),
    .done_out(got_all_obstacles)
  );

  always_comb begin
    for (int i = 0; i < MAX_OBSTACLES_ON_SCREEN; i = i + 1) begin
      obstacle_colors[i] = `LGREEN;
    end
  end

  ////////////////////////////////////////////
  //
  //                 RENDER                     
  //
  ////////////////////////////////////////////

  localparam PIXEL_WIDTH = 1280;
  localparam PIXEL_HEIGHT = 720;
  localparam SCALE_LEVEL = 0;
  localparam WORLD_BITS = 17;
  localparam MAX_OBSTACLES_ON_SCREEN = 1;
  localparam MAX_NUM_VERTICES = 4;
  localparam CAR_BODY_VERTICES = 4;
  localparam CAR_WHEEL_VERTICES = 4;
  localparam BACKGROUND_COLOR = `LBLUE;
  localparam CAR_BODY_COLOR = `RED;
  localparam CAR_WHEEL_COLOR = `BROWN;
  localparam EDGE_COLOR = `BLACK;
  localparam EDGE_THICKNESS = 3;



  logic signed [WORLD_BITS-1:0] camera_x, camera_y;

  // assign camera_x = 640;
  // assign camera_y = 360;
  /*
  always_ff @(posedge clk_pixel) begin
    if (new_frame) begin
      if (btn[3]) begin
        camera_x <= camera_x - 5;
      end else if (btn[2]) begin
        camera_x <= camera_x + 5;
      end else if (btn[1]) begin
        camera_y <= camera_y - 5;
      end else if (btn[0]) begin
        camera_y <= camera_y + 5;
      end
    end
  end
  */

  logic signed [WORLD_BITS-1:0] car_body_x [CAR_BODY_VERTICES];
  logic signed [WORLD_BITS-1:0] car_body_y [CAR_BODY_VERTICES];
  logic signed [WORLD_BITS-1:0] car_wheel_2_x [CAR_WHEEL_VERTICES];
  logic signed [WORLD_BITS-1:0] car_wheel_2_y [CAR_WHEEL_VERTICES];

  assign car_body_x[0] = 50;
  assign car_body_y[0] = 30;
  assign car_body_x[1] = 50;
  assign car_body_y[1] = 40;
  assign car_body_x[2] = 70;
  assign car_body_y[2] = 40;
  assign car_body_x[3] = 70;
  assign car_body_y[3] = 30;

/*
  assign car_wheel_2_x[0] = 65;
  assign car_wheel_2_y[0] = 25;
  assign car_wheel_2_x[1] = 65;
  assign car_wheel_2_y[1] = 35;
  assign car_wheel_2_x[2] = 75;
  assign car_wheel_2_y[2] = 35;
  assign car_wheel_2_x[3] = 75;
  assign car_wheel_2_y[3] = 25;
  */

  render # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .SCALE_LEVEL(SCALE_LEVEL),
    .WORLD_BITS(WORLD_BITS),
    .MAX_OBSTACLES_ON_SCREEN(MAX_OBSTACLES_ON_SCREEN),
    .OBSTACLE_MAX_VERTICES(MAX_NUM_VERTICES),
    .CAR_BODY_VERTICES(CAR_BODY_VERTICES),
    .CAR_WHEEL_VERTICES(CAR_WHEEL_VERTICES),
    .BACKGROUND_COLOR(BACKGROUND_COLOR),
    .CAR_BODY_COLOR(CAR_BODY_COLOR),
    .CAR_WHEEL_COLOR(CAR_WHEEL_COLOR),
    .EDGE_COLOR(EDGE_COLOR),
    .EDGE_THICKNESS(EDGE_THICKNESS)
  ) render_game (
    .rst_in(sys_rst),
    .clk_in(clk_pixel),
    .hcount_in(hcount),
    .vcount_in(vcount),
    .camera_x_in(camera_x),
    .camera_y_in(camera_y),
    .car_body_xs_in(car_body_x),
    .car_body_ys_in(car_body_y),
    .car_wheel_1_xs_in(car_wheel_1_x),
    .car_wheel_1_ys_in(car_wheel_1_y),
    .car_wheel_2_xs_in(car_wheel_2_x),
    .car_wheel_2_ys_in(car_wheel_2_y),
    .obstacles_xs_in(on_screen_xs),
    .obstacles_ys_in(on_screen_ys),
    .obstacles_num_sides_in(num_sides_each_poly),
    .num_obstacles_in(num_polys_on_screen),
    .colors_in(obstacle_colors),
    .color_out(color_out)
  );

  logic forward, backward;
  always_comb begin
    for (int i = 0; i < NUM_NODES; i = i + 1) begin
      car_wheel_1_x[i] = nodes[0][i];
      car_wheel_1_y[i] = nodes[1][i];
      car_wheel_2_x[i] = new_nodes[0][i];
      car_wheel_2_x[i] = new_nodes[0][i];
    end

    forward = sw[1];
    backward = sw[2];
    drive = forward - backward;

  end

  logic signed [WORLD_BITS-1:0] car_wheel_1_x [CAR_WHEEL_VERTICES];
  logic signed [WORLD_BITS-1:0] car_wheel_1_y [CAR_WHEEL_VERTICES];

/*
    assign car_wheel_1_x[0] = 475;
  assign car_wheel_1_y[0] = 275;
  assign car_wheel_1_x[1] = 475;
  assign car_wheel_1_y[1] = 325;
  assign car_wheel_1_x[2] = 525;
  assign car_wheel_1_y[2] = 325;
  assign car_wheel_1_x[3] = 525;
  assign car_wheel_1_y[3] = 275; */

  //Physics
  localparam NUM_SPRINGS = 7;
  localparam NUM_NODES = CAR_WHEEL_VERTICES;
  localparam NUM_VERTICES = MAX_NUM_VERTICES;
  localparam NUM_OBSTACLES = MAX_OBSTACLES_ON_SCREEN;
  localparam POSITION_SIZE = WORLD_BITS;
  localparam VELOCITY_SIZE = 8;
  localparam FORCE_SIZE = 8;
  localparam TORQUE = 4;
  localparam GRAVITY = -1;
  localparam DT = 1;
  localparam CONSTANT_SIZE = 4;

  // Signals for testing
  logic begin_update, result_out;
  logic signed [2:0] drive;
  logic [$clog2(NUM_NODES):0] springs [1:0][NUM_SPRINGS];
  logic signed [POSITION_SIZE-1:0] ideal [1:0][NUM_NODES];
  logic signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES];
  logic signed [POSITION_SIZE-1:0] axle [1:0];
  logic [$clog2(NUM_OBSTACLES)-1:0] num_obstacles;
  logic signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES];
  logic signed [POSITION_SIZE-1:0] new_nodes [1:0][NUM_NODES];
  logic signed [VELOCITY_SIZE-1:0] velocities [1:0][NUM_NODES];
  logic signed [VELOCITY_SIZE-1:0] new_velocities [1:0][NUM_NODES];
  logic signed [FORCE_SIZE-1:0] axle_force [1:0];
  logic signed [VELOCITY_SIZE-1:0] axle_velocity [1:0];
  logic [CONSTANT_SIZE-1:0] constants [4];
  logic [POSITION_SIZE-1:0] equilibriums [NUM_SPRINGS];
  logic signed [POSITION_SIZE-1:0] new_node_x, new_node_y;
  logic signed [VELOCITY_SIZE-1:0] new_velocity_x, new_velocity_y;
  logic signed [FORCE_SIZE-1:0] axle_force_x, axle_force_y;
  logic new_node_valid, new_velocity_valid;
  logic [$clog2(NUM_NODES):0] new_node_count = 0;
  logic [$clog2(NUM_NODES):0] new_velocity_count = 0;

  assign begin_update = new_frame;


  logic [POSITION_SIZE-1:0] node1 [1:0];
  logic [POSITION_SIZE-1:0] node2 [1:0];
  
  always_comb begin
    for (int i = 0; i < NUM_SPRINGS; i = i + 1) begin
      node1[0] = ideal[springs[0][i]][0];
      node2[0] = ideal[springs[1][i]][0];
      node1[1] = ideal[springs[0][i]][1];
      node2[1] = ideal[springs[1][i]][1];
      equilibriums[i] = 40;//$sqrt((node2[1]-node1[1]) * (node2[1]-node1[1]) + (node2[0]-node1[0]) * (node2[0]-node1[0]));
    end

  end 

  
  //assign equilibriums[0] = 4;
  //assign equilibriums[1] = 2

  assign led[4:0] = update_late;
  assign led[9:5] = nodes_done_count;
  assign led[15:10] = wheel_states;

/*states will be attached to lights for debugging
bit  value
12-10    wheel state
15-13    forces_ready
  13      springs_force
  14      ideal_force
  15      torque_force
*/

  logic[7:0] update_late;
  logic[7:0] nodes_done_count;
  logic update_done_yet;

  logic [POSITION_SIZE-1:0] com_x, com_y;
  logic com_valid;

  center_of_mass #(POSITION_SIZE, NUM_NODES) com (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .x_in(new_node_x),
    .y_in(new_node_y),
    .valid_in(new_node_valid),
    .tabulate_in(new_node_done),
    .x_out(com_x),
    .y_out(com_y),
    .valid_out(com_valid));

  //localparam [7:0]
  always_ff @(posedge clk_pixel) begin

    if (sys_rst) begin
      nodes_done_count <= 0;
      camera_x <= 0;
      camera_y <= 0;
      //game_initialized <= 0;
      update_late <= 0;
      update_done_yet <= 0;
      axle[0] <= 5;
      axle[1] <= 2;
      axle_velocity[0] <= 0;
      axle_velocity[1] <= 0;

      all_num_vertices[0] <= 4;
      num_obstacles <= 1;

      ideal[0][0] <= -30;
      ideal[1][0] <= -20;
      ideal[0][1] <= -20;
      ideal[1][1] <= 20;
      ideal[0][2] <= 20;
      ideal[1][2] <= 20;
      ideal[0][3] <= 30;
      ideal[1][3] <= -20;


      nodes[0][0] <= -50;
      nodes[1][0] <= -30;
      nodes[0][1] <= -30;
      nodes[1][1] <= 10;
      nodes[0][2] <= 10;
      nodes[1][2] <= 10;
      nodes[0][3] <= 20;
      nodes[1][3] <= -30;

      velocities[0][0] <= 0;
      velocities[1][0] <= 0;
      velocities[0][1] <= 0;
      velocities[1][1] <= 0;
      velocities[0][2] <= 0;
      velocities[1][2] <= 0;
      velocities[0][3] <= 0;
      velocities[1][3] <= 0;

      constants[0] <= 1;
      constants[1] <= 0;

      springs[0][0] <= 0;
      springs[1][0] <= 1;
      springs[0][1] <= 1;
      springs[1][1] <= 2;
      springs[0][2] <= 2;
      springs[1][2] <= 3;
      springs[0][3] <= 3;
      springs[1][3] <= 0;
      springs[0][4] <= 0;
      springs[1][4] <= 2;
      springs[0][5] <= 1;
      springs[1][5] <= 3;


    end else begin
      if (com_valid) begin
        camera_x <= com_x;
        camera_y <= com_y;
      end

      if (update_done_yet == 0 & begin_update) begin
        update_late <= update_late + 1;
        update_done_yet <= 0;
      end

      if (new_node_done) begin
        update_done_yet <= 1;
        nodes_done_count <= nodes_done_count + 1;
      end

      if (new_node_valid == 1) begin
        new_node_count <= new_node_count + 1;
        new_nodes[0][new_node_count] <= new_node_x;
        new_nodes[1][new_node_count] <= new_node_y;
      end

      if (new_velocity_valid == 1) begin
        new_velocity_count <= new_velocity_count + 1;
        new_velocities[0][new_velocity_count] <= new_velocity_x;
        new_velocities[1][new_velocity_count] <= new_velocity_y;
      end

      if (result_out == 1 && sw[14]) begin
        new_node_count <= 0;
        new_velocity_count <= 0;

        nodes[0][0] <= new_nodes[0][0];
        nodes[1][0] <= new_nodes[1][0];
        nodes[0][1] <= new_nodes[0][1];
        nodes[1][1] <= new_nodes[1][1];
        nodes[0][2] <= new_nodes[0][2];
        nodes[1][2] <= new_nodes[1][3];
        nodes[0][3] <= new_nodes[0][3];
        nodes[1][3] <= new_nodes[1][3];

        velocities[0][0] <= new_velocities[0][0];
        velocities[1][0] <= new_velocities[1][0];
        velocities[0][1] <= new_velocities[0][1];
        velocities[1][1] <= new_velocities[1][1];
        velocities[0][2] <= new_velocities[0][2];
        velocities[1][2] <= new_velocities[1][2];
        velocities[0][3] <= new_velocities[0][3];
        velocities[1][3] <= new_velocities[1][3];
      end
    end


  end

  logic new_node_done;
  logic [5:0] wheel_states;

  update_wheel #(
    .NUM_SPRINGS(NUM_SPRINGS),
    .NUM_NODES(NUM_NODES),
    .NUM_VERTICES(NUM_VERTICES),
    .NUM_OBSTACLES(NUM_OBSTACLES),
    .CONSTANT_SIZE(CONSTANT_SIZE),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .TORQUE(TORQUE),
    .GRAVITY(GRAVITY),
    .DT(DT)
  ) wheel_updater (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .begin_in(begin_update && sw[15]),
    .constants(constants),
    .drive(drive),
    .ideal(ideal),
    .obstacles(obstacles),
    .all_num_vertices(all_num_vertices),
    .num_obstacles(num_obstacles),
    .nodes_in(nodes),
    .velocities_in(velocities),
    .springs(springs),
    .equilibriums(equilibriums),
    .axle(axle),
    .axle_velocity(axle_velocity),
    .node_out_x(new_node_x),
    .node_out_y(new_node_y),
    .node_out_valid(new_node_valid),
    .node_out_done(new_node_done),
    .velocity_out_x(new_velocity_x),
    .velocity_out_y(new_velocity_y),
    .velocity_out_valid(new_velocity_valid),
    .axle_force_x(axle_force_x),
    .axle_force_y(axle_force_y),
    .states(wheel_states),
    .result_out(result_out)
  );


	always_comb begin
		red = color_out[23:16];
		green = color_out[15:8];
		blue = color_out[7:0];
	end
 
  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!
 
  //three tmds_encoders (blue, green, red)
  //MISSING two more tmds encoders (one for green and one for blue)
  //note green should have no control signal like red
  //the blue channel DOES carry the two sync signals:
  //  * control_in[0] = horizontal sync signal
  //  * control_in[1] = vertical sync signal
 
  tmds_encoder tmds_red(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(red),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[2]));
 
  tmds_encoder tmds_green(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(green),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(blue),
      .control_in({ vert_sync, hor_sync }),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[0]));



  //three tmds_serializers (blue, green, red):
  //MISSING: two more serializers for the green and blue tmds signals.
  tmds_serializer red_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[2]),
      .tmds_out(tmds_signal[2]));

  tmds_serializer green_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[1]),
      .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[0]),
      .tmds_out(tmds_signal[0]));


 
  //output buffers generating differential signals:
  //three for the r,g,b signals and one that is at the pixel clock rate
  //the HDMI receivers use recover logic coupled with the control signals asserted
  //during blanking and sync periods to synchronize their faster bit clocks off
  //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
  //the slower 74.25 MHz clock)
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));
 
endmodule // top_level
`default_nettype wire