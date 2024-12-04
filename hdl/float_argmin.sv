`timescale 1ns / 1ps
`default_nettype none

module float_argmin #(parameter SIZE) (
  input wire [SIZE+3:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  input wire [SIZE+3:0] s_axis_b_tdata,
  output logic s_axis_b_tready,
  input wire s_axis_b_tvalid,
  output logic [SIZE+3:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  localparam CMP_LATENCY = 3;

  logic [7:0] cmp_result;

  logic [SIZE+3:0] pipe_a_result;

  logic [SIZE+3:0] pipe_b_result;

  assign m_axis_result_tdata = cmp_result[0] ? pipe_a_result : pipe_b_result;

  axi_pipe #(.LATENCY(CMP_LATENCY), .SIZE(SIZE+4)) pipe_a(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(pipe_a_result),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(CMP_LATENCY), .SIZE(SIZE+4)) pipe_b(
    .s_axis_a_tdata(s_axis_b_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(pipe_b_result),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );
  
  float_lt cmp (
    .s_axis_a_tdata(s_axis_a_tdata[SIZE+3:4]),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata[SIZE+3:4]),
    .s_axis_b_tready(s_axis_b_tready),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(cmp_result),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire