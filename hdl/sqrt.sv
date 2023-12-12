module sqrt #(WIDTH=12, OUTPUT_SIZE=6) (
  input wire clk_in,
  input wire [WIDTH-1:0] x,          // Input integer
  input wire valid_in,
  output logic [WIDTH-1:0] sqrt_x,  // Output square root approximation
  output logic result_valid
);
  typedef enum {IDLE = 0, CALC = 1, RESULT=2} sqrt_state;
  sqrt_state state = IDLE;

  //calculates floor of sqrt
  logic [WIDTH-1:0] approx, approx_next;
  logic [2 * WIDTH - 1:0] approx_squared;
  logic [WIDTH-1:0] min, max;

  assign approx_squared = approx * approx;

  always_ff @(posedge clk_in) begin
    case (state)
        IDLE: begin
            result_valid <= 0;
            if (valid_in) begin
                state <= CALC;
                approx <= x >> 1;
                max <= x;
                min <= 0;
            end
        end
        CALC: begin
            if (approx_squared <= x & x < approx_squared + 2 * approx + 1 ) begin
                state <= RESULT;
            end else begin
                if (approx_squared > x) begin
                    max <= approx;
                    approx <= min + (approx - min)/2;
                end else begin
                    approx <= approx + (max - approx)/2;
                    min <= approx;
                end
            end
        end
        RESULT: begin
            sqrt_x <= approx;
            result_valid <= 1;
            state <= IDLE;
        end


    endcase
  end

endmodule


/*module sqrt #(WIDTH=12, OUTPUT_SIZE=6) (
  input wire clk_in,
  input wire [WIDTH-1:0] x,          // Input integer
  input wire valid_in,
  output logic [WIDTH-1:0] sqrt_x,  // Output square root approximation
  output logic result_valid
);

  logic [WIDTH-1:0] approx, approx_next;
  logic [WIDTH-1:0] x_signed, diff;
  logic [$clog2(WIDTH/2):0] iteration;

  typedef enum {IDLE = 0, CALC = 1, RESULT=2} sqrt_state;
  sqrt_state state = IDLE;

  assign approx_next = ((approx >> 1) + ((x >> (WIDTH - 2 - 2*iteration)) & 3)) << 1;
  assign diff = x - (approx_next * approx_next);

  always_ff @(posedge clk_in) begin
    case (state)
        IDLE: begin
            result_valid <= 0;
            if (valid_in) begin
                state <= CALC;
                iteration <= 0;
                approx <= x >> 1;
                //diff <= 0;
            end
        end
        CALC: begin
            iteration <= iteration + 1;
            if (iteration == WIDTH/2) begin
                state <= RESULT;
            end else begin
                
                approx <= approx | ((diff >> (WIDTH-1)) << (WIDTH - 2 - 2*iteration));
            end
        end
        RESULT: begin
            sqrt_x <= approx;
            result_valid <= 1;
            state <= IDLE;
        end


    endcase
  end

endmodule*/