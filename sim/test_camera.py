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
async def test_camera(dut):
    """Cocotb test for convolution module"""

    # Start the clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    print("Clock started")

    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0

    
    dut.valid_in.value = 1
    dut.light_in.value = 1
    dut.x_in.value = 100
    dut.y_in.value = 50
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 1
    dut.x_in.value = 1
    dut.y_in.value = 1 
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)
    

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 0
    dut.x_in.value = 2
    dut.y_in.value = 2 
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 1
    dut.x_in.value = 3
    dut.y_in.value = 3 
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 1
    dut.x_in.value = 50
    dut.y_in.value = 100
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 0
    dut.x_in.value = 4
    dut.y_in.value = 4 
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 0
    dut.x_in.value = 4
    dut.y_in.value = 4 
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 0
    dut.x_in.value = 4
    dut.y_in.value = 4 
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)
    await ClockCycles(dut.clk_in, 200)

    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 1
    dut.x_in.value = 2
    dut.y_in.value = 2 
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)
    
    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 1
    dut.x_in.value = 50
    dut.y_in.value = 100
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)
 
    await RisingEdge(dut.clk_in)
    dut.valid_in.value = 1
    dut.light_in.value = 0
    dut.x_in.value = 50
    dut.y_in.value = 100
    print("vx: ", dut.vx_out.value)
    print("vy: ", dut.vy_out.value)
    print("valid: ", dut.valid_out.value)

    await ClockCycles(dut.clk_in, 700)

    # Wait for the data to propagate
    # for i in range (10):
    #     await ClockCycles(dut.clk_in, 1)
    #     print(dut.line_out.value)

    # assert dut.bram_out.value == {0x0007,0x000F,0x0007}, f"line_buffer_out is {dut.line_buffer_out.value}, expected 6"
    # assert dut.hcount_out.value == 7-5, f"hcount_out is {dut.hcount_out.value}, expected 2"
    # assert dut.vcount_out.value == 7, f"vcount_out is {dut.vcount_out.value}, expected 7"

    dut._log.info("Test completed successfully")


def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "camera.sv"]
    sources += [proj_path / "hdl" / "signed_div.sv"]
    # sources += [proj_path / "hdl" / "line_buffer.sv"]
    # sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="camera",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="camera",
        test_module="test_camera",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
