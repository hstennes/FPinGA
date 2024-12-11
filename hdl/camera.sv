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
    output logic is_vy_neg,
    output logic valid_out
);

    parameter TIMER_RST = 3000000;

    // Internal signals
    logic [10:0] x_start, x_end;
    logic [9:0] y_start, y_end;
    logic [15:0] time_counter;
    logic calc, div_valid_in;
    logic divx_valid_out, divy_valid_out;
    logic [31:0] divx_out, divy_out;
    logic x_done, y_done;  // Flags to track when each division finishes
    logic [31:0] timer;
    logic [9:0] dividend_y;

    // Divider for X-axis
    divider div_x(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in({21'b0, x_end - x_start}),
        .divisor_in({16'b0, time_counter-1}),
        .data_valid_in(div_valid_in),
        .quotient_out(divx_out),
        .data_valid_out(divx_valid_out)
    );

    // Divider for Y-axis
    divider div_y(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in({22'b0, dividend_y}),
        .divisor_in({16'b0, time_counter-1}),
        .data_valid_in(div_valid_in),
        .quotient_out(divy_out),
        .data_valid_out(divy_valid_out)
    );

    // Main logic
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset all states
            x_start <= 0;
            x_end <= 0;
            y_start <= 0;
            y_end <= 0;
            time_counter <= 0;
            calc <= 1;
            div_valid_in <= 0;
            valid_out <= 0;
            vx_out <= 0;
            vy_out <= 0;
            x_done <= 0;
            y_done <= 0;

        end else if (valid_in) begin
            if (light_in) begin
                // Capture first and last positions
                if (time_counter == 0) begin
                    x_start <= x_in;
                    y_start <= y_in;
                end
                x_end <= x_in;
                y_end <= y_in;
                time_counter <= time_counter + 1;
            end else if (time_counter > 0 && calc) begin
                // Light turned off: Trigger calculations
                div_valid_in <= 1;
                if (y_start < y_end) begin
                    dividend_y <= y_end - y_start;
                    is_vy_neg <= 0;
                end else begin
                    dividend_y <= y_start - y_end;
                    is_vy_neg <= 1;
                end
                calc <= 0;
                x_done <= 0;  // Reset done flags
                y_done <= 0;
            end
        end

        // Wait for dividers to finish their calculations
        if (divx_valid_out && !x_done) begin
            vx_out <= divx_out[15:0];
            x_done <= 1;  // Mark X calculation as done
        end
        if (divy_valid_out && !y_done) begin
            vy_out <= divy_out[15:0];
            y_done <= 1;  // Mark Y calculation as done
        end

        // Assert valid_out only when both divisions are complete
        if (x_done && y_done) begin
            valid_out <= 1;
            div_valid_in <= 0;  // Stop sending valid signal to dividers
            // calc <= 1;  // Ready for next calculation
            time_counter <= 0;  // Reset time counter for the next sequence
        end

    end

endmodule



// `timescale 1ns / 1ps
// `default_nettype none

// module camera (
//     input wire clk_in,
//     input wire rst_in,
//     input wire valid_in,
//     input wire light_in,
//     input wire [10:0] x_in,
//     input wire [9:0] y_in,
//     output logic [15:0] vx_out,
//     output logic [15:0] vy_out,
//     output logic valid_out
//     );

//     logic calc;
//     logic [1:0][10:0] x;
//     logic [1:0][9:0] y;
//     logic [15:0] counter;
//     logic div_valid_in;
//     logic divx_valid_out;
//     logic divy_valid_out;
//     logic [31:0] divx_out;
//     logic [31:0] divy_out;

//     divider div_x(
//         .clk_in(clk_in),
//         .rst_in(rst_in),
//         .dividend_in({21'b0, x[1]-x[0]}),
//         .divisor_in({16'b0, counter}),
//         .data_valid_in(div_valid_in),
//         .quotient_out(divx_out),
//         .data_valid_out(divx_valid_out)
//     );

//     divider div_y(
//         .clk_in(clk_in),
//         .rst_in(rst_in),
//         .dividend_in({22'b0, y[1]-y[0]}),
//         .divisor_in({16'b0, counter}),
//         .data_valid_in(div_valid_in),
//         .quotient_out(divy_out),
//         .data_valid_out(divy_valid_out)
//     );

//     always_ff @(posedge clk_in) begin
//         if (rst_in) begin
//             counter <= 0;
//             calc <= 1;
//             counter <= 0;
//             div_valid_in <= 0;
//             // divx_valid_out <= 0;
//             // divy_valid_out <= 0;
//             valid_out <= 0;

//         end else if (valid_in && calc) begin
//             valid_out <= 0;
//             if (light_in) begin
//                 if (counter == 0) begin
//                     x[0] <= x_in;
//                     y[0] <= y_in;
//                     counter <= 1;
//                 end else begin
//                     x[1] <= x_in;
//                     y[1] <= y_in;
//                     counter <= counter+1;
//                 end
                
//             end else if (counter > 0) begin;
//                 counter <= 0;
//                 div_valid_in <= 1;
//                 calc <= 0; 
//             end
//         end 

//         if (divx_valid_out) begin
//             calc <= 1;
//             vx_out <= divx_out[15:0];
//             vy_out <= divy_out[15:0];
//             div_valid_in <= 0;
//             valid_out <= 1;
//         end else begin
//             // valid_out <= 0;
//             div_valid_in <= 0;
//         end
//     end

// endmodule