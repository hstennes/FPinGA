`timescale 1ns / 1ps
`default_nettype none

module vec_to_pixel_color #(parameter SIZE) (
  input wire [2:0][SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  output logic [23:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  logic [2:0][SIZE-1:0] clamp_result;
  logic clamp_valid;

  logic fltofi_ready;

  logic [SIZE-1:0] fltofi1_result;

  logic [SIZE-1:0] fltofi2_result;

  logic [SIZE-1:0] fltofi3_result;
  
  vec_clamp #(.SIZE(SIZE)) clamp(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(clamp_result),
    .m_axis_result_tready(fltofi_ready),
    .m_axis_result_tvalid(clamp_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_to_fixed #(.SIZE(SIZE)) ff1 (
    .s_axis_a_tdata(clamp_result[0]),
    .s_axis_a_tready(fltofi_ready),
    .s_axis_a_tvalid(clamp_valid),
    .m_axis_result_tdata(fltofi1_result),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_to_fixed #(.SIZE(SIZE)) ff2 (
    .s_axis_a_tdata(clamp_result[1]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(clamp_valid),
    .m_axis_result_tdata(fltofi2_result),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tvalid(),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_to_fixed #(.SIZE(SIZE)) ff3 (
    .s_axis_a_tdata(clamp_result[2]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(clamp_valid),
    .m_axis_result_tdata(fltofi3_result),
    .m_axis_result_tready(m_axis_result_tready),
    .m_axis_result_tvalid(),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  assign m_axis_result_tdata = {fltofi3_result[7:0], fltofi2_result[7:0], fltofi1_result[7:0]};

endmodule
`default_nettype wire