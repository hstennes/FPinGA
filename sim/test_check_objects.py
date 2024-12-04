import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from float_utils import *
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from PIL import Image

width, height = 640, 360
fov = 90
aspect_ratio = width / height
angle = np.tan(np.radians(fov / 2))
PX_MUL = 2 / width * angle * aspect_ratio
PX_ADD = -angle * aspect_ratio
PY_MUL = -2 / height * angle
PY_ADD = angle

def decode_pixel(encoded):
    try:
        encoded = encoded.integer
        return (encoded & 0xFF0000) >> 16, (encoded & 0x00FF00) >> 8, (encoded & 0x0000FF)
    except:
        return (0, 0, 0)
    
def decode_screen_coord(x, y):
    px = x * PX_MUL + PX_ADD
    py = y * PY_MUL + PY_ADD
    return make_binary_vector([px, py, -1])

@cocotb.test()
async def test_check_objects(dut):
    """cocotb test?"""

    im_output = Image.new('RGB', (640, 360))

    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.aclk, 10, units="ns").start())
    await ClockCycles(dut.aclk, 3)
    dut.aresetn.value = 1
    await ClockCycles(dut.aclk, 1)
    dut.aresetn.value = 0
    dut.hcount_axis_tdata.value = 0
    dut.vcount_axis_tdata.value = 0
    dut.ray_axis_tdata.value = 0
    dut.sphere.value = 0
    dut.select_objs.value = 0
    dut.ray_axis_tvalid.value = 0
    dut.normal_axis_tready.value = 1
    dut.hit_point_axis_tready.value = 1
    dut.cylinders.value = 0
    await ClockCycles(dut.aclk, 5)
    dut.aresetn.value = 0
    dut.hcount_axis_tdata.value = 320
    dut.vcount_axis_tdata.value = 240
    dut.sphere.value = make_binary_vector([0.0, 0.0, 0.0, 0, -5, -5])
    dut.select_objs.value = 3
    dut.ray_axis_tvalid.value = 1
    dut.normal_axis_tready.value = 1
    dut.hit_point_axis_tready.value = 1
    cylinders = []
    for i in range(-22, -3, 2):
        # cylinders.extend([0, 1, 0, 0 if i == -4 else -20, -5, i])
        cylinders.extend([0, 1, 0, 0, -5, i])
    print(cylinders, len(cylinders))
    dut.cylinders.value = make_binary_vector(cylinders)

    # ray_223 = make_binary_vector([2.22044605e-16, -2.38888889e-01, -1.00000000e+00])
    ray_223 = decode_screen_coord(317, 223)

    # ray_224 = make_binary_vector([2.22044605e-16, -2.44444444e-01, -1.00000000e+00])
    ray_224 = decode_screen_coord(317, 224)

    # ray_240 = make_binary_vector([2.22044605e-16, -3.33333333e-01, -1.00000000e+00])
    rays = [ray_223, ray_224]
    counter = 0

    for _ in range(400):
        dut.ray_axis_tdata.value = rays[counter % 2]
        dut.hcount_axis_tdata.value = 320
        dut.vcount_axis_tdata.value = 223 if counter % 2 == 0 else 224
        if dut.ray_axis_tready:
            counter += 1
        await ClockCycles(dut.aclk, 1)


    # for y in range(320):
    #     print("Row", y)
    #     for x in range(640):
    #         dut.hcount_axis_tdata.value = x
    #         dut.hcount_axis_tvalid.value = 1
    #         dut.vcount_axis_tdata.value = y
    #         dut.vcount_axis_tvalid.value = 1
    #         if dut.pixel_axis_tvalid == 1:
    #             im_output.putpixel((dut.hcount_out.value.integer, dut.vcount_out.value.integer), decode_pixel(dut.pixel_axis_tdata.value))
    #         await ClockCycles(dut.aclk, 1)

def runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "check_objects.sv"] #grow/modify this as needed.
    sources.append(proj_path / "hdl" / "float_add.sv")
    sources.append(proj_path / "hdl" / "float_mul.sv")
    sources.append(proj_path / "hdl" / "float_div.sv")
    sources.append(proj_path / "hdl" / "float_sqrt.sv")
    sources.append(proj_path / "hdl" / "float_lt.sv")
    sources.append(proj_path / "hdl" / "float_min.sv")
    sources.append(proj_path / "hdl" / "axi_pipe.sv")
    sources.append(proj_path / "hdl" / "vec_add.sv")
    sources.append(proj_path / "hdl" / "vec_dot.sv")
    sources.append(proj_path / "hdl" / "quadratic.sv")
    sources.append(proj_path / "hdl" / "float_mul_pow2.sv")
    sources.append(proj_path / "hdl" / "float_fused_mul_add.sv")
    sources.append(proj_path / "hdl" / "float_sum3.sv")
    sources.append(proj_path / "hdl" / "vec_mul.sv")
    sources.append(proj_path / "hdl" / "vec_clamp.sv")
    sources.append(proj_path / "hdl" / "vec_to_pixel_color.sv")
    sources.append(proj_path / "hdl" / "float_to_fixed.sv")
    sources.append(proj_path / "hdl" / "fixed_to_float.sv")
    sources.append(proj_path / "hdl" / "float_clamp.sv")
    sources.append(proj_path / "hdl" / "vec_fused_mul_add.sv")
    sources.append(proj_path / "hdl" / "vec_norm.sv")
    sources.append(proj_path / "hdl" / "ray_intersect.sv")
    sources.append(proj_path / "hdl" / "ray_from_pixel.sv")
    sources.append(proj_path / "hdl" / "hit_point.sv")
    sources.append(proj_path / "hdl" / "lambert.sv")
    sources.append(proj_path / "hdl" / "float_argmin.sv")
    sources.append(proj_path / "hdl" / "float_multi_argmin.sv")
    sources.append(proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v")
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="check_objects",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="check_objects",
        test_module="test_check_objects",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    runner()

# 0000000000000000 0000000000000000 bff5183f99f3dc86 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 0000000000000000 bff693e93e478e5f 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 0000000000000000 4014000000000000

# 0000000000000000 4014000000000000 4014000000000000

# c019f8499af611f4 c00066eb1e807723 c02f014bcc4129da

# c019f8499af611f4 40079914e17f88dd c025014bcc4129da

# c019f8499af611f4 40079914e17f88dd c025014bcc4129da

# bfdf8499af611f40 0000000000000000 3fdfd68677dac4c0