`timescale 1ns / 1ps
`default_nettype none

module ball (
    input wire clk_in,                    
    input wire rst_in,
    input wire valid_in,
    input wire [15:0] initial_speed_x,
    input wire [15:0] initial_speed_y,
    input wire [15:0] initial_spin,
    output logic [15:0] ball_x,     
    output logic [15:0] ball_y,  
    output logic [15:0] speed_x,
    output logic [15:0] speed_y,
    output logic check_collision
);

    // Physics constants
    // parameter GRAVITY = 981;       // Gravity in mm/s^2 (scaled by 1000)
    parameter FRICTION = 5;        // Frictional deceleration in mm/s^2
    parameter LANE_LENGTH = 1800; // Length of the lane in mm
    parameter TIME_STEP = 1;     // Time step in ms (scaled by 100)
    parameter BALL_MASS = 7200;    // Ball mass in grams
    parameter PIN_START = 1000;

    // Ball dynamics
    logic [15:0] spin;              // Spin of the ball (scaled by 1000)
    logic [15:0] simtime;              // Simulation time in ms
    logic rolling;

    always @(posedge clk_in) begin
        if (rst_in) begin
            ball_x <= 0;
            ball_y <= 0;
            speed_x <= 0;
            speed_y <= 0;
            spin <= 0;
            rolling <= 0;
            check_collision <= 0;
            simtime <= 0;

            
        end else if (valid_in && !rolling) begin
            simtime <= simtime + TIME_STEP;
            speed_y <= initial_speed_y;
            speed_x <= initial_speed_x;
            spin <= initial_spin;
            rolling <= 1;

        end else if (rolling) begin
            if (ball_y >= LANE_LENGTH) begin
                speed_x <= 0;
                spin <= 0;
                rolling <= 0;
                speed_y <= 0;
                simtime <= 0;
                check_collision <= 0;
            
            end else begin
                // Update simulation time
                simtime <= simtime + TIME_STEP;

                // Friction effect on ball speed
                if (speed_y > FRICTION * TIME_STEP) begin
                    speed_y <= speed_y - FRICTION * TIME_STEP;
                end else begin
                    speed_y <= 1;
                end

                // Update lateral speed due to spin
                speed_x <= speed_x + (spin * TIME_STEP) / 1000;
                spin <= spin - (FRICTION * TIME_STEP / 10); // Decrease spin gradually

                // Update ball position in x and y directions
                ball_x <= ball_x + (speed_x * TIME_STEP) / 1000;
                ball_y <= ball_y + (speed_y * TIME_STEP);

                // End simulation if the ball exits the lane
            
                if (ball_y > LANE_LENGTH - PIN_START) begin
                    check_collision <= 1;
                end else begin
                    check_collision <= 0;
                end
            end
        end
    end
endmodule
