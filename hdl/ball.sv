`timescale 1ns / 1ps
`default_nettype none

module ball (
    input wire clk_in,                    
    input wire rst_in,
    input wire valid_in,
    input wire [15:0] initial_speed_x,
    input wire [15:0] initial_speed_y,
    input wire is_vy_neg,
    output logic [10:0] ball_x,     
    output logic [9:0] ball_y,  
    output logic [15:0] speed_x,
    output logic [15:0] speed_y,
    output logic ball_vy_neg,
    output logic check_collision,
    output logic done
);

    // Physics constants
    // parameter GRAVITY = 981;       // Gravity in mm/s^2 (scaled by 1000)
    parameter FRICTION = 0;        // Frictional deceleration in mm/s^2
    // parameter LANE_LENGTH = 1024; // Length of the lane in mm
    parameter TIME_STEP = 1;     // Time step in ms (scaled by 100)
    parameter PIN_START = 0;
    parameter SCREEN_WIDTH = 1024;
    parameter SCREEN_HEIGHT = 768;
    parameter TIMER_RST = 3000000;

    // Ball dynamics
    logic [15:0] simtime;              // Simulation time in ms
    logic rolling;
    logic [31:0] timer;

    always @(posedge clk_in) begin
        if (rst_in) begin
            ball_x <= 144;
            ball_y <= 800;
            speed_x <= 0;
            speed_y <= 0;
            rolling <= 0;
            check_collision <= 0;
            simtime <= 0;
            done <= 0;
            timer <= 0;

        end else if(timer == 0) begin
            timer = timer + 1;
            if (valid_in && !rolling) begin
                speed_y <= initial_speed_y;
                speed_x <= initial_speed_x;
                rolling <= 1;
                done <= 0;

            end else if (rolling) begin
                if (ball_x >= SCREEN_WIDTH || ball_y >= SCREEN_HEIGHT) begin
                    speed_x <= 0;
                    rolling <= 0;
                    speed_y <= 0;
                    check_collision <= 0;
                    done <= 1;

                end else if (speed_x > FRICTION) begin
                    speed_x <= speed_x - FRICTION;
                // end else begin
                //     speed_x <= 1;
                end
                // Update ball position in x and y directions
                if (ball_x < SCREEN_WIDTH) begin
                    ball_x <= ball_x + speed_x;
                end else begin 
                    done <= 1;
                end
                if (is_vy_neg) begin
                    ball_y <= ball_y - speed_y;
                    ball_vy_neg <= 1;
                end else begin
                    ball_y <= ball_y + speed_y;
                    ball_vy_neg <= 0;
                end
            
                if (ball_x > PIN_START) begin
                    check_collision <= 1;    
                end else begin
                    check_collision <= 0;
                end
            end
        end else if (timer == TIMER_RST) begin
            timer <= 0;
        end else begin 
            timer <= timer +1;
        end


            // if (timer == 0) begin
            //     speed_x <= initial_speed_x;
            //     speed_y <= initial_speed_y;
            //     ball_x <= ball_x + 1;
            //     ball_y <= ball_y + 1;
            //     timer <= timer + 1;
            // end else if (timer == 2147483) begin
            //     timer <= 0;
            // end else begin 
            //     timer <= timer +1;
            // end

    end

            
    //     end else if (valid_in && !rolling) begin
    //         simtime <= simtime + TIME_STEP;
    //         speed_y <= initial_speed_y;
    //         speed_x <= initial_speed_x;
    //         rolling <= 1;
    //         done <= 0;

    //     end else if (rolling) begin
    //         if (ball_y >= LANE_LENGTH) begin
    //             speed_x <= 0;
    //             rolling <= 0;
    //             speed_y <= 0;
    //             simtime <= 0;
    //             check_collision <= 0;
            
    //         end else begin
    //             // Update simulation time
    //             simtime <= simtime + TIME_STEP;

    //             // Friction effect on ball speed
    //             if (speed_y > FRICTION * TIME_STEP) begin
    //                 speed_y <= speed_y - FRICTION * TIME_STEP;
    //             end else begin
    //                 speed_y <= 1;
    //             end

    //             // Update lateral speed due to spin
    //             speed_x <= speed_x;

    //             // Update ball position in x and y directions
    //             ball_x <= ball_x + (speed_x * TIME_STEP);
    //             ball_y <= ball_y + (speed_y * TIME_STEP);

    //             // End simulation if the ball exits the lane
            
    //             if (ball_y > LANE_LENGTH - PIN_START) begin
    //                 check_collision <= 1;
    //                 if(ball_y > LANE_LENGTH) begin
    //                     done <= 1;
    //                 end
    //             end else begin
    //                 check_collision <= 0;
    //             end
    //         end
    //     end
    // end
endmodule
