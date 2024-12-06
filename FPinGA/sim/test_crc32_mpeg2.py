import cocotb
import os
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner


@cocotb.test()
async def test_crc21_mpeg2(dut):
    
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    print("Clock started")
    
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    
    dut.data_valid_in.value = 0
    
    # Test case 1
    num_bits = 32
    data = [0,0,0,0,0,0,1,0,0,1,1,0,0,0,0,0,1,1,0,0,1,0,0,0,1,0,0,1,0,1,1,1]
    for i in range(num_bits):
        dut.data_in.value = data[i]
        dut.data_valid_in.value = 1
        await RisingEdge(dut.clk_in)
    
    print(f"data_out: {int(dut.data_out.value)}")
    # print(f"y_out: {int(dut.y_out.value)}")
    # assert int(dut.data_out.value) == 350, f"x_out: {int(dut.x_out.value)}, expected: {350}"
    # assert int(dut.y_out.value) == 350, f"y_out: {int(dut.y_out.value)}, expected: {350}"
    
    dut._log.info(f"Test 1 passed: data_out={(dut.data_out.value)}")
    await ClockCycles(dut.clk_in, 5)
    dut.data_valid_in.value = 0
    # dut.tabulate_in.value = 0

def reverse_bits(n,size):
    reversed_n = 0
    for i in range(size):
        reversed_n = (reversed_n << 1) | (n & 1)
        n >>= 1
    return reversed_n

def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "crc32_mpeg2.sv"]
    # sources += [proj_path / "hdl" / "divider.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="crc32_mpeg2",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="crc32_mpeg2",
        test_module="test_crc32_mpeg2",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
