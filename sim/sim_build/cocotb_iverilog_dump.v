module cocotb_iverilog_dump();
initial begin
    $dumpfile("/mnt/c/Users/deniz/OneDrive/Documents/6.205/FPinGA/sim/sim_build/camera.fst");
    $dumpvars(0, camera);
end
endmodule
