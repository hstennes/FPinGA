module line_buffer (
            input wire clk_in, //system clock
            input wire rst_in, //system reset
 
            input wire [10:0] hcount_in, //current hcount being read
            input wire [9:0] vcount_in, //current vcount being read
            input wire [15:0] pixel_data_in, //incoming pixel
            input wire data_valid_in, //incoming  valid data signal
 
            output logic [KERNEL_SIZE-1:0][15:0] line_buffer_out, //output pixels of data
            output logic [10:0] hcount_out, //current hcount being read
            output logic [9:0] vcount_out, //current vcount being read
            output logic data_valid_out //valid data out signal
  );
  parameter HRES = 1280;
  parameter VRES = 720;
 
  localparam KERNEL_SIZE = 3;

  logic [1:0] ram_cycle;

  logic valid_buffer;
  logic [10:0] hcount_buffer;
  logic [10:0] vcount_buffer;

  logic [KERNEL_SIZE:0][15:0] ram_out;

  generate
    genvar i;
    for(i = 0; i < KERNEL_SIZE + 1; i=i+1)begin
        xilinx_true_dual_port_read_first_2_clock_ram #(
            .RAM_WIDTH(16),                       // Specify RAM data width
            .RAM_DEPTH(HRES),                     // Specify RAM depth (number of entries)
            .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
            .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
        ) ram (
            .addra(hcount_in),   // Port A address bus, width determined from RAM_DEPTH
            .addrb(hcount_in),   // Port B address bus, width determined from RAM_DEPTH
            .dina(pixel_data_in),     // Port A RAM input data, width determined from RAM_WIDTH
            .dinb(16'b0),     // Port B RAM input data, width determined from RAM_WIDTH
            .clka(clk_in),     // Port A clock
            .clkb(clk_in),     // Port B clock
            .wea(i == ram_cycle && data_valid_in),       // Port A write enable
            .web(1'b0),       // Port B write enable
            .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
            .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
            .rsta(rst_in),     // Port A output reset (does not affect memory contents)
            .rstb(rst_in),     // Port B output reset (does not affect memory contents)
            .regcea(1'b0), // Port A output register enable
            .regceb(1'b1), // Port B output register enable
            // .douta(douta),   // Port A RAM output data, width determined from RAM_WIDTH
            .doutb(ram_out[i])    // Port B RAM output data, width determined from RAM_WIDTH
        );
    end
  endgenerate

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
        ram_cycle <= 0;
    end
    else begin
        if(hcount_in == HRES - 1 && data_valid_in) begin
            ram_cycle <= ram_cycle == KERNEL_SIZE ? 0 : ram_cycle + 1;
        end

        valid_buffer <= data_valid_in;
        data_valid_out <= valid_buffer;

        hcount_buffer <= hcount_in;
        hcount_out <= hcount_buffer;

        vcount_buffer <= vcount_in;
        vcount_out <= vcount_buffer == 0 ? VRES - 2 : (vcount_buffer == 1 ? VRES - 1 : vcount_buffer - 2);
    end
  end

  always_comb begin
    if(ram_cycle == 0) begin
        line_buffer_out = {ram_out[1], ram_out[2], ram_out[3]};
    end else if(ram_cycle == 1) begin
        line_buffer_out = {ram_out[2], ram_out[3], ram_out[0]};
    end else if(ram_cycle == 2) begin
        line_buffer_out = {ram_out[3], ram_out[0], ram_out[1]};
    end else begin
        line_buffer_out = {ram_out[0], ram_out[1], ram_out[2]};
    end
  end

endmodule