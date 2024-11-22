`timescale 1ns / 1ps
`default_nettype none

module quadratic #(parameter SIZE) (
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

  //TOTAL LATENCY: 94

  localparam PIPE_A_LATENCY = 65;
  localparam PIPE_B_LATENCY = 50;

  logic [SIZE-1:0] b_sq_result;
  logic b_sq_valid;

  logic [SIZE-1:0] ac_result;
  logic ac_valid;

  logic disc_b_sq_ready;
  logic disc_ac_ready;
  logic [SIZE-1:0] disc_result;
  logic disc_valid;

  logic sqrt_ready;
  logic [SIZE-1:0] sqrt_result;
  logic sqrt_valid;

  logic [SIZE-1:0] pipe_a_result;
  logic pipe_a_valid;

  logic [SIZE-1:0] pipe_b_result;
  logic pipe_b_valid;

  logic pm_p_nb_ready;
  logic pm_p_sqrt_ready;
  logic [SIZE-1:0] pm_p_result;
  logic pm_p_valid;

  logic pm_m_nb_ready;
  logic pm_m_sqrt_ready;
  logic [SIZE-1:0] pm_m_result;
  logic pm_m_valid;

  logic cmp_a_ready;
  logic cmp_b_ready;
  logic [SIZE-1:0] cmp_result;
  logic cmp_valid;

  logic div_num_ready;
  logic div_den_ready;
  
  float_mul b_sq(
    .s_axis_a_tdata(s_axis_b_tdata),
    .s_axis_a_tready(s_axis_b_tready),
    .s_axis_a_tvalid(s_axis_b_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(b_sq_result),
    .m_axis_result_tready(disc_b_sq_ready),
    .m_axis_result_tvalid(b_sq_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_mul ac(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_c_tdata),
    .s_axis_b_tready(s_axis_c_tready),
    .s_axis_b_tvalid(s_axis_c_tvalid),
    .m_axis_result_tdata(ac_result),
    .m_axis_result_tready(disc_ac_ready),
    .m_axis_result_tvalid(ac_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [SIZE-1:0] scale_ac_result;

  float_mul_pow2 #(.SIZE(SIZE), .POW(2), .NEGATE(1)) scale_ac(
    .in_float(ac_result),
    .result(scale_ac_result)
  );

  float_add disc(
    .s_axis_a_tdata(b_sq_result),
    .s_axis_a_tready(disc_b_sq_ready),
    .s_axis_a_tvalid(b_sq_valid),
    .s_axis_b_tdata(scale_ac_result), //* -4
    .s_axis_b_tready(disc_ac_ready),
    .s_axis_b_tvalid(ac_valid),
    .m_axis_result_tdata(disc_result),
    .m_axis_result_tready(sqrt_ready),
    .m_axis_result_tvalid(disc_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_sqrt sqrt(
    .s_axis_a_tdata(disc_result),
    .s_axis_a_tready(sqrt_ready),
    .s_axis_a_tvalid(disc_valid),
    .m_axis_result_tdata(sqrt_result),
    .m_axis_result_tvalid(sqrt_valid),
    .m_axis_result_tready(pm_p_sqrt_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_A_LATENCY)) pipe_a(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(pipe_a_result),
    .m_axis_result_tvalid(pipe_a_valid),
    .m_axis_result_tready(div_den_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_B_LATENCY)) pipe_b(
    .s_axis_a_tdata(s_axis_b_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_b_tvalid),
    .m_axis_result_tdata(pipe_b_result),
    .m_axis_result_tvalid(pipe_b_valid),
    .m_axis_result_tready(pm_p_nb_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_add pm_p (
    .s_axis_a_tdata({~pipe_b_result[SIZE-1], pipe_b_result[SIZE-2:0]}),
    .s_axis_a_tready(pm_p_nb_ready),
    .s_axis_a_tvalid(pipe_b_valid),
    .s_axis_b_tdata(sqrt_result),
    .s_axis_b_tready(pm_p_sqrt_ready),
    .s_axis_b_tvalid(sqrt_valid),
    .m_axis_result_tdata(pm_p_result),
    .m_axis_result_tvalid(pm_p_valid),
    .m_axis_result_tready(cmp_a_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_add pm_m (
    .s_axis_a_tdata({~pipe_b_result[SIZE-1], pipe_b_result[SIZE-2:0]}),
    .s_axis_a_tready(pm_m_nb_ready),
    .s_axis_a_tvalid(pipe_b_valid),
    .s_axis_b_tdata({~sqrt_result[SIZE-1], sqrt_result[SIZE-2:0]}),
    .s_axis_b_tready(pm_m_sqrt_ready),
    .s_axis_b_tvalid(sqrt_valid),
    .m_axis_result_tdata(pm_m_result),
    .m_axis_result_tvalid(pm_m_valid),
    .m_axis_result_tready(cmp_b_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_min #(.SIZE(SIZE)) cmp (
    .s_axis_a_tdata(pm_p_result),
    .s_axis_a_tready(cmp_a_ready),
    .s_axis_a_tvalid(pm_p_valid),
    .s_axis_b_tdata(pm_m_result),
    .s_axis_b_tready(cmp_b_ready),
    .s_axis_b_tvalid(pm_m_valid),
    .m_axis_result_tdata(cmp_result),
    .m_axis_result_tvalid(cmp_valid),
    .m_axis_result_tready(div_num_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [SIZE-1:0] scale_pipe_a_result;

  float_mul_pow2 #(.SIZE(SIZE), .POW(1)) scale_pipe_a(
    .in_float(pipe_a_result),
    .result(scale_pipe_a_result)
  );

  float_div div(
    .s_axis_a_tdata(cmp_result),
    .s_axis_a_tready(div_num_ready),
    .s_axis_a_tvalid(cmp_valid),
    .s_axis_b_tdata(scale_pipe_a_result), //* 2
    .s_axis_b_tready(div_den_ready),
    .s_axis_b_tvalid(pipe_a_valid),
    .m_axis_result_tdata(m_axis_result_tdata),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire