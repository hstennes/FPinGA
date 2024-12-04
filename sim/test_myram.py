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
async def test_myram(dut):
    """cocotb test?"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.aclk, 10, units="ns").start())
    await ClockCycles(dut.aclk, 3)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.aresetn.value = 0
    dut.write.value = 7
    dut.read.value = 8
    dut.data.value = 10
    await ClockCycles(dut.aclk, 1)
    dut.write.value = 8
    dut.read.value = 8
    dut.data.value = 11
    await ClockCycles(dut.aclk, 1)
    dut.write.value = 8
    dut.read.value = 8
    dut.data.value = 12
    await ClockCycles(dut.aclk, 1)
    dut.write.value = 8
    dut.read.value = 7
    dut.data.value = 13
    await ClockCycles(dut.aclk, 2)

def runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "myram.sv"] #grow/modify this as needed.
    sources.append(proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v")
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="myram",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="myram",
        test_module="test_myram",
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