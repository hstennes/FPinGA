`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
 
  //your code here.

  logic [4:0] count;
  logic [4:0] new_count;
  logic [4:0] diff;
  logic [4:0] offset_q_8;
  logic [3:0] n1;
  logic [9:0] temp_out;
  logic balanced;
  logic invert;

  always_comb begin
    n1 = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    balanced = count == 0 || n1 == 4;
    temp_out[9] = balanced ? ~q_m[8] : ((count[4] == 0 && n1 > 4) || (count[4] == 1 && n1 < 4));
    temp_out[8] = q_m[8];
    temp_out[7:0] = temp_out[9] ? ~q_m[7:0] : q_m[7:0];
    diff = n1 - (5'b01000 - n1);
    offset_q_8 = temp_out[9] ? (2 * q_m[8]) : (-2 * (!q_m[8]));
    new_count = count + (temp_out[9] ? (-diff) : (diff)) + (balanced ? 0 : offset_q_8);
  end

  always_ff @(posedge clk_in) begin
    count <= (rst_in == 1 || ve_in == 0) ? 0 : new_count;
    tmds_out <= ve_in ? temp_out : (control_in == 2'b00 ? 10'b1101010100 : (control_in == 2'b01 ? 10'b0010101011 : (control_in == 2'b10 ? 10'b0101010100 : 10'b1010101011)));
  end
 
endmodule
 
`default_nettype wire