`timescale 1ns / 1ps
`default_nettype none

module convolution (
    input wire clk_in,
    input wire rst_in,
    input wire [KERNEL_SIZE-1:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,
    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    parameter K_SELECT = 4;
    localparam KERNEL_SIZE = 3;

    logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][15:0] column_in_buffer;

    logic data_valid_buffer;
    logic [10:0] hcount_buffer;
    logic [10:0] vcount_buffer;

    logic signed [15:0] comb_r_buffer_1;
    logic signed [15:0] comb_g_buffer_1;
    logic signed [15:0] comb_b_buffer_1;

    logic signed [15:0] r_buffer_1;
    logic signed [15:0] g_buffer_1;
    logic signed [15:0] b_buffer_1;

    logic signed [15:0] comb_r_buffer_2;
    logic signed [15:0] comb_g_buffer_2;
    logic signed [15:0] comb_b_buffer_2;

    logic signed [15:0] r_buffer_2;
    logic signed [15:0] g_buffer_2;
    logic signed [15:0] b_buffer_2;

    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [7:0] shift;

    // Your code here!

    /* Note that the coeffs output of the kernels module
     * is packed in all dimensions, so coeffs should be
     * defined as `logic signed [2:0][2:0][7:0] coeffs`
     *
     * This is because iVerilog seems to be weird about passing
     * signals between modules that are unpacked in more
     * than one dimension - even though this is perfectly
     * fine Verilog.
     */

    kernels #(
        .K_SELECT(K_SELECT)
    ) kernel (
        .rst_in(rst_in),
        .coeffs(coeffs),
        .shift(shift)
    );

    always_comb begin
        comb_r_buffer_1 = $signed({1'b0, column_in_buffer[0][0][15:11]}) * $signed(coeffs[0][0]) + $signed({1'b0, column_in_buffer[1][0][15:11]}) * $signed(coeffs[0][1]) +
                      $signed({1'b0, column_in_buffer[2][0][15:11]}) * $signed(coeffs[0][2]) + $signed({1'b0, column_in_buffer[0][1][15:11]}) * $signed(coeffs[1][0]) +
                      $signed({1'b0, column_in_buffer[1][1][15:11]}) * $signed(coeffs[1][1]);

        comb_g_buffer_1 = $signed({1'b0, column_in_buffer[0][0][10:5]}) * $signed(coeffs[0][0]) + $signed({1'b0, column_in_buffer[1][0][10:5]}) * $signed(coeffs[0][1]) +
                      $signed({1'b0, column_in_buffer[2][0][10:5]}) * $signed(coeffs[0][2]) + $signed({1'b0, column_in_buffer[0][1][10:5]}) * $signed(coeffs[1][0]) +
                      $signed({1'b0, column_in_buffer[1][1][10:5]}) * $signed(coeffs[1][1]);

        comb_b_buffer_1 = $signed({1'b0, column_in_buffer[0][0][4:0]}) * $signed(coeffs[0][0]) + $signed({1'b0, column_in_buffer[1][0][4:0]}) * $signed(coeffs[0][1]) +
                      $signed({1'b0, column_in_buffer[2][0][4:0]}) * $signed(coeffs[0][2]) + $signed({1'b0, column_in_buffer[0][1][4:0]}) * $signed(coeffs[1][0]) +
                      $signed({1'b0, column_in_buffer[1][1][4:0]}) * $signed(coeffs[1][1]);

        comb_r_buffer_2 = ($signed({1'b0, column_in_buffer[2][1][15:11]}) * $signed(coeffs[1][2]) + $signed({1'b0, column_in_buffer[0][2][15:11]}) * $signed(coeffs[2][0]) +
                      $signed({1'b0, column_in_buffer[1][2][15:11]}) * $signed(coeffs[2][1]) + $signed({1'b0, column_in_buffer[2][2][15:11]}) * $signed(coeffs[2][2]) +
                      r_buffer_1) >>> shift;

        comb_r_buffer_2 = comb_r_buffer_2[15] == 1 ? 0 : (comb_r_buffer_2 > 31 ? 31 : comb_r_buffer_2);
        
        comb_g_buffer_2 = ($signed({1'b0, column_in_buffer[2][1][10:5]}) * $signed(coeffs[1][2]) + $signed({1'b0, column_in_buffer[0][2][10:5]}) * $signed(coeffs[2][0]) +
                      $signed({1'b0, column_in_buffer[1][2][10:5]}) * $signed(coeffs[2][1]) + $signed({1'b0, column_in_buffer[2][2][10:5]}) * $signed(coeffs[2][2]) +
                      g_buffer_1) >>> shift;

        comb_g_buffer_2 = comb_g_buffer_2[15] == 1 ? 0 : (comb_g_buffer_2 > 63 ? 63 : comb_g_buffer_2);
        
        comb_b_buffer_2 = ($signed({1'b0, column_in_buffer[2][1][4:0]}) * $signed(coeffs[1][2]) + $signed({1'b0, column_in_buffer[0][2][4:0]}) * $signed(coeffs[2][0]) +
                      $signed({1'b0, column_in_buffer[1][2][4:0]}) * $signed(coeffs[2][1]) + $signed({1'b0, column_in_buffer[2][2][4:0]}) * $signed(coeffs[2][2]) +
                      b_buffer_1) >>> shift;

        comb_b_buffer_2 = comb_b_buffer_2[15] == 1 ? 0 : (comb_b_buffer_2 > 31 ? 31 : comb_b_buffer_2);
    end

    always_ff @(posedge clk_in) begin
      if(data_valid_in) begin
        column_in_buffer[2] <= data_in;
        column_in_buffer[1] <= column_in_buffer[2];
        column_in_buffer[0] <= column_in_buffer[1];

        r_buffer_1 <= comb_r_buffer_1;
        g_buffer_1 <= comb_g_buffer_1;
        b_buffer_1 <= comb_b_buffer_1;

        r_buffer_2 <= comb_r_buffer_2;
        g_buffer_2 <= comb_g_buffer_2;
        b_buffer_2 <= comb_b_buffer_2;
      end

      data_valid_buffer <= data_valid_in;
      data_valid_out <= data_valid_buffer;

      hcount_buffer <= hcount_in;
      hcount_out <= hcount_in;

      vcount_buffer <= vcount_in;
      vcount_out <= vcount_buffer;
    end

    assign line_out = {r_buffer_2[4:0], g_buffer_2[5:0], b_buffer_2[4:0]};

endmodule

`default_nettype wire

