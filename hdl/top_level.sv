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
  // assign rgb0 = 0;
  /* have btnd control system reset */
  logic sys_rst;
  assign sys_rst = btn[0];
 
  logic clk_pixel, clk_5x, clk_render; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)

  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
      .reset(0),
      .locked(locked),
      .clk_ref(clk_100mhz),
      .clk_pixel(clk_pixel),
      .clk_render(clk_render),
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

  logic [25:0] some_counter;
  always_ff @(posedge clk_render) begin
    some_counter <= some_counter + 1;
    if (some_counter == 0) begin
      rgb0[0] <= ~rgb0[0];
    end
  end

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
    .clk_in(clk_render),
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
    .clk_in(clk_render),
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
    .clk_in(clk_render),
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
    .clk_in(clk_render),
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
  localparam MAX_OBSTACLES_ON_SCREEN = 8;
  localparam WORLD_BITS = 17;
  localparam MAX_NUM_VERTICES = 4;
  localparam CAR_BODY_VERTICES = 4;
  localparam CAR_WHEEL_VERTICES = 8;
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
  always_ff @(posedge clk_render) begin
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
    logic signed [WORLD_BITS-1:0] car_wheel_1_x [CAR_WHEEL_VERTICES];
  logic signed [WORLD_BITS-1:0] car_wheel_1_y [CAR_WHEEL_VERTICES];



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
    .clk_in(clk_render),
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






  //Physics
  localparam NUM_WHEEL_SPRINGS = 12;
  localparam NUM_BODY_SPRINGS = 6;
  localparam NUM_WHEEL_NODES = CAR_WHEEL_VERTICES;
  localparam NUM_BODY_NODES = CAR_BODY_VERTICES;
  localparam NUM_VERTICES = MAX_NUM_VERTICES;
  localparam NUM_OBSTACLES = MAX_OBSTACLES_ON_SCREEN;
  localparam POSITION_SIZE = WORLD_BITS;
  localparam VELOCITY_SIZE = 15;
  localparam FORCE_SIZE = 15;
  localparam TORQUE = 4;
  localparam GRAVITY = -1;
  localparam DT = 3;
  localparam CONSTANT_SIZE = 3;

  logic [10:0] update_count = 0;


  assign begin_update = got_all_obstacles && (update_count == 0);

  logic begin_update;
  logic [CONSTANT_SIZE-1:0] wheel_constants [4];
  logic [CONSTANT_SIZE-1:0] body_constants [4];
  logic signed [2:0] drive;
  logic signed [POSITION_SIZE-1:0] wheel_ideal [1:0][NUM_WHEEL_NODES];
  logic signed [POSITION_SIZE-1:0] body_ideal [1:0][NUM_BODY_NODES];
  logic [$clog2(NUM_WHEEL_NODES):0] wheel_springs [1:0][NUM_WHEEL_SPRINGS];
  logic [$clog2(NUM_BODY_NODES):0] body_springs [1:0][NUM_BODY_SPRINGS];
  logic [POSITION_SIZE-1:0] wheel_equilibriums [NUM_WHEEL_SPRINGS];
  logic [POSITION_SIZE-1:0] body_equilibriums [NUM_WHEEL_SPRINGS];
  logic signed [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [$clog2(NUM_VERTICES):0] all_num_vertices [NUM_OBSTACLES]; //might be replaced
  logic [$clog2(NUM_OBSTACLES):0] num_obstacles; //might get replaced
  logic signed [POSITION_SIZE-1:0] left_wheel_x;
  logic signed [POSITION_SIZE-1:0] left_wheel_y;
  logic left_wheel_valid;
  logic signed [POSITION_SIZE-1:0] right_wheel_x;
  logic signed [POSITION_SIZE-1:0] right_wheel_y;
  logic right_wheel_valid;
  logic signed [POSITION_SIZE-1:0] body_x;
  logic signed [POSITION_SIZE-1:0] body_y;
  logic body_valid;
  logic [5:0] states;
  logic [POSITION_SIZE-1:0] com_x, com_y;
  logic com_valid;
  logic all_done;



    manage_car #(
    .DT(DT),
    .NUM_WHEEL_NODES(NUM_WHEEL_NODES),
    .NUM_BODY_NODES(NUM_BODY_NODES),
    .NUM_WHEEL_SPRINGS(NUM_WHEEL_SPRINGS),
    .NUM_BODY_SPRINGS(NUM_BODY_SPRINGS),
    .NUM_VERTICES(NUM_VERTICES),
    .NUM_OBSTACLES(NUM_OBSTACLES),
    .POSITION_SIZE(POSITION_SIZE),
    .VELOCITY_SIZE(VELOCITY_SIZE),
    .FORCE_SIZE(FORCE_SIZE),
    .CONSTANT_SIZE(CONSTANT_SIZE),
    .TORQUE(TORQUE),
    .GRAVITY(GRAVITY)
  ) car_instance (
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .begin_update(begin_update),
    .wheel_constants(wheel_constants),
    .body_constants(body_constants),
    .drive(drive),
    .wheel_ideal(wheel_ideal),
    .body_ideal(body_ideal),
    .wheel_springs(wheel_springs),
    .body_springs(body_springs),
    .wheel_equilibriums(wheel_equilibriums),
    .body_equilibriums(body_equilibriums),
    .obstacles(obstacles),
    .all_num_vertices(all_num_vertices), //num_sides_each_poly
    .num_obstacles(num_obstacles), //num_polys_on_screen
    .debug_switches(debug_switches),
    .left_wheel_x(left_wheel_x),
    .left_wheel_y(left_wheel_y),
    .left_wheel_valid(left_wheel_valid),
    .right_wheel_x(right_wheel_x),
    .right_wheel_y(right_wheel_y),
    .right_wheel_valid(right_wheel_valid),
    .body_x(body_x),
    .body_y(body_y),
    .body_valid(body_valid),
    .states(states),
    .com_x_out(com_x),
    .com_y_out(com_y),
    .com_out_valid(com_valid),
    .all_done(all_done)
  );


/*states will be attached to lights for debugging
bit  value
12-10    wheel state
15-13    forces_ready
  13      springs_force
  14      ideal_force
  15      torque_force

//switches for debugging
sw   action
1    forward
2 backward
14   nodes <= new_nodes
15   begin simulation

*/


  logic [3:0] debug_switches;
  assign led[15:9] = states;

  logic forward, backward;
  logic 
  always_comb begin

      for (int i = 0; i < NUM_WHEEL_SPRINGS; i = i + 1) begin
          wheel_equilibriums[i] = 10;//$sqrt((wheel_ideal[wheel_springs[1][i]][1] - wheel_ideal[wheel_springs[0][i]][1]) * (wheel_ideal[wheel_springs[1][i]][1] - wheel_ideal[wheel_springs[0][i]][1]) + (wheel_ideal[wheel_springs[1][i]][0] - wheel_ideal[wheel_springs[0][i]][0]) * (wheel_ideal[wheel_springs[1][i]][0] - wheel_ideal[wheel_springs[0][i]][0]));
      end

      for (int i = 0; i < NUM_BODY_SPRINGS; i = i + 1) begin
          body_equilibriums[i] = 10;//$sqrt((body_ideal[body_springs[1][i]][1] - body_ideal[body_springs[0][i]][1]) * (body_ideal[body_springs[1][i]][1] - body_ideal[body_springs[0][i]][1]) + (body_ideal[body_springs[1][i]][0] - body_ideal[body_springs[0][i]][0]) * (body_ideal[body_springs[1][i]][0] - body_ideal[body_springs[0][i]][0]));
      end

      body_ideal[0][0] = -30;
      body_ideal[1][0] = -20;
      body_ideal[0][1] = -20;
      body_ideal[1][1] = 20;
      body_ideal[0][2] = 20;
      body_ideal[1][2] = 20;
      body_ideal[0][3] = 30;
      body_ideal[1][3] = -20;

      body_springs[0][0] = 0;
      body_springs[1][0] = 1;
      body_springs[0][1] = 1;
      body_springs[1][1] = 2;
      body_springs[0][2] = 2;
      body_springs[1][2] = 3;
      body_springs[0][3] = 3;
      body_springs[1][3] = 0;
      body_springs[0][4] = 0;
      body_springs[1][4] = 2;
      body_springs[0][5] = 1;
      body_springs[1][5] = 3;

      wheel_ideal[0][0] = 0;
      wheel_ideal[1][0] = 50;
      wheel_ideal[0][1] = 35;
      wheel_ideal[1][1] = 35;
      wheel_ideal[0][2] = 50;
      wheel_ideal[1][2] = 0;
      wheel_ideal[0][3] = 35;
      wheel_ideal[1][3] = -35;
      wheel_ideal[0][4] = 0;
      wheel_ideal[1][4] = -50;
      wheel_ideal[0][5] = -35;
      wheel_ideal[1][5] = -35;
      wheel_ideal[0][6] = -50;
      wheel_ideal[1][6] = 0;
      wheel_ideal[0][7] = -35;
      wheel_ideal[1][7] = -35;

      wheel_springs[0][0] = 0;
      wheel_springs[1][0] = 1;
      wheel_springs[0][1] = 1;
      wheel_springs[1][1] = 2;
      wheel_springs[0][2] = 2;
      wheel_springs[1][2] = 3;
      wheel_springs[0][3] = 3;
      wheel_springs[1][3] = 4;
      wheel_springs[0][4] = 4;
      wheel_springs[1][4] = 5;
      wheel_springs[0][5] = 5;
      wheel_springs[1][5] = 6;
      wheel_springs[1][6] = 6;
      wheel_springs[0][6] = 7;
      wheel_springs[1][7] = 7;
      wheel_springs[0][7] = 0;
      wheel_springs[1][8] = 0;
      wheel_springs[1][8] = 4;
      wheel_springs[0][9] = 1;
      wheel_springs[1][9] = 5;
      wheel_springs[0][10] = 2;
      wheel_springs[1][10] = 6;
      wheel_springs[0][11] = 3;
      wheel_springs[1][11] = 7;


      //constants do shifts
      wheel_constants[0] = 1; //spring_k
      wheel_constants[1] = 0; //spring_b
      wheel_constants[2] = 1; //ideal_k
      wheel_constants[3] = 0; //ideal_b

      body_constants[0] = 0; //spring_k
      body_constants[1] = 0; //spring_b
      body_constants[2] = 1; //ideal_k
      body_constants[3] = 0; //ideal_b

      forward = sw[1];
      backward = sw[2];
      drive = forward - backward;

      for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
        for (int j = 0; j < NUM_OBSTACLES; j = j + 1) begin
          obstacles[0][i][j] = on_screen_xs[j][i];
          obstacles[1][i][j] = on_screen_ys[j][i];
        end
      end

  end

  //recieving the new positions and velocities from manage_car
  logic [$clog2(NUM_WHEEL_NODES):0] left_wheel_count, right_wheel_count;
  logic [$clog2(NUM_BODY_NODES):0] body_count;


  always_ff @(posedge clk_pixel) begin
    if (begin_update) begin
      update_count <= (update_count == sw[12:6])?0:update_count + 1;
    end
    if (com_valid) begin
      camera_x <= com_x;
      camera_y <= com_y;
    end

    if (left_wheel_valid) begin
      left_wheel_count <= (left_wheel_count == NUM_WHEEL_NODES-1)?0: left_wheel_count + 1;
      car_wheel_1_x[left_wheel_count] <= left_wheel_x;
      car_wheel_1_y[left_wheel_count] <= left_wheel_y;
    end
    if (right_wheel_valid) begin
      right_wheel_count <= (right_wheel_count == NUM_WHEEL_NODES-1)?0: right_wheel_count + 1;
      car_wheel_2_x[right_wheel_count] <= right_wheel_x;
      car_wheel_2_y[right_wheel_count] <= right_wheel_y;
    end
    if (body_count) begin
      body_count <= (body_count == NUM_WHEEL_NODES-1)?0: body_count + 1;
      car_body_x[body_count] <= body_x;
      car_body_y[body_count] <= body_y;
    end

  end



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