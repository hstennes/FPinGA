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

@cocotb.test()
async def test_ray_sphere_intersection(dut):
    """cocotb test?"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.aclk, 10, units="ns").start())

    await ClockCycles(dut.aclk, 3)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.aresetn.value = 0
    dut.sphere_loc.value = 0
    dut.sphere_loc_valid.value = 0
    dut.ray_axis_tdata.value = 0
    dut.ray_axis_tvalid.value = 0
    dut.t_axis_tready.value = 0
    await ClockCycles(dut.aclk, 125)
    dut.sphere_loc.value = make_binary_vector([0.0, -5.0, -5.0])
    dut.sphere_loc_valid.value = 1
    await ClockCycles(dut.aclk, 2)
    dut.ray_axis_tdata.value = make_binary_vector([-0.02032806, -0.36880913, -0.92928284, 0.0, 0.0, 5.0])
    dut.ray_axis_tvalid.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.sphere_loc.value = 0
    dut.sphere_loc_valid.value = 0
    dut.ray_axis_tdata.value = 0
    dut.ray_axis_tvalid.value = 0
    await ClockCycles(dut.aclk, 5)
    dut.sphere_loc.value = make_binary_vector([0.0, -5.0, -5.0])
    dut.sphere_loc_valid.value = 1
    dut.ray_axis_tdata.value = make_binary_vector([-0.02032806, -0.36880913, -0.92928284, 0.0, 0.0, 5.0])
    dut.ray_axis_tvalid.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.sphere_loc.value = 0
    dut.sphere_loc_valid.value = 0
    dut.ray_axis_tdata.value = 0
    dut.ray_axis_tvalid.value = 0
    dut.t_axis_tready.value = 1
    await ClockCycles(dut.aclk, 175)

def ray_sphere_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "ray_sphere_intersection.sv"] #grow/modify this as needed.
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
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="ray_sphere_intersection",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="ray_sphere_intersection",
        test_module="test_ray_sphere_intersection",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    ray_sphere_runner()

# 0000000000000000 0000000000000000 bff5183f99f3dc86 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 4014000000000000 4014000000000000