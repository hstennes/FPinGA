`timescale 1ns / 1ps
`default_nettype none

module CollisionFSM (
    input wire clk_in,                     
    input wire rst_in,
    input wire valid_in, 
    input wire [15:0] ball_x,          
    input wire [15:0] ball_y,     
    input wire [9:0] [15:0] pins_x,       
    input wire [9:0] [15:0] pins_y,        
    input wire [15:0] ball_vx_in,       
    input wire [15:0] ball_vy_in, 
    input wire [9:0] pins_hit_in,
    output logic [9:0] [15:0] pins_vx_out, 
    output logic [9:0] [15:0] pins_vy_out, 
    output logic [9:0] pins_hit_out,
    output logic done               
);

    parameter BALL_MASS = 7200,
    parameter PIN_MASS = 1000,   
    parameter BALL_RADIUS = 100,  
    parameter PIN_RADIUS = 25, 

    // Intermediate variables
    logic [9:0] [15:0] dist_ball_pin;
    logic [8:0] [15:0] dist_pin0_pin; 
    logic [7:0] [15:0] dist_pin1_pin; 
    logic [6:0] [15:0] dist_pin2_pin; 
    logic [5:0] [15:0] dist_pin3_pin; 
    logic [4:0] [15:0] dist_pin4_pin; 
    logic [3:0] [15:0] dist_pin5_pin; 
    logic [2:0] [15:0] dist_pin6_pin; 
    logic [1:0] [15:0] dist_pin7_pin; 
    logic [15:0] dist_pin8_pin;
    logic [9:0] [15:0] coll_ball_pin;
    logic [8:0] [15:0] coll_pin0_pin; 
    logic [7:0] [15:0] coll_pin1_pin; 
    logic [6:0] [15:0] coll_pin2_pin; 
    logic [5:0] [15:0] coll_pin3_pin; 
    logic [4:0] [15:0] coll_pin4_pin; 
    logic [3:0] [15:0] coll_pin5_pin; 
    logic [2:0] [15:0] coll_pin6_pin; 
    logic [1:0] [15:0] coll_pin7_pin; 
    logic [15:0] coll_pin8_pin; 
    logic [9:0] pins_hit;
   

    // Calculate squared distances between objects
    always_comb begin
        if (valid_in) begin
            for (int i=0; i<10; i=i+1) begin
                dist_ball_pin[i] = (ball_x - pins_x[i]) * (ball_x - pins_x[i]) + (ball_y - pins_y[i]) * (ball_y - pins_y[i]);
                coll_ball_pin[i] = !pins_hit_in[i] * (dist_ball_pin[i] <= (ball_radius + pin_radius) * (ball_radius + pin_radius));
                if (coll_ball_pin[i]) begin
                    pins_vx_out[i] = (ball_vx_in * (ball_mass - pin_mass) + 2 * pin_mass * pins_vx_in[i]) / (ball_mass + pin_mass);
                    pins_vy_out[i] = (ball_vy_in * (ball_mass - pin_mass) + 2 * pin_mass * pins_vx_in[i]) / (ball_mass + pin_mass);
                    pins_hit_out[i] = 1;
                end
            end
            for (int i=0; i<9; i=i+1) begin
                dist_pin9_pin[i] = (pins_x[9] - pins_x[i]) * (pins_x[9] - pins_x[i]) + (pins_y[9] - pins_y[i]) * (pins_y[9] - pins_y[i]);
                coll_pin9_pin[i] = pins_hit[i] * (dist_pin9_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin9_pin[i]) begin
                    pins_vx_out[i] = (ball_vx_in * (ball_mass - pin_mass) + 2 * pin_mass * pins_vx_in[i]) / (pin_mass + pin_mass);
                    pins_vy_out[i] = (ball_vy_in * (ball_mass - pin_mass) + 2 * pin_mass * pins_vx_in[i]) / (pin_mass + pin_mass);
                    pins_vx_out[9] = (ball_vx_in * (ball_mass - pin_mass) + 2 * pin_mass * pins_vx_in[i]) / (pin_mass + pin_mass);
                    pins_vy_out[9] = (ball_vy_in * (ball_mass - pin_mass) + 2 * pin_mass * pins_vx_in[i]) / (pin_mass + pin_mass);
                    pins_hit_out[i] = 1;
                end
            end

            if(!pins_hit[8]) begin
                for (int i=0; i<8; i=i+1) begin
                    dist_pin8_pin[i] = (pins_x[8] - pins_x[i]) * (pins_x[8] - pins_x[i]) + (pins_y[8] - pins_y[i]) * (pins_y[8] - pins_y[i]);
                    coll_pin8_pin[i] = pins_hit[i] * (dist_pin8_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                end
            end
            if(!pins_hit[7]) begin
                for (int i=0; i<7; i=i+1) begin
                    dist_pin7_pin[i] = (pins_x[7] - pins_x[i]) * (pins_x[7] - pins_x[i]) + (pins_y[7] - pins_y[i]) * (pins_y[7] - pins_y[i]);
                    coll_pin7_pin[i] = pins_hit[i] * (dist_pin7_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                end
            end
            if(pins_hit[6]) begin
                for (int i=0; i<6; i=i+1) begin
                    dist_pin6_pin[i] = (pins_x[6] - pins_x[i]) * (pins_x[6] - pins_x[i]) + (pins_y[6] - pins_y[i]) * (pins_y[6] - pins_y[i]);
                    coll_pin6_pin[i] = pins_hit[i] * (dist_pin6_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                end
            end
            if(pins_hit[5]) begin
                for (int i=0; i<5; i=i+1) begin
                    dist_pin5_pin[i] = (pins_x[5] - pins_x[i]) * (pins_x[5] - pins_x[i]) + (pins_y[5] - pins_y[i]) * (pins_y[5] - pins_y[i]);
                    coll_pin5_pin[i] = pins_hit[i] * (dist_pin5_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                end
            end
            if(pins_hit[4]) begin
                for (int i=0; i<4; i=i+1) begin
                    dist_pin4_pin[i] = (pins_x[4] - pins_x[i]) * (pins_x[4] - pins_x[i]) + (pins_y[4] - pins_y[i]) * (pins_y[4] - pins_y[i]);
                    coll_pin4_pin[i] = pins_hit[i] * (dist_pin4_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                end
            end
            if(pins_hit[3]) begin
                for (int i=0; i<3; i=i+1) begin
                    dist_pin3_pin[i] = (pins_x[3] - pins_x[i]) * (pins_x[3] - pins_x[i]) + (pins_y[3] - pins_y[i]) * (pins_y[3] - pins_y[i]);
                    coll_pin3_pin[i] = pins_hit[i] * (dist_pin3_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                end
            end
            if(pins_hit[2]) begin
                for (int i=0; i<2; i=i+1) begin
                    dist_pin2_pin[i] = (pins_x[2] - pins_x[i]) * (pins_x[2] - pins_x[i]) + (pins_y[2] - pins_y[i]) * (pins_y[2] - pins_y[i]);
                    coll_pin2_pin[i] = pins_hit[i] * (dist_pin2_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                end
            end
            if(pins_hit[1]) begin
                dist_pin1_pin = (pins_x[1] - pins_x[0]) * (pins_x[1] - pins_x[0]) + (pins_y[1] - pins_y[0]) * (pins_y[1] - pins_y[0]);
                coll_pin1_pin = pins_hit[i] * (dist_pin1_pin <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
            end
        end
    end

    // FSM State Transitions
    always @(posedge clk or posedge reset) begin
        if (rst_in)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // FSM Next-State Logic
    always @(posedge clk_in) begin
        case (current_state)
            IDLE:           next_state = start ? CHECK_COLLISION : IDLE;
            CHECK_COLLISION: next_state = CALC_COLLISION;
            CALC_COLLISION:  next_state = DONE;
            DONE:           next_state = IDLE;
            default:        next_state = IDLE;
        endcase
    end

    // FSM Output Logic
    always @(posedge clk_in) begin
        if (rst_in) begin
            // Reset outputs
            pins_vx_out <= 0; 
            pins_vy_out <= 0;
            done <= 0;
        end else begin
            

                CHECK_COLLISION: begin
                    // Check for collision conditions
                    if (collision_ball_pin1) begin
                        // Ball-to-Pin collision detected
                        temp_ball_vx <= (ball_vx_in * (ball_mass - pin_mass) + 2 * pin_mass * pin1_vx_in) / (ball_mass + pin_mass);
                        temp_pin1_vx <= (pin1_vx_in * (pin_mass - ball_mass) + 2 * ball_mass * ball_vx_in) / (ball_mass + pin_mass);
                        temp_ball_vy <= (ball_vy_in * (ball_mass - pin_mass) + 2 * pin_mass * pin1_vy_in) / (ball_mass + pin_mass);
                        temp_pin1_vy <= (pin1_vy_in * (pin_mass - ball_mass) + 2 * ball_mass * ball_vy_in) / (ball_mass + pin_mass);
                    end else if (collision_pin1_pin2) begin
                        // Pin-to-Pin collision detected
                        temp_pin2_vx <= (pin2_vx_in * (pin_mass - pin_mass) + 2 * pin_mass * pin1_vx_in) / (pin_mass + pin_mass);
                        temp_pin1_vx <= (pin1_vx_in * (pin_mass - pin_mass) + 2 * pin_mass * pin2_vx_in) / (pin_mass + pin_mass);
                        temp_pin2_vy <= (pin2_vy_in * (pin_mass - pin_mass) + 2 * pin_mass * pin1_vy_in) / (pin_mass + pin_mass);
                        temp_pin1_vy <= (pin1_vy_in * (pin_mass - pin_mass) + 2 * pin_mass * pin2_vy_in) / (pin_mass + pin_mass);
                    end else begin
                        // No collision, velocities remain unchanged
                        temp_ball_vx <= ball_vx_in;
                        temp_ball_vy <= ball_vy_in;
                        temp_pin1_vx <= pin1_vx_in;
                        temp_pin1_vy <= pin1_vy_in;
                        temp_pin2_vx <= pin2_vx_in;
                        temp_pin2_vy <= pin2_vy_in;
                    end
                end

                CALC_COLLISION: begin
                    // Update outputs with calculated velocities
                    ball_vx_out <= temp_ball_vx[15:0];
                    ball_vy_out <= temp_ball_vy[15:0];
                    pin1_vx_out <= temp_pin1_vx[15:0];
                    pin1_vy_out <= temp_pin1_vy[15:0];
                    pin2_vx_out <= temp_pin2_vx[15:0];
                    pin2_vy_out <= temp_pin2_vy[15:0];
                end

                DONE: begin
                    done <= 1; // Signal completion
                end
            endcase
        end
    end
endmodule