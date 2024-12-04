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

@cocotb.test()
async def test_hit_point(dut):
    """cocotb test?"""
    im_output = Image.new('RGB', (640, 360))

    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.aclk, 10, units="ns").start())
    await ClockCycles(dut.aclk, 1)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.aresetn.value = 0
    dut.hcount_axis_tdata.value = 0
    dut.hcount_axis_tvalid.value = 1
    dut.vcount_axis_tdata.value = 0
    dut.vcount_axis_tvalid.value = 1
    dut.pixel_axis_tready.value = 1
    dut.sphere.value = make_binary_vector([0.0, 0.0, 0.0, 0, -5, -5])
    await ClockCycles(dut.aclk, 500) #make the whole pipeline valid
    for _ in range(33):
        for x in range(317, 327):
            dut.hcount_axis_tdata.value = x
            dut.hcount_axis_tvalid.value = 1
            dut.vcount_axis_tdata.value = 251
            dut.vcount_axis_tvalid.value = 1
            await ClockCycles(dut.aclk, 1) #fill the pipeline with useful stuff, but not up to the output

    dut.pixel_axis_tready.value = 0
    dut.hcount_axis_tdata.value = 0
    dut.hcount_axis_tvalid.value = 1
    dut.vcount_axis_tdata.value = 0
    dut.vcount_axis_tvalid.value = 1
    await ClockCycles(dut.aclk, 500) #try to send garbage through the pipeline with the ready signal off
    dut.pixel_axis_tready.value = 1
    await ClockCycles(dut.aclk, 500) #check that the useful stuff is still in the pipeline and unchanged

def runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "renderer.sv"] #grow/modify this as needed.
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
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="renderer",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="renderer",
        test_module="test_renderer_ready",
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