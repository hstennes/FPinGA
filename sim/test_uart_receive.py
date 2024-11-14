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

# utility function to reverse bits:
def reverse_bits(n,size):
    reversed_n = 0
    for i in range(size):
        reversed_n = (reversed_n << 1) | (n & 1)
        n >>= 1
    return reversed_n

# test spi message:
SPI_RESP_MSG = 0x2345
#flip them:
SPI_RESP_MSG = reverse_bits(SPI_RESP_MSG,16)

@cocotb.test()
async def test_a(dut):
    """cocotb test for seven segment controller"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut._log.info("Holding reset...")
    dut.rst_in.value = 1
    dut.rx_wire_in.value = 1
    await ClockCycles(dut.clk_in, 3) #wait three clock cycles
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    await  FallingEdge(dut.clk_in)
    dut._log.info("Setting start bit")
    dut.rx_wire_in.value = 0
    await ClockCycles(dut.clk_in, 3,rising=False)
    dut.rx_wire_in.value = 1
    # dut.rx_wire_in.value = 1
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut.rx_wire_in.value = 1
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut.rx_wire_in.value = 1
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut.rx_wire_in.value = 0
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut.rx_wire_in.value = 1
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut.rx_wire_in.value = 0
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut.rx_wire_in.value = 0
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut.rx_wire_in.value = 1
    # await ClockCycles(dut.clk_in, 50,rising=False)
    # dut._log.info("Setting stop bit")
    # dut.rx_wire_in.value = 1
    # await ClockCycles(dut.clk_in, 10,rising=False)
    # await with_timeout(FallingEdge(dut.busy_out),5000,'ns')
    # await ReadOnly()
    # await ReadOnly()
    await ClockCycles(dut.clk_in, 3000)

def uart_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_receive.sv"]
    sources += [proj_path / "hdl" / "counter.sv"]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 1000, 'BAUD_RATE':20} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_receive",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_receive",
        test_module="test_uart_receive",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    uart_runner()