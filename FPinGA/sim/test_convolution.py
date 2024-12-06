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
async def test_convolution(dut):
    """Cocotb test for convolution module"""

    # Start the clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    print("Clock started")

    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0

    assert dut.hcount_out.value == 0, "hcount_out not reset properly"
    assert dut.vcount_out.value == 0, "vcount_out not reset properly"
    assert dut.data_valid_out.value == 0, "data_valid_out not reset properly"

    pixel_data_pattern = [
        0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008,
        0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F, 0x0000,
        0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008,
        0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F, 0x0000,
        0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008,
        0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F, 0x0000,
        0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008,
        0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F, 0x0000
    ]
    dut.hcount_in.value = 0
    dut.vcount_in.value = 0
    vval = 0

    for i in range(64): 

        dut.hcount_in.value = i % 8
        # print(i%4)
        dut.vcount_in.value = int(vval/8)
        # print(int(vval/4))
        vval +=1 
        dut.data_in.value = pixel_data_pattern[i]
        dut.data_valid_in.value = 1
        # await ClockCycles(dut.clk_in, 2)
        await RisingEdge(dut.clk_in)
        # print(dut.bram_out[0].value)
        # print(dut.bram_out[1].value)
        # print(dut.bram_out[2].value)
        # print(dut.bram_out[3].value)
        print(dut.hcount_out.value)
        print(dut.vcount_out.value)
        # print(dut.data_valid_out.value)
        # print(dut.line_buffer_out.value)
    
    dut.data_valid_in.value = 0

    # Wait for the data to propagate
    # for i in range (10):
    #     await ClockCycles(dut.clk_in, 1)
    #     print(dut.line_out.value)

    # assert dut.bram_out.value == {0x0007,0x000F,0x0007}, f"line_buffer_out is {dut.line_buffer_out.value}, expected 6"
    assert dut.hcount_out.value == 7-5, f"hcount_out is {dut.hcount_out.value}, expected 2"
    assert dut.vcount_out.value == 7, f"vcount_out is {dut.vcount_out.value}, expected 7"

    dut._log.info("Test completed successfully")


def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "convolution.sv"]
    sources += [proj_path / "hdl" / "kernels.sv"]
    sources += [proj_path / "hdl" / "line_buffer.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="convolution",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="convolution",
        test_module="test_convolution",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()
