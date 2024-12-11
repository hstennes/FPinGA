`timescale 1ns / 1ps
`default_nettype none

module camera_input (
    input wire rst_sim,
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] hcount,
    input wire [9:0] vcount,
    output logic new_com,
    output logic light_on,
    output logic [10:0] x_com, // Center of mass X-coordinate
    output logic [9:0] y_com  // Center of mass Y-coordinate
);
    logic [31:0] counter; // For timing the generation of new data

    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in || rst_sim) begin
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
                x_com <= hcount[3]; // Small random movements
                y_com <= vcount[3];
                counter <= counter + 1;
            end else if (counter == 32'd1000010) begin
                // Update position every few cycles
                new_com <= 1;
                light_on <= 1;
                if (vcount[0] < y_com) begin
                    y_com <= vcount[0];
                end else begin
                    y_com <= y_com + 10;
                end
                x_com <= hcount[0]; // Small random movements
                // y_com <= vcount[0];
                counter <= 0;
            end else begin
                new_com <= 1;
                light_on <= 0;
            end
        end
    end
endmodule
// `timescale 1ns / 1ps
// `default_nettype none

// module camera_input (
//     input wire clk_in,
//     input wire rst_in,
//     output logic new_com,
//     output logic light_on,
//     output logic [10:0] x_com, // Center of mass X-coordinate
//     output logic [9:0] y_com  // Center of mass Y-coordinate
// );
//     logic [31:0] counter; // For timing the generation of new data

//     always_ff @(posedge clk_in or posedge rst_in) begin
//         if (rst_in) begin
//             counter <= 0;
//             new_com <= 0;
//             light_on <= 0;
//             x_com <= 11'd200; // Start at screen center
//             y_com <= 10'd240; // Start at screen center
//         end else begin
//             counter <= counter + 1;

//             if (counter == 32'd1000000) begin
//                 // Update position every few cycles
//                 new_com <= 1;
//                 light_on <= 1;
//                 x_com <= x_com; // Small random movements
//                 y_com <= y_com;
//                 counter <= counter + 1;
//             end else if (counter == 32'd1000001) begin
//                 // Update position every few cycles
//                 new_com <= 1;
//                 light_on <= 1;
//                 x_com <= x_com+10; // Small random movements
//                 y_com <= y_com+1;
//                 counter <= 0;
//             end else begin
//                 new_com <= 1;
//                 light_on <= 0;
//             end
//         end
//     end
// endmodule
