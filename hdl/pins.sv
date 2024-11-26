`timescale 1ns / 1ps
`default_nettype none

module pins (
    input wire clk_in,                    
    input wire rst_in,
    input wire valid_in,
    input logic [9:0] [15:0] pins_vx_in, 
    input logic [9:0] [15:0] pins_vy_in, 
    input logic [9:0] pins_hit_in,
    output logic [9:0] [15:0] pins_x,     
    output logic [9:0] [15:0] pins_y,  
    output logic [15:0] speed_x,
    output logic [15:0] speed_y,
);

    // Physics constants
    // parameter GRAVITY = 981;       // Gravity in mm/s^2 (scaled by 1000)
    parameter FRICTION = 10;        // Frictional deceleration in mm/s^2
    // parameter LANE_LENGTH = 1800; // Length of the lane in mm
    parameter TIME_STEP = 1;     // Time step in ms (scaled by 100)
    // parameter BALL_MASS = 7200;    // Ball mass in grams
    // parameter PIN_START = 1000;
    parameter PINS_X_INITIAL = [];
    parameter PINS_Y_INITIAL = [];


    // Pin dynamics
    logic [15:0] simtime;              // Simulation time in ms
    logic [9:0] [15:0] pins_vx;
    logic [9:0] [15:0] pins_vy;

    always @(posedge clk_in) begin
        if (rst_in) begin
            pins_x <= PINS_X_INITIAL;
            pins_y <= PINS_Y_INITIAL;
            pins_vx <= 0;
            pins_vy <= 0;
            simtime <= 0;

            
        end else if (valid_in) begin
            simtime <= simtime + TIME_STEP;
            pins_vx <= pins_vx_in;
            pins_vy <= pins_vy_in;
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
