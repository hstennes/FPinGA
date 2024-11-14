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
    dut.trigger_in.value = 0
    dut.data_byte_in.value = 0x35
    await ClockCycles(dut.clk_in, 3) #wait three clock cycles
    assert dut.tx_wire_out.value.integer==1, "tx is not 1 on reset!"
    await  FallingEdge(dut.clk_in)
    dut.rst_in.value = 0 #un reset device
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    await  FallingEdge(dut.clk_in)
    dut._log.info("Setting Trigger")
    dut.trigger_in.value = 1
    await ClockCycles(dut.clk_in, 1,rising=False)
    dut.data_byte_in.value = 0xBE # once trigger in is off, don't expect data_in to stay the same!!
    dut.trigger_in.value = 0
    await with_timeout(FallingEdge(dut.busy_out),5000,'ns')
    await ReadOnly()
    await ReadOnly()
    # data_out = dut.data_out.value
    # dut._log.info(f"Receiver Data: {data_out}")
    await ClockCycles(dut.clk_in, 300)

def uart_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_transmit.sv"]
    sources += [proj_path / "hdl" / "counter.sv"]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 1000, 'BAUD_RATE':100} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_transmit",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_transmit",
        test_module="test_uart_transmit",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    uart_runner()