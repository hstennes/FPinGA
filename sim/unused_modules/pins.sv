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
    output logic [9:0] [15:0] pins_vx_out,     
    output logic [9:0] [15:0] pins_vy_out
);

    // Physics constants
    // parameter GRAVITY = 981;       // Gravity in mm/s^2 (scaled by 1000)
    parameter FRICTION = 10;        // Frictional deceleration in mm/s^2
    // parameter LANE_LENGTH = 1800; // Length of the lane in mm
    parameter TIME_STEP = 1;     // Time step in ms (scaled by 100)
    // parameter BALL_MASS = 7200;    // Ball mass in grams
    // parameter PIN_START = 1000;
    parameter PINS_X_INITIAL = 0;
    parameter PINS_Y_INITIAL = 0;


    // Pin dynamics
    // logic [15:0] simtime;              // Simulation time in ms
    logic [9:0] [15:0] pins_vx;
    logic [9:0] [15:0] pins_vy;

    always @(posedge clk_in) begin
        if (rst_in) begin
            pins_x <= PINS_X_INITIAL;
            pins_y <= PINS_Y_INITIAL;
            pins_vx_out <= 0;
            pins_vy_out <= 0;
            // simtime <= 0;
            
        end else if (valid_in) begin
            // simtime <= simtime + TIME_STEP;
            for (int i=0; i<10; i=i+1) begin
                if (pins_hit_in[i]) begin
                    pins_vx_out[i] <= pins_vx_in - FRICTION * TIME_STEP;
                    pins_vy_out[i] <= pins_vy_in - FRICTION * TIME_STEP;
                    pins_x[i] <= pins_x[i] + (pins_vx_in[i] * TIME_STEP) / 1000;
                    pins_y[i] <= pins_y[i] + (pins_vy_in[i] * TIME_STEP) / 1000;
                end
            end
        end
    end

endmodule
