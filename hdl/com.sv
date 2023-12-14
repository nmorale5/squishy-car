`timescale 1ns / 1ps
`default_nettype none

module center_of_mass #(POSITION_SIZE=8, NUM_NODES)(
    input wire clk_in,
    input wire rst_in,
    input wire [POSITION_SIZE-1:0] x_in,
    input wire [POSITION_SIZE-1:0]  y_in,
    input wire valid_in,
    input wire tabulate_in,
    output logic [POSITION_SIZE-1:0] x_out,
    output logic [POSITION_SIZE-1:0] y_out,
    output logic valid_out);

  
  divider #(.WIDTH(POSITION_SIZE + NUM_NODES), .OUT_SIZE(POSITION_SIZE)) x_divider (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(x_sum),
                .divisor_in(mass_total),
                .data_valid_in(divider_valid_in),
                .quotient_out(x_divider_out),
                //.remainder_out(x_remainder), //do we do anything with the remainder?
                .data_valid_out(divider_valid_out_x),
                .error_out(x_error),
                .busy_out(x_divide_busy)
                );
 
    divider #(.WIDTH(POSITION_SIZE + NUM_NODES), .OUT_SIZE(POSITION_SIZE)) y_divider (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(y_sum),
                .divisor_in(mass_total),
                .data_valid_in(divider_valid_in),
                .quotient_out(y_divider_out),
                //.remainder_out(y_remainder), //do we do anything with the remainder?
                .data_valid_out(divider_valid_out_y),
                .error_out(y_error),
                .busy_out(y_divide_busy)
                );

  typedef enum logic [3:0] {IDLE = 5, TALLY=0, DIVIDE=1, DIV_WAIT=2, VALID_OUT=3, RESET=4} com_state;
  com_state state = TALLY;
  logic [POSITION_SIZE + NUM_NODES - 1:0] x_sum = 0; //# bits = ciel(log2(n*(n+1)) - 1)
  logic [POSITION_SIZE + NUM_NODES - 1:0] y_sum = 0; //could be 18
  logic [$clog2(NUM_NODES):0] mass_total;
  logic divider_valid_in = 0;
  //logic [29:0] x_remainder;
  //logic [29:0] y_remainder;
  logic divider_valid_out_x;
  logic divider_valid_out_y;
  logic x_ready;
  logic y_ready;
  logic x_divide_busy;
  logic y_divide_busy;
  logic x_error;
  logic y_error;
  logic [POSITION_SIZE-1:0] x_divider_out;
  logic [POSITION_SIZE-1:0] y_divider_out;
  logic [$clog2(NUM_NODES):0] current_node;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        x_out <= 0;
        y_out <= 0;
        valid_out <= 0;
        x_sum <= 0;
        y_sum <= 0;
        mass_total <= 0;
        x_ready <= 0;
        y_ready <= 0;
    end else begin
        case (state)
            TALLY: state <= (tabulate_in == 1 && mass_total != 0)? DIVIDE: TALLY;
            DIVIDE: state <= (x_divide_busy == 0 && y_divide_busy == 0)? DIV_WAIT: DIVIDE;
            DIV_WAIT: state <= (x_ready && y_ready)?VALID_OUT: DIV_WAIT;
            VALID_OUT: state <= RESET;
            RESET: state <= TALLY;
        endcase

        case(state)
            TALLY: begin
              if (valid_in) begin
                x_sum <= x_sum + x_in;
                y_sum <= y_sum + y_in;
                mass_total <= mass_total + 1;
              end
            end
            DIVIDE: divider_valid_in <= 1;
            DIV_WAIT: begin
                divider_valid_in <= 0;
                x_ready <= (divider_valid_out_x)?1:x_ready;
                y_ready <= (divider_valid_out_y)?1:y_ready;
            end
            VALID_OUT: begin
                valid_out <= 1;
                x_out <= x_divider_out[POSITION_SIZE-1:0];
                y_out <= y_divider_out[POSITION_SIZE-1:0];

            end
            RESET: begin
                valid_out <= 0;
                x_sum <= 0;
                y_sum <= 0;
                mass_total <= 0;
                x_ready <= 0;
                y_ready <= 0;
            end
        endcase

    end

  end

endmodule



`default_nettype wire

