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
async def test_traffic(dut):
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 1)
    dut.read_axis_ready.value = 1
    dut.read_axis_valid.value = 1
    dut.read_request_ready.value = 1
    dut.read_request_valid.value = 1
    dut.write_axis_ready.value = 1
    dut.write_axis_valid.value = 1
    dut.write_axis_tlast.value = 0
    await ClockCycles(dut.clk_in, 200000)

def com_runner():
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
        hdl_toplevel="traffic_evt_counter",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="traffic_evt_counter",
        test_module="test_traffic",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    com_runner()