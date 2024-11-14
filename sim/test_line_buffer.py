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

def get_vals(buffer_out):
    try:
        buffer_out = buffer_out.integer
        first = (buffer_out & 0xFFFF00000000) >> 32
        second = (buffer_out & 0x0000FFFF0000) >> 16
        third = buffer_out & 0x00000000FFFF
        return first, second, third
    except:
        return None
    
    # return (first, second, third)
    # print(type(buffer_out))
    # return (int(buffer_out[0:16], 2), int(buffer_out[16:32], 2), int(buffer_out[32:48], 2))

@cocotb.test()
async def test_line_buffer(dut):
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 1)

    for y in range(725):
        for x in range(1285):
            dut.hcount_in.value = x
            dut.vcount_in.value = y
            dut.pixel_data_in.value = (x + y * 720) & 0xFFFF
            dut.data_valid_in.value = x < 1280 and y < 720
            await ClockCycles(dut.clk_in, 1)
            if 3 <= y <= 6 and x < 15:
                print(f'({x}, {y}):', get_vals(dut.line_buffer_out.value), dut.data_valid_out.value)
            


def line_buffer_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "line_buffer.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v"]
    build_test_args = ["-Wall"]
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="line_buffer",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="line_buffer",
        test_module="test_line_buffer",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    line_buffer_runner()