`timescale 1ns / 1ps
`default_nettype none

module float_sum3 #(parameter SIZE) (
  input wire [SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  input wire [SIZE-1:0] s_axis_b_tdata,
  output logic s_axis_b_tready,
  input wire s_axis_b_tvalid,
  input wire [SIZE-1:0] s_axis_c_tdata,
  output logic s_axis_c_tready,
  input wire s_axis_c_tvalid,
  output logic [SIZE-1:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 18

  localparam PIPE_LATENCY = 9;

  logic [SIZE-1:0] sum1_result;
  logic sum1_valid;

  logic [SIZE-1:0] pipe_result;
  logic pipe_valid;

  logic sum2_a_ready;
  logic sum2_b_ready;
  
  float_add sum1(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata),
    .s_axis_b_tready(s_axis_b_tready),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(sum1_result),
    .m_axis_result_tready(sum2_a_ready),
    .m_axis_result_tvalid(sum1_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_LATENCY)) pipe(
    .s_axis_a_tdata(s_axis_c_tdata),
    .s_axis_a_tready(s_axis_c_tready),
    .s_axis_a_tvalid(s_axis_c_tvalid),
    .m_axis_result_tdata(pipe_result),
    .m_axis_result_tready(sum2_b_ready),
    .m_axis_result_tvalid(pipe_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_add sum2(
    .s_axis_a_tdata(sum1_result),
    .s_axis_a_tready(sum2_a_ready),
    .s_axis_a_tvalid(sum1_valid),
    .s_axis_b_tdata(pipe_result),
    .s_axis_b_tready(sum2_b_ready),
    .s_axis_b_tvalid(pipe_valid),
    .m_axis_result_tdata(m_axis_result_tdata),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire