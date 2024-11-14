import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

@cocotb.test()
async def test_center_of_mass(dut):
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 1)

    #Simple test with 2 pixels
    dut.x_in.value = 100
    dut.y_in.value = 100
    dut.valid_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.x_in.value = 500
    dut.y_in.value = 500
    dut.valid_in.value = 0
    await ClockCycles(dut.clk_in, 1)
    dut.x_in.value = 200
    dut.y_in.value = 200
    dut.valid_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.valid_in.value = 0
    dut.tabulate_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.tabulate_in.value = 0
    await RisingEdge(dut.valid_out)
    assert dut.x_out.value == 150, f'expected 150, got {dut.x_out.value}'
    assert dut.y_out.value == 150, f'expected 150, got {dut.y_out.value}'
    await ClockCycles(dut.clk_in, 2)
    assert dut.valid_out.value == 0, "expected one cycle valid out"

    for x in range(700):
        dut.x_in.value = x
        dut.y_in.value = x
        dut.valid_in.value = 1
        await ClockCycles(dut.clk_in, 1)
    dut.valid_in.value = 0
    dut.tabulate_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.tabulate_in.value = 0
    await RisingEdge(dut.valid_out)
    assert dut.x_out.value == 349, f'expected 349, got {dut.x_out.value}'
    assert dut.y_out.value == 349, f'expected 349, got {dut.y_out.value}'
    await ClockCycles(dut.clk_in, 2)
    assert dut.valid_out.value == 0, "expected one cycle valid out"

    dut.x_in.value = 545
    dut.y_in.value = 123
    dut.valid_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.valid_in.value = 0
    dut.tabulate_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.tabulate_in.value = 0
    await RisingEdge(dut.valid_out)
    assert dut.x_out.value == 545, f'expected 545, got {dut.x_out.value}'
    assert dut.y_out.value == 123, f'expected 123, got {dut.y_out.value}'
    await ClockCycles(dut.clk_in, 2)
    assert dut.valid_out.value == 0, "expected one cycle valid out"

    for x in range(1024):
        for y in range(768):
            dut.x_in.value = x
            dut.y_in.value = y
            dut.valid_in.value = 1
            await ClockCycles(dut.clk_in, 1)
    dut.valid_in.value = 0
    dut.tabulate_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.tabulate_in.value = 0
    await RisingEdge(dut.valid_out)
    assert dut.x_out.value == 511, f'expected 511, got {dut.x_out.value}'
    assert dut.y_out.value == 383, f'expected 383, got {dut.y_out.value}'
    await ClockCycles(dut.clk_in, 2)
    assert dut.valid_out.value == 0, "expected one cycle valid out"

def traffic_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "traffic_evt_counter.sv"]
    sources += [proj_path / "hdl" / "evt_counter.sv"]
    build_test_args = ["-Wall"]
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="center_of_mass",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="center_of_mass",
        test_module="test_center_of_mass",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    com_runner()