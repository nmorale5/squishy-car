`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module multiplier_sim (
    input wire CLK,
    input wire signed [17:0] A,
    input wire signed [17:0] B,
    output logic signed [35:0] P
  );

  logic signed [35:0] mul_outs [3];

  always_ff @(posedge CLK) begin
    mul_outs[0] <= A * B;
    for (int i = 1; i < 3; i = i + 1) begin
      mul_outs[i] <= mul_outs[i - 1];
    end
  end

  assign P = mul_outs[2];

endmodule

`default_nettype wire