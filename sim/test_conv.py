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
from PIL import Image

def get_vals(buffer_out):
    try:
        buffer_out = buffer_out.integer
        first = (buffer_out & 0xFFFF00000000) >> 32
        second = (buffer_out & 0x0000FFFF0000) >> 16
        third = buffer_out & 0x00000000FFFF
        return first, second, third
    except:
        return None
    
def rgb565_encode(pixel):
    return ((pixel[0] >> 3) << 11) | ((pixel[1] >> 2) << 5) | (pixel[2] >> 3)
    
def encode_pixels(im_input, x, y):
    pixels = im_input.getpixel((x, y - 1)), im_input.getpixel((x, y)), im_input.getpixel((x, y + 1))
    return (rgb565_encode(pixels[0]) << 32) | (rgb565_encode(pixels[1]) << 16) | rgb565_encode(pixels[2])

def decode_pixel(encoded):
    try:
        encoded = encoded.integer
        return (encoded & 0b1111100000000000) >> 8, (encoded & 0b0000011111100000) >> 3, (encoded & 0b0000000000011111) << 3
    except:
        return (0, 0, 0)

@cocotb.test()
async def test_conv(dut):
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 1)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 1)

    im_input = Image.open("clowns.png")
    im_input = im_input.convert('RGB')
    im_output = Image.new('RGB', (1280, 720))

    for y in range(1, 719):
        for x in range(1280):
            dut.hcount_in.value = x
            dut.vcount_in.value = y
            dut.data_in.value = encode_pixels(im_input, x, y)
            dut.data_valid_in.value = x < 1280 and y < 720

            await ClockCycles(dut.clk_in, 1)
            
            if dut.vcount_out.value.integer < 720 and dut.hcount_out.value.integer < 1280:
                im_output.putpixel((dut.hcount_out.value.integer, dut.vcount_out.value.integer), decode_pixel(dut.line_out.value))

    im_output.save('output.png','PNG')

def conv_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "convolution.sv"]
    sources.append(proj_path / "hdl" / "kernels.sv")
    build_test_args = ["-Wall"]
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="convolution",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="convolution",
        test_module="test_conv",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    conv_runner()