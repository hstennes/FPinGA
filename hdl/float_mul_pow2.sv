`timescale 1ns / 1ps
`default_nettype none

module float_mul_pow2 #(parameter SIZE, POW=1, NEGATE=0) (
  input wire [SIZE-1:0] in_float,
  output logic [SIZE-1:0] result);

  localparam EXP_WIDTH = (SIZE == 32) ? 8 : 11;
  localparam MANT_WIDTH = (SIZE == 32) ? 23 : 52;

  logic sign;
  logic [EXP_WIDTH-1:0] exponent;
  logic [MANT_WIDTH-1:0] mantissa;

  assign sign = NEGATE == 1 ? ~in_float[SIZE-1] : in_float[SIZE-1];
  assign exponent = in_float[SIZE-2 -: EXP_WIDTH] + POW;
  assign mantissa = in_float[MANT_WIDTH-1:0];

  assign result = {sign, exponent, mantissa};

endmodule
`default_nettype wire