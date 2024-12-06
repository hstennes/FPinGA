`timescale 1ns / 1ps
`default_nettype none

module camera (
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire light_in,
    input wire [10:0] x_in,
    input wire [9:0] y_in,
    output logic [15:0] vx_out,
    output logic [15:0] vy_out,
    output logic valid_out
    );

    logic calc;
    logic [1:0][10:0] x;
    logic [1:0][9:0] y;
    logic [15:0] counter;
    logic div_valid_in;
    logic divx_valid_out;
    logic divy_valid_out;
    logic [31:0] divx_out;
    logic [31:0] divy_out;

    divider div_x(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in({21'b0, x[1]-x[0]}),
        .divisor_in({16'b0, counter}),
        .data_valid_in(div_valid_in),
        .quotient_out(divx_out),
        .data_valid_out(divx_valid_out)
    );

    divider div_y(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in({22'b0, y[1]-y[0]}),
        .divisor_in({16'b0, counter}),
        .data_valid_in(div_valid_in),
        .quotient_out(divy_out),
        .data_valid_out(divy_valid_out)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            counter <= 0;
            calc <= 1;
            counter <= 0;
            div_valid_in <= 0;
            // divx_valid_out <= 0;
            // divy_valid_out <= 0;
            valid_out <= 0;

        end else if (valid_in && calc) begin
            valid_out <= 0;
            if (light_in) begin
                if (counter == 0) begin
                    x[0] <= x_in;
                    y[0] <= y_in;
                    counter <= 1;
                end else begin
                    x[1] <= x_in;
                    y[1] <= y_in;
                    counter <= counter+1;
                end
                
            end else if (counter > 0) begin;
                counter <= 0;
                div_valid_in <= 1;
                calc <= 0; 
            end
        end 

        if (divx_valid_out) begin
            calc <= 1;
            vx_out <= divx_out[15:0];
            vy_out <= divy_out[15:0];
            div_valid_in <= 0;
            valid_out <= 1;
        end else begin
            // valid_out <= 0;
            div_valid_in <= 0;
        end
    end

endmodule