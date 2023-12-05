`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

// responsible for reading all obstacles and updating the moving ones
module manage_environment # (
  parameter WORLD_BITS = 32,
  parameter MAX_NUM_VERTICES = 8,
  parameter DT = 1
) (
  input wire clk_in,
  input wire rst_in,
  input wire start_in,
  output logic valid_out,
  output logic [WORLD_BITS-1:0] x_out,
  output logic [WORLD_BITS-1:0] y_out,
  output logic done_out
);

  typedef enum { IDLE = 0, READ_DELAY_1 = 1, READ_DELAY_2 = 2, CALCULATE = 3, RESULT = 4 } manage_env_state;
  manage_env_state state = IDLE;

  typedef enum { WAITING = 0, MOVING = 1, STATIC = 2 } manage_env_region;
  manage_env_region read_region = WAITING;
  manage_env_region write_region = WAITING;

  logic [WORLD_BITS-1:0] MOVING_SENTINEL;
  assign MOVING_SENTINEL = 1 << (WORLD_BITS - 1);
  logic [$clog2(BRAM_DEPTH)-1:0] sentinel_address;

  localparam BRAM_WIDTH = 2 * WORLD_BITS;
  localparam BRAM_DEPTH = 67; // Needs to match the number of lines in /data/level.mem
  
  logic [$clog2(BRAM_DEPTH)-1:0] read_addr, write_addr;
  logic signed [WORLD_BITS-1:0] read_data_a, read_data_b, write_data_a, write_data_b;
  logic write_valid;

  assign write_addr = read_addr - MAX_LATENCY - 3;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(BRAM_WIDTH),               // Specify RAM data width
    .RAM_DEPTH(BRAM_DEPTH),               // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(level.mem))         // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) env_bram (
    .addra(read_addr),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(write_addr),   // Port B address bus, width determined from RAM_DEPTH
    .dina(1'b0),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb({ write_data_a, write_data_b }),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Port A clock
    .clkb(clk_in),     // Port B clock
    .wea(1'b0),       // Port A write enable
    .web(write_valid), // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1),    // Port A output register enable
    .regceb(1'b1),    // Port B output register enable
    .douta({ read_data_a, read_data_b }), // Port A RAM output data, width determined from RAM_WIDTH
    .doutb()           // Port B RAM output data, width determined from RAM_WIDTH
  );

  localparam MAX_LATENCY = 36; // same as rotate latency (WORLD_BITS + 4)

  logic signed [WORLD_BITS-1:0] buffer_a [MAX_LATENCY];
  logic signed [WORLD_BITS-1:0] buffer_b [MAX_LATENCY];

  logic [$clog2(MAX_NUM_VERTICES + 4):0] read_line_counter; // add 1 extra bit to allow for negatives
  logic [$clog2(MAX_NUM_VERTICES + 4):0] write_line_counter; // add 1 extra bit to allow for negatives

  logic [$clog2(MAX_NUM_VERTICES + 1)-1:0] read_num_points;
  logic [$clog2(MAX_NUM_VERTICES + 1)-1:0] write_num_points;

  // the displacement of each point due to translation movement
  logic signed [WORLD_BITS-1:0] translate_x;
  logic signed [WORLD_BITS-1:0] translate_y;

  logic signed [WORLD_BITS-1:0] rotate_point_x_arg;
  logic signed [WORLD_BITS-1:0] rotate_point_y_arg;
  logic signed [WORLD_BITS-1:0] rotate_angle_arg;
  logic rotate_valid, rotate_out_valid;

  // the displacement of each point due to rotation movement
  logic signed [WORLD_BITS-1:0] rotate_x;
  logic signed [WORLD_BITS-1:0] rotate_y;

  rotate m_rotate (
    .s_axis_cartesian_tdata({ rotate_point_y_arg, rotate_point_x_arg }),
    .s_axis_cartesian_tvalid(rotate_valid),
    .s_axis_phase_tdata(rotate_angle_arg),
    .s_axis_phase_tvalid(rotate_valid),
    .m_axis_dout_tdata({ rotate_y, rotate_x }),
    .m_axis_dout_tvalid(rotate_out_valid)
  );

  always_ff @(posedge clk_in) begin
    for (int i = 0; i < MAX_LATENCY - 1; i = i + 1) begin
      buffer_a[i + 1] <= buffer_a[i];
      buffer_b[i + 1] <= buffer_b[i];
    end
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= IDLE;
    end else if (start_in) begin
      read_addr <= 0;
      write_valid <= 0;
      done_out <= 0;
      valid_out <= 0;
      read_region <= WAITING;
      write_region <= WAITING;
      read_line_counter <= 0;
      write_line_counter <= 0;
      read_num_points <= 1;
      write_num_points <= 1;
      rotate_valid <= 0;
      state <= READ_DELAY_1;
    end else begin
      if (state == READ_DELAY_1) begin
        read_addr <= read_addr + 1;
        state <= READ_DELAY_2;
      end else if (state == READ_DELAY_2) begin
        read_addr <= read_addr + 1;
        read_region <= MOVING;
        state <= CALCULATE;
      end else if (state == CALCULATE) begin
        read_addr <= read_addr + 1;
        if (read_region == MOVING) begin
          if (read_data_a == MOVING_SENTINEL) begin
            read_region <= STATIC;
            sentinel_address <= read_addr - 2;
            valid_out <= 0;
          end else begin
            case (read_line_counter)
              0: begin
                buffer_a[0] <= (read_data_a + DT) > read_data_b ? (read_data_a + DT) - read_data_b : (read_data_a + DT);
                buffer_b[0] <= read_data_b;
                rotate_valid <= 0;
                valid_out <= 0;
              end
              1: begin
                buffer_a[0] <= buffer_a[0] < (buffer_b[0] >> 1) ? read_data_a : -read_data_a;
                buffer_b[0] <= buffer_a[0] < (buffer_b[0] >> 1) ? read_data_b : -read_data_b;
              end
              2: begin
                buffer_a[0] <= read_data_a;
                buffer_b[0] <= read_data_b;
              end
              3: begin
                buffer_a[0] <= read_data_a;
                buffer_b[0] <= read_data_b;
                read_num_points <= read_data_b;
                rotate_angle_arg <= read_data_a;
              end
              default: begin
                buffer_a[0] <= read_data_a;
                buffer_b[0] <= read_data_b;
                rotate_point_x_arg <= read_data_a - buffer_a[read_line_counter - 3];
                rotate_point_y_arg <= read_data_b - buffer_b[read_line_counter - 3];
                rotate_valid <= 1;
                valid_out <= 1;
                x_out <= read_data_a;
                y_out <= read_data_b;
              end
            endcase
            read_line_counter <= read_line_counter < read_num_points + 3 ? read_line_counter + 1 : 0;
          end
        end else if (read_region == STATIC) begin
          read_line_counter <= read_line_counter < read_num_points ? read_line_counter + 1 : 0;
          if (read_line_counter == 0) begin
            read_num_points <= read_data_b;
            valid_out <= 0;
          end else begin
            x_out <= read_data_a;
            y_out <= read_data_b;
            valid_out <= 1;
          end
          if (read_addr == BRAM_DEPTH + 1) begin
            valid_out <= 0;
            state <= RESULT;
          end
        end
        if (write_addr + 2 == 1 << $clog2(BRAM_DEPTH)) begin
          write_region <= MOVING;
        end
        if (write_addr + 1 == sentinel_address) begin
          write_region <= STATIC;
          write_valid <= 0;
        end else if (write_region == MOVING) begin
          case (write_line_counter)
            0: begin
              write_valid <= 1;
              write_data_a <= buffer_a[MAX_LATENCY-1];
              write_data_b <= buffer_b[MAX_LATENCY-1];
            end
            1: begin
              write_valid <= 0;
              translate_x <= buffer_a[MAX_LATENCY-1];
              translate_y <= buffer_b[MAX_LATENCY-1];
            end
            2: begin
              write_valid <= 1;
              write_data_a <= buffer_a[MAX_LATENCY-1] + translate_x;
              write_data_b <= buffer_b[MAX_LATENCY-1] + translate_y;
            end
            3: begin
              write_valid <= 0;
              write_num_points <= buffer_b[MAX_LATENCY-1];
            end
            default: begin
              write_valid <= 1;
              write_data_a <= buffer_a[MAX_LATENCY-1] + translate_x + rotate_x;
              write_data_b <= buffer_b[MAX_LATENCY-1] + translate_y + rotate_y;
            end
          endcase
        end
        if (write_region != WAITING) begin
          write_line_counter <= write_line_counter + 1 < write_num_points + 4 ? write_line_counter + 1 : 0;
        end
      end else if (state == RESULT) begin
        done_out <= 1;
        state <= IDLE;
        read_region <= WAITING;
        write_region <= WAITING;
      end else begin
        done_out <= 0;
      end
    end
  end

endmodule

`default_nettype wire