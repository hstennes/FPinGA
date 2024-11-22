`timescale 1ns / 1ps
`default_nettype none

module vec_mul #(parameter SIZE) (
  input wire [2:0][SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  input wire [SIZE-1:0] s_axis_b_tdata,
  output logic s_axis_b_tready,
  input wire s_axis_b_tvalid,
  output logic [2:0][SIZE-1:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 9
  
  float_mul mul1(
    .s_axis_a_tdata(s_axis_a_tdata[0]),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata),
    .s_axis_b_tready(s_axis_b_tready),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(m_axis_result_tdata[0]),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_mul mul2(
    .s_axis_a_tdata(s_axis_a_tdata[1]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(m_axis_result_tdata[1]),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tvalid(),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_mul mul3(
    .s_axis_a_tdata(s_axis_a_tdata[2]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(m_axis_result_tdata[2]),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tvalid(),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire