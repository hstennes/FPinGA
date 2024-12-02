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
async def test_pins(dut):
    """Cocotb test for pins module"""

    # Start the clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    print("Clock started")

    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 5)

    dut.valid_in.value = 1
    dut.pins_hit_in.value = 1
    dut.pins_vx_in.value = 1
    dut.pins_vy_in.value = 1

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 0
    await ClockCycles(dut.clk_in, 1)
    await RisingEdge(dut.clk_in)
    # print("1: score, player, chance, round")
    print('vx', str(dut.pins_vx_out.value))
    print('vy', str(dut.pins_vy_out.value))
    print('x', str(dut.pins_x.value))
    print('y', str(dut.pins_y.value))

  
    dut._log.info("Test completed successfully")


def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "pins.sv"]
    # sources += [proj_path / "hdl" / "kernels.sv"]
    # sources += [proj_path / "hdl" / "line_buffer.sv"]
    # sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="pins",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="pins",
        test_module="test_pins",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
