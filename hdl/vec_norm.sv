`timescale 1ns / 1ps
`default_nettype none

module vec_norm #(parameter SIZE) (
  input wire [2:0][SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  output logic [SIZE-1:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 59

  logic [SIZE-1:0] dot_result;
  logic dot_valid;

  logic sqrt_ready;
  
  vec_dot dot(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_a_tdata),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(dot_result),
    .m_axis_result_tready(sqrt_ready),
    .m_axis_result_tvalid(dot_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_sqrt sqrt(
    .s_axis_a_tdata(dot_result),
    .s_axis_a_tready(sqrt_ready),
    .s_axis_a_tvalid(dot_valid),
    .m_axis_result_tdata(m_axis_result_tdata),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire