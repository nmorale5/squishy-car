module collision_new_values #(POSITION_SIZE=8, VELOCITY_SIZE=8, ACCELERATION_SIZE=8,  DT = 1, FRICTION=1, RESTITUTION = 15)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [POSITION_SIZE-1:0] v1_in [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2_in [1:0],
  input  wire signed [POSITION_SIZE-1:0] pos_x,
  input  wire signed [POSITION_SIZE-1:0] pos_y,
  input  wire signed [VELOCITY_SIZE-1:0] vel_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel_y,
  input  wire signed [POSITION_SIZE-1:0] dx,
  input  wire signed [POSITION_SIZE-1:0] dy,
  output logic signed [POSITION_SIZE - 1:0] x_new_out,
  output logic signed [POSITION_SIZE - 1:0] y_new_out,
  output logic signed [VELOCITY_SIZE-1:0] vx_new_out,
  output logic signed [VELOCITY_SIZE-1:0] vy_new_out,
  output logic signed [POSITION_SIZE-1:0] x_int_out,
  output logic signed [POSITION_SIZE-1:0] y_int_out,
  output logic signed [ACCELERATION_SIZE-1:0] acceleration_x_out,
  output logic signed [ACCELERATION_SIZE-1:0] acceleration_y_out,
  output logic collision,
  output logic output_valid
  
);
	typedef enum {IDLE = 0, INTERSECTION = 1, NEW_POS=2, MULTIPLY=3} coll_state;
	coll_state state = IDLE;
	//logic signed [POSITION_SIZE-1:0] dx,dy;
	logic signed [POSITION_SIZE-1:0] v1 [1:0];
	logic signed [POSITION_SIZE-1:0] v2 [1:0];


	

	logic signed [POSITION_SIZE- 1:0] x_new, y_new;
  	logic signed [VELOCITY_SIZE-1:0] vx_new, vy_new;
  	logic signed [POSITION_SIZE-1:0] x_int, y_int;
	
	logic signed [ACCELERATION_SIZE-1:0] acceleration_x, acceleration_y;
	

	//propeerly sized
	logic signed [2 * POSITION_SIZE+3-1:0] v_mag;
	logic signed [POSITION_SIZE+1 -1:0] rise,run;

	logic signed [POSITION_SIZE + VELOCITY_SIZE + 2  -1:0] v_parr, v_perp;  //recheck
	logic signed [2 * POSITION_SIZE + VELOCITY_SIZE + 3 -1:0] v_parr_x,v_parr_y, v_perp_x, v_perp_y; //recheck
	logic signed [2 * POSITION_SIZE + VELOCITY_SIZE + 4	 -1:0] vx_new_dividend, vy_new_dividend;

	logic signed [2 * POSITION_SIZE + 2 -1:0] r_parr, r_perp;
	logic signed [3 * POSITION_SIZE + 3  -1:0] r_parr_x,r_parr_y, r_perp_x, r_perp_y;
	logic signed [3 * POSITION_SIZE + 4	 -1:0] x_new_dividend, y_new_dividend;


	logic signed [2 * POSITION_SIZE+1 -1:0] t1;
	logic signed [2 * POSITION_SIZE+1 -1:0] t2;
	logic signed [3 * POSITION_SIZE + 3 - 1:0] x_int_dividend, y_int_dividend;
	logic signed [2 * POSITION_SIZE + 2 - 1:0] int_divisor;
	

    logic on_line;
	logic [5:0] divider_error;
	logic [5:0] divider_busy;


	//assign r_parr = ((pos_x + dx - x_int) * run + (pos_y + dy - y_int) * rise);
	//assign r_parr_x = r_parr * run;
	//assign r_parr_y = r_parr * rise;
	//assign r_perp = (pos_x + dx - x_int) * rise - (pos_y + dy - y_int) * run;
	//assign r_perp_x = r_perp * rise;
	//assign r_perp_y = ~(r_perp * run) + 2'sd1;

	logic signed [2 * POSITION_SIZE+2-1:0] product_1, product_2;
	logic signed [POSITION_SIZE+1-1:0] mult11, mult12, mult21, mult22;
	logic signed [3 * POSITION_SIZE + 3-1:0] product_3, product_4;
	logic signed [2 * POSITION_SIZE+2-1:0] mult31, mult41;
	logic signed [POSITION_SIZE+1-1:0] mult32, mult42;

    //mult1, mult2: POSITION_SIZE + 1, POSITION_SIZE+1 
	//product1,product2: 2 * POSITION_SIZE + 2 
	assign product_1 = mult11 * mult12;
	assign product_2 = mult21 * mult22;

	//mult: 2 * POSITION_SIZE + 2, POSITION_SIZE+1
	//product: 3 * POSITIONS_SIZE + 3
	assign product_3 = mult31 * mult32;
	assign product_4 = mult41 * mult42;


	assign rise = (v2[1]-v1[1]);
	assign run = (v2[0]-v1[0]);
	//assign int_divisor = dy*run-dx*rise;
	//assign t1 = (dy*pos_x-dx*pos_y);
	//assign t2 = (v2[0]*v1[1] - v1[0]*v2[1]);
	//assign x_int_dividend = run*t1 + dx*t2;
	//assign y_int_dividend = rise*t1 = dy * t2;

	logic signed [3 * POSITION_SIZE + 4-1:0] x_dividend, x_divisor, y_dividend,y_divisor;
	logic signed [POSITION_SIZE-1:0] x_quotient, y_quotient;
	logic x_valid, y_valid, x_valid_in, y_valid_in, vx_new_valid_in, vy_new_valid_in, vx_new_valid, vy_new_valid;

		
	//assign v_mag = run*run + rise * rise;

	//assign v_parr = vel_x * run + vel_y*rise;
	//assign v_parr_x = v_parr * run;
	//assign v_parr_y = v_parr * rise;
	//assign v_perp = vel_x * rise - vel_y*run;
	//assign v_perp_x = v_perp * rise;
	//assign v_perp_y = ~(v_perp * run) + 2'sd1;


	always_comb begin

		
		
        v1[0] = v1_in[0];
		v1[1] = v1_in[1];
		v2[0] = v2_in[0];
		v2[1] = v2_in[1];



		//optimization/ |v| / |r| * r_new = v_new
		acceleration_x = 0;//(~($signed(FRICTION) * v_parr_x)+2'sd1) / (v_mag * 5'sd16);
		acceleration_y = 0;//(~($signed(FRICTION) * v_parr_y)+2'sd1) / (v_mag * 5'sd16);
	end 

    divider #(.WIDTH(3 * POSITION_SIZE + 4), .OUT_SIZE(POSITION_SIZE)) x_divider (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(x_dividend),
                .divisor_in(x_divisor),
                .data_valid_in(x_valid_in),
                .quotient_out(x_quotient),
                //.remainder_out(x_remainder), //do we do anything with the remainder?
                .data_valid_out(x_valid),
                .error_out(divider_error[0]),
                .busy_out(divider_busy[0])
                );	

    divider #(.WIDTH(3 * POSITION_SIZE + 4), .OUT_SIZE(POSITION_SIZE)) y_divider (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(y_dividend),
                .divisor_in(y_divisor),
                .data_valid_in(y_valid_in),
                .quotient_out(y_quotient),
                //.remainder_out(x_remainder), //do we do anything with the remainder?
                .data_valid_out(y_valid),
                .error_out(divider_error[1]),
                .busy_out(divider_busy[1])
                );	

  divider #(.WIDTH(2 * POSITION_SIZE + VELOCITY_SIZE + 4), .OUT_SIZE(VELOCITY_SIZE)) vx_new_divider (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(vx_new_dividend),
                .divisor_in(v_mag),
                .data_valid_in(vx_new_valid_in),
                .quotient_out(vx_new),
                //.remainder_out(x_remainder), //do we do anything with the remainder?
                .data_valid_out(vx_new_valid),
                .error_out(divider_error[3]),
                .busy_out(divider_busy[3])
                );	

	divider #(.WIDTH(2 * POSITION_SIZE + VELOCITY_SIZE + 4),.OUT_SIZE(VELOCITY_SIZE)) vy_new_divider (
		.clk_in(clk_in),
		.rst_in(rst_in),
		.dividend_in(vy_new_dividend),
		.divisor_in(v_mag),
		.data_valid_in(vy_new_valid_in),
		.quotient_out(vy_new),
		//.remainder_out(x_remainder), //do we do anything with the remainder?
		.data_valid_out(vy_new_valid),
		.error_out(divider_error[4]),
		.busy_out(divider_busy[4])
	);	

	//dividers: x_new, y_new, x_int, y_int, accel_x, accel_y


    //for testing
   /* logic signed [POSITION_SIZE-1:0] test1, test2;
    assign test1 = 2 * rise;
    assign test2 = 2 * run; */



	logic [5:0] valids;
	logic [8:0] mult_num;

	//do x_int and vel, then new pos
	always_ff @(posedge clk_in) begin

		if (state != IDLE) begin
			if (vx_new_valid == 1) begin
				valids[0] <= 1;
				vx_new_out <= vx_new;
			end
			if (vy_new_valid == 1) begin
				valids[1] <= 1;
				vy_new_out <= vy_new;
			end			
		end

		case (state)
			IDLE: begin
				output_valid <= 0;
				if (input_valid) begin
					state <= MULTIPLY;
					valids[0] <= 0;
					valids[1] <= 0;
					valids[2] <= 0;
					valids[3] <= 0;
					valids[4] <= 0;
					valids[5] <= 0;
					mult_num <= 0;
					//t1
					mult11 <= dy;
					mult12 <= pos_x;
					mult21 <= dx;
					mult22 <= pos_y;

				end
			end
			MULTIPLY: begin
				mult_num <= mult_num + 1;
				case (mult_num)
					0: begin
						t1 <= product_1 - product_2;

						//t2
						mult11 <= v2[0];
						mult12 <= v1[1];
						mult21 <= v1[0];
						mult22 <= v2[1];
					end
					1: begin
						t2 <= product_1 - product_2;
						//int_divisor
						mult11 <= dy;
						mult12 <= run;
						mult21 <= dx;
						mult22 <= rise;

						//x_int_dividend
						mult31 <= t1;
						mult32 <= run;
						mult41 <= product_1 - product_2;
						mult42 <= dx;
					end
					2: begin
						//check if it is going inside the obstacle
						//
						if (product_1 >= product_2)  begin
							collision <= 0;
							state <= IDLE;
							output_valid <= 1;
						end else begin
							//int_divisor <= product1 - product2; also don't need int_divisor
							//x_int_dividend <= product_3 + product_4; don't need x_int_dividend
							x_dividend <= product_3 + product_4; //x_int_dividend
							x_divisor <= product_1 - product_2; //int_divisor
							y_divisor <= product_1 - product_2; //int_divisor

							//v_perp
							mult11 <= vel_x;
							mult12 <= rise;
							mult21 <= vel_y;
							mult22 <= run;

							//denom * pos_x, denom * dx
							mult31 <= product_1 - product_2; //denom
							mult32 <= pos_x;
							mult41 <= product_1 - product_2; //denom
							mult42 <= dx;
						end


					end
					3: begin
						//check if x intersection is within x bounds
						if (((product_3 <= x_dividend) && ((product_3 + product_4) >= x_dividend))
						||((product_3 >= x_dividend) && ((product_3 + product_4) <= x_dividend))) begin
							v_perp <= product_1 - product_2;

							//v_parr
							mult11 <= vel_x;
							mult12 <= run;
							mult21 <= vel_y;
							mult22 <= rise;
							
							//y_int_dividend
							mult31 <= t1;
							mult32 <= rise;
							mult41 <= t2;
							mult42 <= dy;

						end else begin
							collision <= 0;
							state <= IDLE;
							output_valid <= 1;
						end

					end
					4: begin
		
						v_parr <= product_1 + product_2;
						//y_int_dividend <= product_3 + product_4; don't need y_int_dividend
						//y_int ready
						y_dividend <= product_3 + product_4; //y_int_dividend

						//v_mag
						mult11 <= run;
						mult12 <= run;
						mult21 <= rise;
						mult22 <= rise;

						//denom * pos_y, denom * dy
						mult31 <= y_divisor; //denom
						mult32 <= pos_y;
						mult41 <= y_divisor; //denom
						mult42 <= dy;




					end
					5: begin
						//cheching if intersection is within y bounds
						if (((product_3 <= y_dividend) && ((product_3 + product_4) >= y_dividend))
						||((product_3 >= y_dividend) && ((product_3 + product_4) <= y_dividend))) begin
							//all checks passed and there is a collision, continue
							collision <= 1;

							v_mag <= product_1 + product_2;
							//start the dividers
							x_valid_in <= 1;
							y_valid_in <= 1;

							//v_parr_x, v_parr_y
							mult31 <= v_parr;
							mult32 <= run;
							mult41 <= v_parr;
							mult42 <= rise;							

						end else begin
							collision <= 0;
							state <= IDLE;
							output_valid <= 1;
						end


					end
					6: begin

						v_parr_x <= product_3;
						v_parr_y <= product_4;

						x_valid_in <= 0;
						y_valid_in <= 0;

						//v_perp_x, v_perp_y
						mult31 <= v_perp;
						mult32 <= rise;
						mult41 <= v_perp;
						mult42 <= run;
					end
					7: begin
						v_perp_x <= product_3;
						v_perp_y <= ~product_4 + 2'sd1;

						
						vx_new_dividend <= (v_parr_x - product_3);
						vy_new_dividend <= (v_parr_y + product_4);

						state <= INTERSECTION;
						vx_new_valid_in <= 1;
						vy_new_valid_in <= 1;
					end
					8: begin

						//start for r_parr in divide
						r_parr <= product_1 + product_2;

						//r_perp
						mult11 <= (pos_x + dx - x_int);
						mult12 <= rise;
						mult21 <= (pos_y + dy - y_int);
						mult22 <= run;

						//r_parr_x, r_parr_y
						mult31 <= product_1 + product_2;
						mult32 <= run;
						mult41 <= product_1 + product_2;
						mult42 <= rise;	



					end
					9: begin

						r_parr_x <= product_3;
						r_parr_y <= product_4;

						r_perp <= product_1 - product_2;

						//r_perp_x, r_perp_y
						mult31 <= product_1 - product_2;
						mult32 <= rise;
						mult41 <= product_2 - product_1;
						mult42 <= run;

					end
					10: begin
						//x_new_dividend = (r_parr_x - r_perp_x);
						//y_new_dividend = (r_parr_y - r_perp_y);
						r_perp_x <= product_3;
						r_perp_y <= product_4;

						state <= NEW_POS;
						x_valid_in <= 1;
						y_valid_in <= 1;
						x_dividend <= r_parr_x - product_3;
						y_dividend <= r_parr_y - product_4;
						x_divisor <= v_mag;
						y_divisor <= v_mag;
					end

				endcase

				if (x_valid == 1) begin
					x_int <= x_quotient;
					valids[4] <= 1;
				end
				if (y_valid == 1) begin
					y_int <= y_quotient;
					valids[5] <= 1;
				end

			end

			INTERSECTION: begin
				vx_new_valid_in <= 0;
				vy_new_valid_in <= 0;

				if (x_valid == 1) begin
					x_int <= x_quotient;
					valids[4] <= 1;
				end
				if (y_valid == 1) begin
					y_int <= y_quotient;
					valids[5] <= 1;
				end

				if (valids[5:4] == 2'b11) begin	
					state <= MULTIPLY;

					//r_parr
					mult11 <= (pos_x + dx - x_int);
					mult12 <= run;
					mult21 <= (pos_y + dy - y_int);
					mult22 <= rise;


				end
			end
			NEW_POS: begin
				x_valid_in <= 0;
				y_valid_in <= 0;
				if (x_valid == 1) begin
					x_new_out <= x_int + x_quotient;
					valids[2] <= 1;
				end
				if (y_valid == 1) begin
					y_new_out <= y_int + y_quotient;
					valids[3] <= 1;
				end
				if (valids[3:0] == 4'b1111) begin	 
					state <= IDLE;
					x_int_out <= x_int;
					y_int_out <= y_int;
					acceleration_x_out <= acceleration_x;
					acceleration_y_out <= acceleration_y;
					output_valid <= 1;
				end
			end
		endcase
	end	
	
endmodule
	typedef enum {IDLE = 0, INTERSECTION = 1, NEW_POS=2, MULTIPLY=3} coll_state;


/*
	assign r_parr = ((pos_x + dx) * run + (pos_y + dy) * rise); - x_int * run - y_int * rise
	assign r_parr_x = r_parr * run; (- x_int * run - y_int * rise) * run
	assign r_parr_y = r_parr * rise; (- x_int * run - y_int * rise) * rise

	assign r_perp = (pos_x + dx) * rise - (pos_y + dy) * run; - x_int * rise -y_int * run
	assign r_perp_x = r_perp * rise; (- x_int * rise -y_int * run) * rise
	assign r_perp_y = ~(r_perp * run) + 2'sd1; (x_int * rise  + y_int * run) * run
	*/

	/*
	assign v_mag = run*run + rise * rise;
	assign rise = (v2[1]-v1[1]);
	assign run = (v2[0]-v1[0]);
	assign denom = dy*run-dx*rise;
	assign t1 = 0
	assign t2 = (v2[0]*v1[1] - v1[0]*v2[1]);
	assign x_num = dx*t2;
	assign y_num = t2 * dy; 

	assign v_mag = run*run + rise * rise;
	assign rise = (v2[1]-v1[1]);
	assign run = (v2[0]-v1[0]);
	assign denom = dy*run-dx*rise;
	assign t1 = (dy*pos_x-dx*pos_y);
	assign t2 = (v2[0]*v1[1] - v1[0]*v2[1]);
	assign x_num = run*t1 + dx*t2;
	assign y_num = ~(rise*(dx*pos_y-dy*pos_x) + dy*((v2[1]*v1[0] - v1[1]*v2[0]))) + 2'sd1;*/