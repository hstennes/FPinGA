`timescale 1ns / 1ps
`default_nettype none

module camera_input (
    input wire clk_in,
    input wire rst_in,
    output logic new_com,
    output logic light_on,
    output logic [10:0] x_com, // Center of mass X-coordinate
    output logic [9:0] y_com  // Center of mass Y-coordinate
);
    logic [31:0] counter; // For timing the generation of new data

    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            counter <= 0;
            new_com <= 0;
            light_on <= 0;
            x_com <= 11'd200; // Start at screen center
            y_com <= 10'd240; // Start at screen center
        end else begin
            counter <= counter + 1;

            if (counter == 32'd1000000) begin
                // Update position every few cycles
                new_com <= 1;
                light_on <= 1;
                x_com <= x_com; // Small random movements
                y_com <= y_com;
                counter <= counter + 1;
            end else if (counter == 32'd1000001) begin
                // Update position every few cycles
                new_com <= 1;
                light_on <= 1;
                x_com <= x_com; // Small random movements
                y_com <= y_com-8;
                counter <= 0;
            end else begin
                new_com <= 1;
                light_on <= 0;
            end
        end
    end
endmodule
