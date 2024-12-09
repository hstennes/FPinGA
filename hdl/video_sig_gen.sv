module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1024,
  parameter H_FRONT_PORCH = 24,
  parameter H_SYNC_WIDTH = 136,
  parameter H_BACK_PORCH = 160,
  parameter ACTIVE_LINES = 768,
  parameter V_FRONT_PORCH = 3,
  parameter V_SYNC_WIDTH = 6,
  parameter V_BACK_PORCH = 29,
  parameter FPS = 60)
(
  input wire pixel_clk_in,
  input wire rst_in,
  output logic [$clog2(ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH)-1:0] hcount_out,
  output logic [$clog2(ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH)-1:0] vcount_out,
  output logic vs_out, //vertical sync out
  output logic hs_out, //horizontal sync out
  output logic ad_out,
  output logic nf_out, //single cycle enable signal
  output logic [5:0] fc_out); //frame

  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH; //figure this out
  localparam TOTAL_LINES = ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH; //figure this out

  logic [$clog2(TOTAL_PIXELS)-1:0] hcount;
  logic [$clog2(TOTAL_LINES)-1:0] vcount;
  logic [5:0] fc;
  logic nf;

  // logic state;
  //your code here
  always_ff @(posedge pixel_clk_in) begin
    if (rst_in) begin
      hcount <= 0;
      vcount <= 0;
      fc <= 0;
      nf <= 0;
    
    end else begin
      if (hcount == TOTAL_PIXELS - 1) begin
        hcount <= 0;

        if (vcount == TOTAL_LINES - 1) begin
          vcount <= 0;
        end else begin
          vcount <= vcount + 1;
        end
      end else begin
        hcount <= hcount + 1;
      end

      if ((hcount == ACTIVE_H_PIXELS - 1) && (vcount == ACTIVE_LINES - 1)) begin
        nf <= 1; 
        if (fc == FPS - 1) begin
            fc <= 0;
        end else begin
          fc <= fc + 1;
        end
      end else begin
        nf <= 0;
      end
    end
  end

  assign hcount_out = hcount;
  assign vcount_out = vcount;
  assign hs_out = ((hcount < (ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH)) && (hcount > (ACTIVE_H_PIXELS + H_FRONT_PORCH - 1)));
  assign vs_out = ((vcount < (ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH)) && (vcount > (ACTIVE_LINES + V_FRONT_PORCH - 1)));
  assign ad_out = ((hcount < ACTIVE_H_PIXELS) && (vcount < ACTIVE_LINES));
  assign fc_out = fc;
  assign nf_out = nf;

endmodule
