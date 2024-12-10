`timescale 1ns / 1ps
`default_nettype none

module pin_rotate #(parameter SIZE) (
  output logic [2:0][SIZE-1:0] pin_axis,
  output logic pin_axis_valid,
  input wire pin_axis_ready,
  input wire aclk,
  input wire aresetn);

  parameter TIMER_RST = 1000000;

  logic [31:0] timer;

  logic [31:0] pin_rot;

  logic [SIZE-1:0] float_pin_rot;
  logic float_pin_rot_valid;

  logic [SIZE-1:0] scale_float_pin_rot;

  logic norm_ready;

  always_ff @(posedge aclk) begin
    if(~aresetn) begin
        timer <= 32'b0;
        pin_rot <= 32'b0;
    end
    else begin
        if(timer == TIMER_RST) begin
            timer <= 32'b0;
            pin_rot <= pin_rot + 1;
        end else begin
            timer <= timer + 1;
        end
    end
  end

  fixed_to_float convert_rot(
    .s_axis_a_tdata(pin_rot),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(float_pin_rot),
    .m_axis_result_tready(norm_ready),
    .m_axis_result_tvalid(float_pin_rot_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_mul_pow2 #(.SIZE(SIZE), .POW(-9)) scale_pin_rot(
    .in_float(float_pin_rot),
    .result(scale_float_pin_rot)
  );

  vec_unit #(.SIZE(SIZE)) norm (
    .s_axis_a_tdata({scale_float_pin_rot, 32'h3f800000, 32'h00000000}),
    .s_axis_a_tready(norm_ready),
    .s_axis_a_tvalid(float_pin_rot_valid),
    .m_axis_result_tdata(pin_axis),
    .m_axis_result_tvalid(pin_axis_valid),
    .m_axis_result_tready(pin_axis_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire