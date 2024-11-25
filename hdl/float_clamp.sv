`timescale 1ns / 1ps
`default_nettype none

//clamps float value to between 0 and 255
module float_clamp #(parameter SIZE) (
  input wire [SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  output logic [SIZE-1:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  localparam [SIZE-1:0] MAX = 64'h406FE00000000000;
  // localparam [SIZE-1:0] MAX = 32'h437f0000;

  logic [SIZE-1:0] min_result;

  float_min #(.SIZE(SIZE)) min (
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(MAX),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(1'b1),
    .m_axis_result_tdata(min_result),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  assign m_axis_result_tdata = min_result[SIZE-1] ? 0 : min_result;

endmodule
`default_nettype wire