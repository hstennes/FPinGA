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
async def test_ball(dut):
    """Cocotb test for ball module"""

    # Start the clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    print("Clock started")

    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 5)

    dut.valid_in.value = 1
    dut.initial_speed_x.value = 0
    dut.initial_speed_y.value = 500
    dut.initial_spin.value = 0

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 0
    print("1: x, y, vx, ,vy, col")
    print(str(dut.ball_x.value))
    print(str(dut.ball_y.value))
    print(str(dut.speed_x.value))
    print(str(dut.speed_y.value))
    print(str(dut.check_collision.value))

    await RisingEdge(dut.clk_in)
    print("2: x, y, vx, ,vy, col")
    print(str(dut.ball_x.value))
    print(str(dut.ball_y.value))
    print(str(dut.speed_x.value))
    print(str(dut.speed_y.value))
    print(str(dut.check_collision.value))

    await ClockCycles(dut.clk_in, 5)

    await RisingEdge(dut.clk_in)
    print("3: x, y, vx, ,vy, col")
    print(str(dut.ball_x.value))
    print(str(dut.ball_y.value))
    print(str(dut.speed_x.value))
    print(str(dut.speed_y.value))
    print(str(dut.check_collision.value))

    
    # Wait for the data to propagate
    # for i in range (10):
    #     await ClockCycles(dut.clk_in, 1)
    #     print(dut.line_out.value)

    # # assert dut.bram_out.value == {0x0007,0x000F,0x0007}, f"line_buffer_out is {dut.line_buffer_out.value}, expected 6"
    # assert dut.hcount_out.value == 7-5, f"hcount_out is {dut.hcount_out.value}, expected 2"
    # assert dut.vcount_out.value == 7, f"vcount_out is {dut.vcount_out.value}, expected 7"

    dut._log.info("Test completed successfully")


def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "ball.sv"]
    # sources += [proj_path / "hdl" / "kernels.sv"]
    # sources += [proj_path / "hdl" / "line_buffer.sv"]
    # sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="ball",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="ball",
        test_module="test_ball",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
