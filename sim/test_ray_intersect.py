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
async def test_ray_intersct(dut):
    """cocotb test?"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.aclk, 10, units="ns").start())

    # await ClockCycles(dut.aclk, 3)
    # dut.aresetn.value = 1
    # await ClockCycles(dut.aclk, 1)
    # dut.aresetn.value = 0
    # dut.obj_axis_tdata.value = 0
    # dut.obj_axis_is_cylinder.value = 0
    # dut.obj_axis_tvalid.value = 0
    # dut.ray_axis_tdata.value = 0
    # dut.ray_axis_tvalid.value = 0
    # dut.t_axis_tready.value = 0
    # await ClockCycles(dut.aclk, 125)
    # dut.obj_axis_tdata.value = make_binary_vector([0.0, 0.0, 0.0, 0.0, -5.0, -5.0])
    # dut.obj_axis_is_cylinder.value = 0
    # dut.obj_axis_tvalid.value = 1
    # dut.ray_axis_tdata.value = make_binary_vector([-0.01666667, -0.39444444, -1.0, 0.0, 0.0, 5.0])
    # dut.ray_axis_tvalid.value = 1
    # await ClockCycles(dut.aclk, 1)
    # dut.obj_axis_tdata.value = 0
    # dut.obj_axis_is_cylinder.value = 0
    # dut.obj_axis_tvalid.value = 0
    # dut.ray_axis_tdata.value = 0
    # dut.ray_axis_tvalid.value = 0
    # await ClockCycles(dut.aclk, 5)
    # dut.obj_axis_tdata.value = make_binary_vector([0.0, 0.0, 0.0, 0.0, -5.0, -5.0])
    # dut.obj_axis_is_cylinder.value = 0
    # dut.obj_axis_tvalid.value = 1
    # dut.ray_axis_tdata.value = make_binary_vector([-0.01666667, -0.39444444, -1.0, 0.0, 0.0, 5.0])
    # dut.ray_axis_tvalid.value = 1
    # await ClockCycles(dut.aclk, 1)
    # dut.obj_axis_tdata.value = 0
    # dut.obj_axis_is_cylinder.value = 0
    # dut.obj_axis_tvalid.value = 0
    # dut.ray_axis_tdata.value = 0
    # dut.ray_axis_tvalid.value = 0
    # dut.t_axis_tready.value = 1
    # await ClockCycles(dut.aclk, 175)

    await ClockCycles(dut.aclk, 3)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.aresetn.value = 0
    dut.obj_axis_tdata.value = 0
    dut.obj_axis_is_cylinder.value = 1
    dut.obj_axis_tvalid.value = 0
    dut.ray_axis_tdata.value = 0
    dut.ray_axis_tvalid.value = 0
    dut.t_axis_tready.value = 0
    await ClockCycles(dut.aclk, 125)
    dut.obj_axis_tdata.value = make_binary_vector([0.0, 1.0, 0.0, -6, -5, -16])
    dut.obj_axis_is_cylinder.value = 1
    dut.obj_axis_tvalid.value = 1
    dut.ray_axis_tdata.value = make_binary_vector([-0.31666667, -0.1, -1.0, 0.0, 0.0, 5.0])
    dut.ray_axis_tvalid.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.obj_axis_tdata.value = 0
    dut.obj_axis_is_cylinder.value = 1
    dut.obj_axis_tvalid.value = 0
    dut.ray_axis_tdata.value = 0
    dut.ray_axis_tvalid.value = 0
    await ClockCycles(dut.aclk, 5)
    dut.obj_axis_tdata.value = make_binary_vector([0.0, 1.0, 0.0, -6, -5, -16])
    dut.obj_axis_is_cylinder.value = 1
    dut.obj_axis_tvalid.value = 1
    dut.ray_axis_tdata.value = make_binary_vector([-0.31666667, -0.1, -1.0, 0.0, 0.0, 5.0])
    dut.ray_axis_tvalid.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.obj_axis_tdata.value = 0
    dut.obj_axis_is_cylinder.value = 1
    dut.obj_axis_tvalid.value = 0
    dut.ray_axis_tdata.value = 0
    dut.ray_axis_tvalid.value = 0
    dut.t_axis_tready.value = 1
    await ClockCycles(dut.aclk, 175)

def runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "ray_intersect.sv"] #grow/modify this as needed.
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
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="ray_intersect",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="ray_intersect",
        test_module="test_ray_intersect",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    runner()

# 0000000000000000 0000000000000000 bff5183f99f3dc86 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 0000000000000000 bff693e93e478e5f 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 4014000000000000 4014000000000000

# bf91111111111100 bfd93e93e93e93ea bff0000000000000

# 7f22222222222201 7fb27d27d27d27d5 7fe0000000000000 0000000000000000 0000000000000000 4014000000000000