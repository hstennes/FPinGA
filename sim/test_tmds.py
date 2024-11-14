import cocotb
from cocotb.triggers import Timer
import os
from pathlib import Path
import sys

from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,ReadWrite,with_timeout, First, Join
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

from random import getrandbits

async def reset(rst,clk):
    """ Helper function to issue a reset signal to our module """
    rst.value = 1
    await ClockCycles(clk,3)
    rst.value = 0
    await ClockCycles(clk,2)

async def drive_data(dut,data_byte,control_bits,ve_bit):
    """ submit a set of data values as input, then wait a clock cycle for them to stay there. """
    dut.data_in.value = data_byte
    dut.control_in.value = control_bits
    dut.ve_in.value = ve_bit
    await ClockCycles(dut.clk_in,1)
    
@cocotb.test()
async def test_tmds(dut):
    """ Your simulation test!
        TODO: Flesh this out with value sets and print statements. Maybe even some assertions, as a treat.
    """
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # set all inputs to 0
    dut.data_in.value = 0
    dut.control_in.value = 0
    dut.ve_in.value = 0
    # use helper function to assert reset signal
    await reset(dut.rst_in,dut.clk_in)

    # example usage of the helper function to set all the input values you want to set
    # you probably want to make lots more of these.
    await drive_data(dut, 0x0, 0b00, 1)
    await drive_data(dut, 0xd, 0b00, 1)
    await drive_data(dut, 0x1a, 0b00, 1)
    await drive_data(dut, 0x27, 0b00, 1)
    await drive_data(dut, 0x34, 0b00, 1)
    await drive_data(dut, 0x41, 0b00, 1)
    await drive_data(dut, 0x4e, 0b00, 1)
    await drive_data(dut, 0x5b, 0b00, 1)
    await drive_data(dut, 0x68, 0b00, 1)
    await drive_data(dut, 0x75, 0b00, 1)
    await drive_data(dut, 0x0, 0b00, 1)
    await drive_data(dut, 0xb, 0b00, 1)
    await drive_data(dut, 0x16, 0b00, 1)
    await drive_data(dut, 0x21, 0b00, 1)
    await drive_data(dut, 0x2c, 0b00, 1)
    await drive_data(dut, 0x37, 0b00, 1)
    await drive_data(dut, 0x42, 0b00, 1)
    await drive_data(dut, 0x4d, 0b00, 1)
    await drive_data(dut, 0x58, 0b00, 1)
    await drive_data(dut, 0x63, 0b00, 1)
    await drive_data(dut, 0x00, 0b00, 1)
    await drive_data(dut, 0x4f, 0b00, 1)
    await drive_data(dut, 0x9e, 0b00, 1)
    await drive_data(dut, 0xed, 0b00, 1)

    
def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "tmds_encoder.sv", proj_path / "hdl" / "tm_choice.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="tmds_encoder",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="tmds_encoder",
        test_module="test_tmds",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_tmds_runner()