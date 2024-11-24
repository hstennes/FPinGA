`timescale 1ns / 1ps
`default_nettype none

module ray_intersect #(parameter SIZE) (
  input wire [5:0][SIZE-1:0] obj_axis_tdata,
  input wire obj_axis_is_cylinder,
  output logic obj_axis_tready,
  input wire obj_axis_tvalid,
  input wire [5:0][SIZE-1:0] ray_axis_tdata,
  output logic ray_axis_tready,
  input wire ray_axis_tvalid,
  output logic [SIZE-1:0] t_axis_tdata,
  output logic undef_axis_tdata,
  input wire t_axis_tready,
  output logic t_axis_tvalid,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 168

  localparam PIPE_D_LATENCY = 12;
  localparam PIPE_CA_LATENCY = 12;
  localparam PIPE_DCA_LATENCY = 12;
  localparam PIPE_A_LATENCY = 24;
  localparam PIPE_B_LATENCY = 12;
  localparam PIPE_OCOC_LATENCY = 17;
  localparam PIPE_FLAG_PREC_LATENCY = 45;
  localparam PIPE_FLAG_QUAD_LATENCY = 74;
  localparam PIPE_FLAG_FINAL_LATENCY = 168;

  // localparam NEG_SPHERE_RAD_SQ = 64'hBFF0000000000000;
  // localparam NEG_CYLINDER_RAD_SQ = 64'hBFDF5C28F5C28F5C;

  localparam [SIZE-1:0] NEG_SPHERE_RAD_SQ = 32'hbf800000;;
  localparam [SIZE-1:0] NEG_CYLINDER_RAD_SQ = 32'hbefae148;

  logic [2:0][SIZE-1:0] oc_result;
  logic oc_valid;

  logic [SIZE-1:0] dd_result;
  logic dd_valid;

  logic [SIZE-1:0] dca_result;
  logic dca_valid;

  logic ococ_ready;
  logic [SIZE-1:0] ococ_result;
  logic ococ_valid;

  logic [2:0][SIZE-1:0] pipe_d_result;
  logic pipe_d_valid;

  logic [2:0][SIZE-1:0] pipe_ca_result;
  logic pipe_ca_valid;

  logic pipe_is_cylinder_result;
  logic pipe_is_cylinder_valid;

  logic pipe_flag_prec_result;
  logic pipe_flag_prec_valid;
  logic pipe_flag_quad_result;
  logic pipe_flag_quad_valid;
  logic pipe_flag_final_result;
  logic pipe_flag_final_valid;

  logic pipe_dca_ready;
  logic [SIZE-1:0] pipe_dca_result;
  logic pipe_dca_valid;

  logic ocd_oc_ready;
  logic ocd_d_ready;
  logic [SIZE-1:0] ocd_result;
  logic ocd_valid;

  logic occa_oc_ready;
  logic occa_ca_ready;
  logic [SIZE-1:0] occa_result;
  logic occa_valid;

  logic a_dd_ready;
  logic a_dca_ready;
  logic [SIZE-1:0] a_result;
  logic a_valid;

  logic prec_occa_ready;
  logic prec_radius_ready;
  logic [SIZE-1:0] prec_result;
  logic prec_valid;

  logic b_ocd_ready;
  logic b_occa_ready;
  logic b_dca_ready;
  logic [SIZE-1:0] b_result;
  logic b_valid;

  logic c_prec_ready;
  logic c_ococ_ready;
  logic [SIZE-1:0] c_result;
  logic c_valid;

  logic pipe_ococ_ready;
  logic [SIZE-1:0] pipe_ococ_result;
  logic pipe_ococ_valid;

  logic pipe_a_ready;
  logic [SIZE-1:0] pipe_a_result;
  logic pipe_a_valid;

  logic pipe_b_ready;
  logic [SIZE-1:0] pipe_b_result;
  logic pipe_b_valid;

  logic quad_a_ready;
  logic quad_b_ready;
  logic quad_c_ready;

  logic [2:0][SIZE-1:0] neg_valid_obj_loc;
  logic [2:0][SIZE-1:0] valid_obj_dir;
  logic valid_is_cylinder;

  logic [SIZE*3-1:0] neg_obj_loc;
  assign neg_obj_loc = {{~obj_axis_tdata[2][SIZE-1], obj_axis_tdata[2][SIZE-2:0]}, {~obj_axis_tdata[1][SIZE-1], obj_axis_tdata[1][SIZE-2:0]}, {~obj_axis_tdata[0][SIZE-1], obj_axis_tdata[0][SIZE-2:0]}};

  vec_add #(.SIZE(SIZE)) oc(
    .s_axis_a_tdata(ray_axis_tdata[2:0]),
    .s_axis_a_tready(ray_axis_tready),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .s_axis_b_tdata(neg_obj_loc),
    .s_axis_b_tready(obj_axis_tready),
    .s_axis_b_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(oc_result),
    .m_axis_result_tready(ocd_oc_ready),
    .m_axis_result_tvalid(oc_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) dd(
    .s_axis_a_tdata(ray_axis_tdata[5:3]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .s_axis_b_tdata(ray_axis_tdata[5:3]),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(ray_axis_tvalid),
    .m_axis_result_tdata(dd_result),
    .m_axis_result_tready(pipe_a_ready),
    .m_axis_result_tvalid(dd_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) dca(
    .s_axis_a_tdata(ray_axis_tdata[5:3]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .s_axis_b_tdata(obj_axis_tdata[5:3]),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(dca_result),
    .m_axis_result_tready(pipe_a_ready),
    .m_axis_result_tvalid(dca_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_D_LATENCY), .SIZE(SIZE*3)) pipe_d(
    .s_axis_a_tdata(ray_axis_tdata[5:3]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .m_axis_result_tdata(pipe_d_result),
    .m_axis_result_tvalid(pipe_d_valid),
    .m_axis_result_tready(ocd_d_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_DCA_LATENCY), .SIZE(SIZE)) pipe_dca(
    .s_axis_a_tdata(dca_result),
    .s_axis_a_tready(pipe_dca_ready),
    .s_axis_a_tvalid(dca_valid),
    .m_axis_result_tdata(pipe_dca_result),
    .m_axis_result_tvalid(pipe_dca_valid),
    .m_axis_result_tready(b_dca_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_CA_LATENCY), .SIZE(SIZE*3)) pipe_ca(
    .s_axis_a_tdata(obj_axis_tdata[5:3]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(pipe_ca_result),
    .m_axis_result_tvalid(pipe_ca_valid),
    .m_axis_result_tready(occa_ca_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_FLAG_PREC_LATENCY), .SIZE(1)) pipe_flag_prec(
    .s_axis_a_tdata(obj_axis_is_cylinder),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(pipe_flag_prec_result),
    .m_axis_result_tvalid(pipe_flag_prec_valid),
    .m_axis_result_tready(prec_radius_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_FLAG_QUAD_LATENCY), .SIZE(1)) pipe_flag_quad(
    .s_axis_a_tdata(obj_axis_is_cylinder),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(pipe_flag_quad_result),
    .m_axis_result_tvalid(pipe_flag_quad_valid),
    .m_axis_result_tready(quad_a_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_FLAG_FINAL_LATENCY), .SIZE(1)) pipe_flag_final(
    .s_axis_a_tdata(obj_axis_is_cylinder),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(pipe_flag_final_result),
    .m_axis_result_tvalid(pipe_flag_final_valid),
    .m_axis_result_tready(t_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) ocd(
    .s_axis_a_tdata(oc_result),
    .s_axis_a_tready(ocd_oc_ready),
    .s_axis_a_tvalid(oc_valid),
    .s_axis_b_tdata(pipe_d_result),
    .s_axis_b_tready(ocd_d_ready),
    .s_axis_b_tvalid(pipe_d_valid),
    .m_axis_result_tdata(ocd_result),
    .m_axis_result_tready(pipe_b_ready),
    .m_axis_result_tvalid(ocd_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) occa(
    .s_axis_a_tdata(oc_result),
    .s_axis_a_tready(occa_oc_ready),
    .s_axis_a_tvalid(oc_valid),
    .s_axis_b_tdata(pipe_ca_result),
    .s_axis_b_tready(occa_ca_ready),
    .s_axis_b_tvalid(pipe_ca_valid),
    .m_axis_result_tdata(occa_result),
    .m_axis_result_tready(b_occa_ready),
    .m_axis_result_tvalid(occa_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_fused_mul_add a(
    .s_axis_a_tdata({~dca_result[SIZE-1], dca_result[SIZE-2:0]}),
    .s_axis_a_tready(a_dca_ready),
    .s_axis_a_tvalid(dca_valid),
    .s_axis_b_tdata(dca_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(dca_valid),
    .s_axis_c_tdata(dd_result),
    .s_axis_c_tready(a_dd_ready),
    .s_axis_c_tvalid(dd_valid),
    .m_axis_result_tdata(a_result),
    .m_axis_result_tready(pipe_a_ready),
    .m_axis_result_tvalid(a_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) ococ(
    .s_axis_a_tdata(oc_result),
    .s_axis_a_tready(ococ_ready),
    .s_axis_a_tvalid(oc_valid),
    .s_axis_b_tdata(oc_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(oc_valid),
    .m_axis_result_tdata(ococ_result),
    .m_axis_result_tready(pipe_ococ_ready),
    .m_axis_result_tvalid(ococ_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_fused_mul_add b(
    .s_axis_a_tdata(pipe_dca_result),
    .s_axis_a_tready(b_dca_ready),
    .s_axis_a_tvalid(pipe_dca_valid),
    .s_axis_b_tdata({~occa_result[SIZE-1], occa_result[SIZE-2:0]}),
    .s_axis_b_tready(b_occa_ready),
    .s_axis_b_tvalid(occa_valid),
    .s_axis_c_tdata(ocd_result),
    .s_axis_c_tready(b_ocd_ready),
    .s_axis_c_tvalid(ocd_valid),
    .m_axis_result_tdata(b_result),
    .m_axis_result_tready(pipe_b_ready),
    .m_axis_result_tvalid(b_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_fused_mul_add prec(
    .s_axis_a_tdata(occa_result),
    .s_axis_a_tready(prec_occa_ready),
    .s_axis_a_tvalid(occa_valid),
    .s_axis_b_tdata({~occa_result[SIZE-1], occa_result[SIZE-2:0]}),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(occa_valid),
    .s_axis_c_tdata(pipe_flag_prec_result ? NEG_CYLINDER_RAD_SQ : NEG_SPHERE_RAD_SQ),
    .s_axis_c_tready(prec_radius_ready),
    .s_axis_c_tvalid(pipe_flag_prec_valid),
    .m_axis_result_tdata(prec_result),
    .m_axis_result_tready(c_prec_ready),
    .m_axis_result_tvalid(prec_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_OCOC_LATENCY)) pipe_ococ(
    .s_axis_a_tdata(ococ_result),
    .s_axis_a_tready(pipe_ococ_ready),
    .s_axis_a_tvalid(ococ_valid),
    .m_axis_result_tdata(pipe_ococ_result),
    .m_axis_result_tvalid(pipe_ococ_valid),
    .m_axis_result_tready(c_ococ_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_add c(
    .s_axis_a_tdata(prec_result),
    .s_axis_a_tready(c_prec_ready),
    .s_axis_a_tvalid(prec_valid),
    .s_axis_b_tdata(pipe_ococ_result),
    .s_axis_b_tready(c_ococ_ready),
    .s_axis_b_tvalid(pipe_ococ_valid),
    .m_axis_result_tdata(c_result),
    .m_axis_result_tready(quad_c_ready),
    .m_axis_result_tvalid(c_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_A_LATENCY)) pipe_a(
    .s_axis_a_tdata(a_result),
    .s_axis_a_tready(pipe_a_ready),
    .s_axis_a_tvalid(a_valid),
    .m_axis_result_tdata(pipe_a_result),
    .m_axis_result_tvalid(pipe_a_valid),
    .m_axis_result_tready(quad_a_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_B_LATENCY)) pipe_b(
    .s_axis_a_tdata(b_result),
    .s_axis_a_tready(pipe_b_ready),
    .s_axis_a_tvalid(b_valid),
    .m_axis_result_tdata(pipe_b_result),
    .m_axis_result_tvalid(pipe_b_valid),
    .m_axis_result_tready(quad_b_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [SIZE-1:0] quad_result;

  logic [SIZE-1:0] scale_pipe_a_result;
  float_mul_pow2 #(.SIZE(SIZE), .POW(-2)) scale_pipe_a(
    .in_float(pipe_a_result),
    .result(scale_pipe_a_result)
  );

  logic [SIZE-1:0] scale_pipe_b_result;
  float_mul_pow2 #(.SIZE(SIZE), .POW(1)) scale_pipe_b(
    .in_float(pipe_b_result),
    .result(scale_pipe_b_result)
  );

  logic [SIZE-1:0] final_pipe_a_result;
  logic [SIZE-1:0] final_pipe_b_result;
  assign final_pipe_a_result = pipe_flag_quad_result ? scale_pipe_a_result : pipe_a_result;
  assign final_pipe_b_result = pipe_flag_quad_result ? pipe_b_result : scale_pipe_b_result;

  quadratic #(.SIZE(SIZE)) quad(
    .s_axis_a_tdata(final_pipe_a_result),
    .s_axis_a_tready(quad_a_ready),
    .s_axis_a_tvalid(pipe_a_valid),
    .s_axis_b_tdata(final_pipe_b_result),
    .s_axis_b_tready(quad_b_ready),
    .s_axis_b_tvalid(pipe_b_valid),
    .s_axis_c_tdata(c_result),
    .s_axis_c_tready(quad_c_ready),
    .s_axis_c_tvalid(c_valid),
    .m_axis_result_tdata(quad_result),
    .m_axis_result_undef(undef_axis_tdata),
    .m_axis_result_tready(t_axis_tready),
    .m_axis_result_tvalid(t_axis_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [SIZE-1:0] scale_quad_result;
  float_mul_pow2 #(.SIZE(SIZE), .POW(-1)) scale_quad(
    .in_float(quad_result),
    .result(scale_quad_result)
  );

  logic [SIZE-1:0] final_quad_result;
  assign t_axis_tdata = pipe_flag_final_result ? scale_quad_result : quad_result;

endmodule
`default_nettype wire