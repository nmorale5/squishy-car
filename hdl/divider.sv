`timescale 1ns / 1ps
`default_nettype none

module divider #(parameter WIDTH = 32, parameter OUT_SIZE=20) (input wire clk_in,
                input wire rst_in,
                input wire signed [WIDTH-1:0] dividend_in,
                input wire signed [WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[OUT_SIZE-1:0] quotient_out,
                //output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);
  logic [32-1:0] quotient, dividend;
  logic [32-1:0] divisor;
  logic [5:0] count;
  logic [31:0] p;


  logic [1:0] negative;
  logic sign; //1 if sign flip needed
  
  always_comb begin
    if (^ negative) begin
      sign = 1;
    end else begin
      sign = 0;
    end
  end

  enum {RESTING, DIVIDING, RESULT} state;
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
      count <= 0;
    end else begin
      case (state)
        RESTING: begin
          if (data_valid_in)begin
            
            state <= DIVIDING;
            quotient <= 0;
            busy_out <= 1'b1;
            error_out <= 1'b0;
            count <= 31;//load all up
            p <= 0;

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

          end
          data_valid_out <= 1'b0;
        end
        DIVIDING: begin
          if (count==0)begin
            state <= RESULT;
            if ({p[30:0],dividend[31]}>=divisor[31:0])begin
              //remainder_out <= {p[30:0],dividend[31]} - divisor[31:0];
              quotient_out <= {dividend[30:0],1'b1};
            end else begin
              //remainder_out <= {p[30:0],dividend[31]};
              quotient_out <= {dividend[30:0],1'b0};
            end
            busy_out <= 1'b0; //tell outside world i'm done
            error_out <= 1'b0;

          end else begin
            if ({p[30:0],dividend[31]}>=divisor[31:0])begin
              p <= {p[30:0],dividend[31]} - divisor[31:0];
              dividend <= {dividend[30:0],1'b1};
            end else begin
              p <= {p[30:0],dividend[31]};
              dividend <= {dividend[30:0],1'b0};
            end
            count <= count-1;
          end
        end
        RESULT: begin
          if (sign) begin
            quotient_out <= ~quotient_out + 2'sd1;
          end else begin
            quotient_out <= quotient_out;
          end
          data_valid_out <= 1'b1; //good stuff!
          state <= RESTING;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
