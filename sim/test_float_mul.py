import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

@cocotb.test()
async def test_float_mul(dut):
    """cocotb test?"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.aclk, 10, units="ns").start())

    # await ClockCycles(dut.aclk, 3)
    # dut.aresetn.value = 1
    # await ClockCycles(dut.aclk, 1)
    # dut.aresetn.value = 0
    # await ClockCycles(dut.aclk, 1)
    # dut.s_axis_a_tvalid.value = 1
    # dut.s_axis_b_tvalid.value = 1
    # dut.s_axis_a_tdata.value = 0b0011111111111000000000000000000000000000000000000000000000000000
    # dut.s_axis_b_tdata.value = 0b0011111111111000000000000000000000000000000000000000000000000000
    # await ClockCycles(dut.aclk, 1)
    # dut.s_axis_a_tvalid.value = 0
    # dut.s_axis_b_tvalid.value = 0
    # dut.s_axis_a_tdata.value = 0
    # dut.s_axis_b_tdata.value = 0
    # await ClockCycles(dut.aclk, 15)
    # dut.m_axis_result_tready = 1
    # print(dut.m_axis_result_tdata.value)
    # await ClockCycles(dut.aclk, 1)
    # print(dut.m_axis_result_tdata.value)
    # await ClockCycles(dut.aclk, 5)

    await ClockCycles(dut.aclk, 3)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.aresetn.value = 0
    dut.s_axis_a_tvalid.value = 0
    dut.s_axis_a_tdata = 0
    dut.s_axis_b_tvalid.value = 0
    dut.s_axis_b_tdata = 0
    dut.m_axis_result_tready = 0
    await ClockCycles(dut.aclk, 15)
    dut.s_axis_a_tvalid.value = 1
    dut.s_axis_b_tvalid.value = 1
    dut.s_axis_a_tdata.value = 0b0011111111111000000000000000000000000000000000000000000000000000 #1.5
    dut.s_axis_b_tdata.value = 0b0011111111111000000000000000000000000000000000000000000000000000 #1.5
    await ClockCycles(dut.aclk, 1)
    dut.s_axis_a_tvalid.value = 0
    dut.s_axis_b_tvalid.value = 0
    dut.s_axis_a_tdata.value = 0
    dut.s_axis_b_tdata.value = 0
    await ClockCycles(dut.aclk, 5)
    dut.s_axis_a_tvalid.value = 1
    dut.s_axis_b_tvalid.value = 1
    dut.s_axis_a_tdata.value = 0b0100000000100011000000000000000000000000000000000000000000000000 #9.5
    dut.s_axis_b_tdata.value = 0b0011111111100000000000000000000000000000000000000000000000000000 #0.5
    await ClockCycles(dut.aclk, 1)
    dut.s_axis_a_tvalid.value = 0
    dut.s_axis_b_tvalid.value = 0
    dut.s_axis_a_tdata.value = 0
    dut.s_axis_b_tdata.value = 0
    dut.m_axis_result_tready = 1
    await ClockCycles(dut.aclk, 15)

def float_mul_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "float_mul.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="float_mul",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="float_mul",
        test_module="test_float_mul",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    float_mul_runner()