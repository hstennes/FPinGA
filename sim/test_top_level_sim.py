import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from float_utils import *
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from PIL import Image

def decode_pixel(encoded):
    try:
        encoded = encoded.integer
        return (encoded & 0xFF0000) >> 16, (encoded & 0x00FF00) >> 8, (encoded & 0x0000FF)
    except:
        return (0, 0, 0)

def decode_pixel_vga(R, G, B):
    try:
        return R.integer << 4, G.integer << 4, B.integer << 4
    except:
        return (0, 0, 0)

@cocotb.test()
async def test_top_level_sim(dut):
    """cocotb test?"""

    im_output = Image.new('RGB', (1024, 768))

    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.CLK100MHZ, 10, units="ns").start())
    await ClockCycles(dut.CLK100MHZ, 3)
    dut.BTNC.value = 1
    await ClockCycles(dut.CLK100MHZ, 3)
    dut.BTNC.value = 0

    hcount = 0
    vcount = 0
    prev_hsync = 0
    prev_vsync = 0

    for i in range(200000):
        if dut.VGA_VS.value == 1 and prev_vsync == 0:
            hcount = 0
            vcount = 0
        elif dut.VGA_HS.value == 1 and prev_hsync == 0:
            hcount = 0
            vcount += 1
            print(vcount)
        
        if dut.VGA_VS.value == 0 and dut.VGA_HS.value == 0 and hcount < 1024:
            # print(hcount, vcount)
            im_output.putpixel((hcount, vcount), decode_pixel_vga(dut.VGA_R.value, dut.VGA_G.value, dut.VGA_B.value))
            hcount += 1

        prev_vsync = dut.VGA_VS.value
        prev_hsync = dut.VGA_HS.value
        await ClockCycles(dut.CLK100MHZ, 1)


    # for i in range(800):
    #     await ClockCycles(dut.CLK100MHZ, 1000)
    #     print("iter", i)

    im_output.save('output_full_sim.png','PNG')

def runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "top_level_sim.sv"] #grow/modify this as needed.
    sources.append(proj_path / "hdl" / "float_add.sv")
    sources.append(proj_path / "hdl" / "float_mul.sv")
    sources.append(proj_path / "hdl" / "float_div.sv")
    sources.append(proj_path / "hdl" / "float_sqrt.sv")
    sources.append(proj_path / "hdl" / "float_lt.sv")
    sources.append(proj_path / "hdl" / "float_min.sv")
    sources.append(proj_path / "hdl" / "axi_pipe.sv")
    sources.append(proj_path / "hdl" / "vec_add.sv")
    sources.append(proj_path / "hdl" / "vec_dot.sv")
    sources.append(proj_path / "hdl" / "quadratic.sv")
    sources.append(proj_path / "hdl" / "float_mul_pow2.sv")
    sources.append(proj_path / "hdl" / "float_fused_mul_add.sv")
    sources.append(proj_path / "hdl" / "float_sum3.sv")
    sources.append(proj_path / "hdl" / "vec_mul.sv")
    sources.append(proj_path / "hdl" / "vec_clamp.sv")
    sources.append(proj_path / "hdl" / "vec_to_pixel_color.sv")
    sources.append(proj_path / "hdl" / "float_to_fixed.sv")
    sources.append(proj_path / "hdl" / "fixed_to_float.sv")
    sources.append(proj_path / "hdl" / "float_clamp.sv")
    sources.append(proj_path / "hdl" / "vec_fused_mul_add.sv")
    sources.append(proj_path / "hdl" / "vec_norm.sv")
    sources.append(proj_path / "hdl" / "ray_intersect.sv")
    sources.append(proj_path / "hdl" / "ray_from_pixel.sv")
    sources.append(proj_path / "hdl" / "hit_point.sv")
    sources.append(proj_path / "hdl" / "lambert.sv")
    sources.append(proj_path / "hdl" / "float_argmin.sv")
    sources.append(proj_path / "hdl" / "float_multi_argmin.sv")
    sources.append(proj_path / "hdl" / "check_objects.sv")
    sources.append(proj_path / "hdl" / "vga_sig_gen.sv")
    sources.append(proj_path / "hdl" / "renderer_sig_gen.sv")
    sources.append(proj_path / "hdl" / "evt_counter.sv")
    sources.append(proj_path / "hdl" / "counter.sv")
    sources.append(proj_path / "hdl" / "full_renderer.sv")
    sources.append(proj_path / "hdl" / "camera_input.sv")
    sources.append(proj_path / "hdl" / "camera.sv")
    sources.append(proj_path / "hdl" / "ball.sv")
    sources.append(proj_path / "hdl" / "collision.sv")
    sources.append(proj_path / "hdl" / "pins.sv")
    sources.append(proj_path / "hdl" / "divider.sv")
    sources.append(proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v")
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="top_level_sim",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="top_level_sim",
        test_module="test_top_level_sim",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    runner()

# 0000000000000000 0000000000000000 bff5183f99f3dc86 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 0000000000000000 bff693e93e478e5f 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 4014000000000000 4014000000000000

# c019f8499af611f4 c00066eb1e807723 c02f014bcc4129da

# c019f8499af611f4 40079914e17f88dd c025014bcc4129da

# c019f8499af611f4 40079914e17f88dd c025014bcc4129da

# bfdf8499af611f40 0000000000000000 3fdfd68677dac4c0

'''
3f800000
00000000
c0c00000
c0a00000
c1800000
00000000
3f800000
00000000
c0000000
c0a00000
c1800000
00000000
3f800000
00000000
40000000
c0a00000
c1800000
00000000
3f800000
00000000
40c00000
c0a00000
c1800000
00000000
3f800000
00000000
c0800000
c0a00000
c1600000
00000000
3f800000
00000000
00000000
c0a00000
c1600000
00000000
3f800000
00000000
40800000
c0a00000
c1600000
00000000
3f800000
00000000
c0000000
c0a00000
c1400000
00000000
3f800000
00000000
40000000
c0a00000
c1400000
00000000
3f800000
00000000
00000000
c0a00000
c1200000
'''