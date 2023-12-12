`timescale 1ns / 1ps
`default_nettype none

module divider #(parameter WIDTH = 32, parameter OUT_SIZE = 8) (input wire clk_in,
                input wire rst_in,
                input wire signed [WIDTH-1:0] dividend_in,
                input wire signed [WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic signed [OUT_SIZE-1:0] quotient_out,
                //output logic signed [WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);
  localparam RESTING = 0;
  localparam DIVIDING = 1;
  localparam RESULT = 2;


  logic [WIDTH-1:0] quotient, dividend;
  logic [WIDTH-1:0] divisor;
  logic [3:0] state = RESTING;
  logic [1:0] negative;
  logic signed [WIDTH-1:0] sign;
  
  always_comb begin
    if (^ negative) begin
      sign = -1;
    end else begin
      sign = 1;
    end
  end

  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      quotient <= 0;
      dividend <= 0;
      divisor <= 0;
      //remainder_out <= 0;
      busy_out <= 1'b0;
      error_out <= 1'b0;
      state <= RESTING;
      data_valid_out <= 1'b0;
    end else begin
      case (state)
        RESTING: begin
          if (data_valid_in)begin
            state <= DIVIDING;
            quotient <= 0;

            if (dividend_in < 0) begin
              dividend <= ~ dividend_in + 2'sb1;
              negative[0] <= 1;
            end else begin
              dividend <= dividend_in;
              negative[0] <= 0;
            end

            if (divisor_in < 0) begin
              divisor <= ~divisor_in + 2'sb1;
              negative[1] <= 1;
            end else begin
              divisor <= divisor_in;
              negative[1] <= 0;
            end

            busy_out <= 1'b1;
            error_out <= 1'b0;
          end
          data_valid_out <= 1'b0;
        end
        DIVIDING: begin
          if (dividend<=0)begin
            state <= RESULT; //similar to return statement
            //remainder_out <= dividend;
            quotient <= quotient * sign;
            busy_out <= 1'b0; //tell outside world i'm done
            error_out <= 1'b0;
          end else if (divisor==0)begin
            state <= RESULT;
            //remainder_out <= 0;
            quotient <= 0;
            busy_out <= 1'b0; //tell outside world i'm done
            error_out <= 1'b1; //ERROR
          end else if (dividend < divisor) begin
            state <= RESULT;
            //remainder_out <= dividend;
            quotient <= quotient * sign;
            busy_out <= 1'b0;
            error_out <= 1'b0;

          end else begin
            //state staying in.
            state <= DIVIDING;
            quotient <= quotient + 1'b1;
            dividend <= dividend-divisor;
          end
        end
        RESULT: begin
          quotient_out <= quotient;
          state <= RESTING;
          data_valid_out <= 1'b1; //good stuff!
          negative[1] <= 0;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
