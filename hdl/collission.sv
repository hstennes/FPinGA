`timescale 1ns / 1ps
`default_nettype none

//USE BRAMS OR PIPELINE STORE IN REGISTERS

module CollisionFSM (
    input wire clk_in,                     
    input wire rst_in,
    input wire valid_in, 
    input wire [15:0] ball_x,          
    input wire [15:0] ball_y,     
    input wire [9:0] [15:0] pins_x,       
    input wire [9:0] [15:0] pins_y,        
    input wire [9:0] [15:0] pins_vx_in,       
    input wire [9:0] [15:0] pins_vy_in,        
    input wire [15:0] ball_vx_in,       
    input wire [15:0] ball_vy_in, 
    // input wire [9:0] pins_hit_in,
    output logic [9:0] [15:0] pins_vx_out, 
    output logic [9:0] [15:0] pins_vy_out, 
    output logic [9:0] pins_hit,
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
    // logic [9:0] pins_hit;
   
    always @(posedge clk_in) begin
        if (rst_in) begin
            pins_hit_out <= 0;
            coll_ball_pin <= 0;
            coll_pin0_pin <= 0;
            coll_pin1_pin <= 0;
            coll_pin2_pin <= 0;
            coll_pin3_pin <= 0;
            coll_pin4_pin <= 0;
            coll_pin5_pin <= 0;
            coll_pin6_pin <= 0;
            coll_pin7_pin <= 0;
            coll_pin8_pin <= 0;
        end

        if (valid_in) begin
            for (int i=0; i<10; i=i+1) begin
                dist_ball_pin[i] <= (ball_x - pins_x[i]) * (ball_x - pins_x[i]) + (ball_y - pins_y[i]) * (ball_y - pins_y[i]);
                coll_ball_pin[i] <= !pins_hit[i] * (dist_ball_pin[i] <= (ball_radius + pin_radius) * (ball_radius + pin_radius));
                if (coll_ball_pin[i]) begin
                    pins_vx_out[i] <= (2*ball_mass*ball_vx_in)/(ball_mass+pin_mass) - pin_vx_in[i]*(ball_mass-pin_mass)/(ball_mass+pin_mass);
                    pins_vy_out[i] <= (2*ball_mass*ball_vy_in)/(ball_mass+pin_mass) - pin_vy_in[i]*(ball_mass-pin_mass)/(ball_mass+pin_mass);
                    pins_hit_out[i] <= 1;
                end
            end
            for (int i=0; i<9; i=i+1) begin
                dist_pin9_pin[i] <= (pins_x[9] - pins_x[i]) * (pins_x[9] - pins_x[i]) + (pins_y[9] - pins_y[i]) * (pins_y[9] - pins_y[i]);
                coll_pin9_pin[i] <= !pins_hit[i] * (dist_pin9_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin9_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[9];
                    pins_vy_out[i] <= pins_vy_in[9];
                    pins_vx_out[9] <= pins_vx_in[i];
                    pins_vy_out[9] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[9] <= 1;
                end
            end
            
            for (int i=0; i<8; i=i+1) begin
                dist_pin8_pin[i] = (pins_x[8] - pins_x[i]) * (pins_x[8] - pins_x[i]) + (pins_y[8] - pins_y[i]) * (pins_y[8] - pins_y[i]);
                coll_pin8_pin[i] = !pins_hit[i] * (dist_pin8_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin8_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[8];
                    pins_vy_out[i] <= pins_vy_in[8];
                    pins_vx_out[8] <= pins_vx_in[i];
                    pins_vy_out[8] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[8] <= 1;
                end
            end

            for (int i=0; i<7; i=i+1) begin
                dist_pin7_pin[i] = (pins_x[7] - pins_x[i]) * (pins_x[7] - pins_x[i]) + (pins_y[7] - pins_y[i]) * (pins_y[7] - pins_y[i]);
                coll_pin7_pin[i] = !pins_hit[i] * (dist_pin7_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin7_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[7];
                    pins_vy_out[i] <= pins_vy_in[7];
                    pins_vx_out[7] <= pins_vx_in[i];
                    pins_vy_out[7] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[7] <= 1;
                end
            end
            
            for (int i=0; i<6; i=i+1) begin
                dist_pin6_pin[i] = (pins_x[6] - pins_x[i]) * (pins_x[6] - pins_x[i]) + (pins_y[6] - pins_y[i]) * (pins_y[6] - pins_y[i]);
                coll_pin6_pin[i] = !pins_hit[i] * (dist_pin6_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin6_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[6];
                    pins_vy_out[i] <= pins_vy_in[6];
                    pins_vx_out[6] <= pins_vx_in[i];
                    pins_vy_out[6] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[6] <= 1;
                end
            end
            
            for (int i=0; i<5; i=i+1) begin
                dist_pin5_pin[i] = (pins_x[5] - pins_x[i]) * (pins_x[5] - pins_x[i]) + (pins_y[5] - pins_y[i]) * (pins_y[5] - pins_y[i]);
                coll_pin5_pin[i] = !pins_hit[i] * (dist_pin5_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin5_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[5];
                    pins_vy_out[i] <= pins_vy_in[5];
                    pins_vx_out[5] <= pins_vx_in[i];
                    pins_vy_out[5] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[5] <= 1;
                end
            end

            for (int i=0; i<4; i=i+1) begin
                dist_pin4_pin[i] = (pins_x[4] - pins_x[i]) * (pins_x[4] - pins_x[i]) + (pins_y[4] - pins_y[i]) * (pins_y[4] - pins_y[i]);
                coll_pin4_pin[i] = !pins_hit[i] * (dist_pin4_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin4_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[4];
                    pins_vy_out[i] <= pins_vy_in[4];
                    pins_vx_out[4] <= pins_vx_in[i];
                    pins_vy_out[4] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[4] <= 1;
                end
            end

            for (int i=0; i<3; i=i+1) begin
                dist_pin3_pin[i] = (pins_x[3] - pins_x[i]) * (pins_x[3] - pins_x[i]) + (pins_y[3] - pins_y[i]) * (pins_y[3] - pins_y[i]);
                coll_pin3_pin[i] = !pins_hit[i] * (dist_pin3_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin3_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[3];
                    pins_vy_out[i] <= pins_vy_in[3];
                    pins_vx_out[3] <= pins_vx_in[i];
                    pins_vy_out[3] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[3] <= 1;
                end
            end

            for (int i=0; i<2; i=i+1) begin
                dist_pin2_pin[i] = (pins_x[2] - pins_x[i]) * (pins_x[2] - pins_x[i]) + (pins_y[2] - pins_y[i]) * (pins_y[2] - pins_y[i]);
                coll_pin2_pin[i] = !pins_hit[i] * (dist_pin2_pin[i] <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
                if (coll_pin2_pin[i]) begin
                    pins_vx_out[i] <= pins_vx_in[2];
                    pins_vy_out[i] <= pins_vy_in[2];
                    pins_vx_out[2] <= pins_vx_in[i];
                    pins_vy_out[2] <= pins_vy_in[i];
                    pins_hit_out[i] <= 1;
                    pins_hit_out[2] <= 1;
                end
            end
            
            dist_pin1_pin = (pins_x[1] - pins_x[0]) * (pins_x[1] - pins_x[0]) + (pins_y[1] - pins_y[0]) * (pins_y[1] - pins_y[0]);
            coll_pin1_pin = !pins_hit[i] * (dist_pin1_pin <= (pin_radius + pin_radius) * (pin_radius + pin_radius));
            if (coll_pin1_pin) begin
                pins_vx_out[0] <= pins_vx_in[1];
                pins_vy_out[0] <= pins_vy_in[1];
                pins_vx_out[1] <= pins_vx_in[0];
                pins_vy_out[1] <= pins_vy_in[0];
                pins_hit_out[0] <= 1;
                pins_hit_out[1] <= 1;
            end
        end
    end
endmodule