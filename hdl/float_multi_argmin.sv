`timescale 1ns / 1ps
`default_nettype none

module float_multi_argmin #(parameter SIZE=64) (
  input wire [15:0][SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  output logic [3:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  localparam CMP_LATENCY = 3;

  logic cmp_11_valid;
  logic [SIZE+3:0] cmp_11_result;

  logic cmp_12_valid;
  logic[SIZE+3:0] cmp_12_result;

  logic cmp_13_valid;
  logic [SIZE+3:0] cmp_13_result; 

  logic cmp_14_valid;
  logic [SIZE+3:0] cmp_14_result;

  logic cmp_15_valid;
  logic [SIZE+3:0] cmp_15_result;

  logic cmp_16_valid;
  logic [SIZE+3:0] cmp_16_result;

  logic cmp_17_valid;
  logic[SIZE+3:0]  cmp_17_result;

  logic cmp_18_valid;
  logic[SIZE+3:0] cmp_18_result;

  logic cmp_21_ready;
  logic [SIZE+3:0] cmp_21_result;
  logic cmp_21_valid;

  logic cmp_22_ready;
  logic [SIZE+3:0] cmp_22_result;
  logic cmp_22_valid;

  logic cmp_23_ready;
  logic [SIZE+3:0] cmp_23_result;
  logic cmp_23_valid;

  logic cmp_24_ready;
  logic [SIZE+3:0] cmp_24_result;
  logic cmp_24_valid;

  logic cmp_31_ready;
  logic [SIZE+3:0] cmp_31_result;
  logic cmp_31_valid;

  logic cmp_32_ready;
  logic [SIZE+3:0] cmp_32_result;
  logic cmp_32_valid;

  logic cmp_41_ready;
  logic [SIZE+3:0] cmp_41_result;

  assign m_axis_result_tdata = cmp_41_result[3:0];

  float_argmin #(.SIZE(SIZE)) cmp_11 (
    .s_axis_a_tdata({s_axis_a_tdata[0], 4'b0}),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[1], 4'b1}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_11_result),
    .m_axis_result_tvalid(cmp_11_valid),
    .m_axis_result_tready(cmp_21_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_12 (
    .s_axis_a_tdata({s_axis_a_tdata[2], 4'b10}),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[3], 4'b11}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_12_result),
    .m_axis_result_tvalid(cmp_12_valid),
    .m_axis_result_tready(cmp_21_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_13 (
    .s_axis_a_tdata({s_axis_a_tdata[4], 4'b100}),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[5], 4'b101}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_13_result),
    .m_axis_result_tvalid(cmp_13_valid),
    .m_axis_result_tready(cmp_22_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_14 (
    .s_axis_a_tdata({s_axis_a_tdata[6], 4'b110}),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[7], 4'b111}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_14_result),
    .m_axis_result_tvalid(cmp_14_valid),
    .m_axis_result_tready(cmp_22_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_15 (
    .s_axis_a_tdata({s_axis_a_tdata[8], 4'b1000}),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[9], 4'b1001}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_15_result),
    .m_axis_result_tvalid(cmp_15_valid),
    .m_axis_result_tready(cmp_23_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_16 (
    .s_axis_a_tdata({s_axis_a_tdata[10], 4'b1010}),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[11], 4'b1011}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_16_result),
    .m_axis_result_tvalid(cmp_16_valid),
    .m_axis_result_tready(cmp_23_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_17 (
    .s_axis_a_tdata({s_axis_a_tdata[12], 4'b1100}),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[13], 4'b1101}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_17_result),
    .m_axis_result_tvalid(cmp_17_valid),
    .m_axis_result_tready(cmp_24_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_18 (
    .s_axis_a_tdata({s_axis_a_tdata[14], 4'b1110}),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata({s_axis_a_tdata[15], 4'b1111}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(cmp_18_result),
    .m_axis_result_tvalid(cmp_18_valid),
    .m_axis_result_tready(cmp_24_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_21 (
    .s_axis_a_tdata(cmp_11_result),
    .s_axis_a_tready(cmp_21_ready),
    .s_axis_a_tvalid(cmp_11_valid),
    .s_axis_b_tdata(cmp_12_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(cmp_12_valid),
    .m_axis_result_tdata(cmp_21_result),
    .m_axis_result_tvalid(cmp_21_valid),
    .m_axis_result_tready(cmp_31_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_22 (
    .s_axis_a_tdata(cmp_13_result),
    .s_axis_a_tready(cmp_22_ready),
    .s_axis_a_tvalid(cmp_13_valid),
    .s_axis_b_tdata(cmp_14_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(cmp_14_valid),
    .m_axis_result_tdata(cmp_22_result),
    .m_axis_result_tvalid(cmp_22_valid),
    .m_axis_result_tready(cmp_31_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_23 (
    .s_axis_a_tdata(cmp_15_result),
    .s_axis_a_tready(cmp_23_ready),
    .s_axis_a_tvalid(cmp_15_valid),
    .s_axis_b_tdata(cmp_16_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(cmp_16_valid),
    .m_axis_result_tdata(cmp_23_result),
    .m_axis_result_tvalid(cmp_23_valid),
    .m_axis_result_tready(cmp_32_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_24 (
    .s_axis_a_tdata(cmp_17_result),
    .s_axis_a_tready(cmp_24_ready),
    .s_axis_a_tvalid(cmp_17_valid),
    .s_axis_b_tdata(cmp_18_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(cmp_18_valid),
    .m_axis_result_tdata(cmp_24_result),
    .m_axis_result_tvalid(cmp_24_valid),
    .m_axis_result_tready(cmp_32_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_31 (
    .s_axis_a_tdata(cmp_21_result),
    .s_axis_a_tready(cmp_31_ready),
    .s_axis_a_tvalid(cmp_21_valid),
    .s_axis_b_tdata(cmp_22_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(cmp_22_valid),
    .m_axis_result_tdata(cmp_31_result),
    .m_axis_result_tvalid(cmp_31_valid),
    .m_axis_result_tready(cmp_41_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_32 (
    .s_axis_a_tdata(cmp_23_result),
    .s_axis_a_tready(cmp_32_ready),
    .s_axis_a_tvalid(cmp_23_valid),
    .s_axis_b_tdata(cmp_24_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(cmp_24_valid),
    .m_axis_result_tdata(cmp_32_result),
    .m_axis_result_tvalid(cmp_32_valid),
    .m_axis_result_tready(cmp_41_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_argmin #(.SIZE(SIZE)) cmp_41 (
    .s_axis_a_tdata(cmp_31_result),
    .s_axis_a_tready(cmp_41_ready),
    .s_axis_a_tvalid(cmp_31_valid),
    .s_axis_b_tdata(cmp_32_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(cmp_32_valid),
    .m_axis_result_tdata(cmp_41_result),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire