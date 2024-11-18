`timescale 1ns / 1ps
`default_nettype none

module ray_sphere_intersection #(parameter SIZE=64) (
  input wire [SIZE-1:0] sphere_loc [2:0],
  input wire sphere_loc_valid,
  output logic ray_axis_tready,
  input wire ray_axis_tvalid,
  input wire [SIZE-1:0] ray_axis_tdata [2:0],
  input wire t_axis_tready,
  output logic t_axis_tvalid,
  output logic [SIZE-1:0] t_axis_tdata,
  input wire clk_render,
  input wire rst);

  

endmodule
`default_nettype wire