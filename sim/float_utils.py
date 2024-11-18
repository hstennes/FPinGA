import struct

def float_to_binary(f):
    # Pack the float into 8 bytes (double-precision) and unpack as an integer
    binary_as_int = struct.unpack('>Q', struct.pack('>d', f))[0]
    return binary_as_int

def binary_to_float(binary_as_int):
    # Pack the integer into 8 bytes and unpack as a double-precision float
    float_value = struct.unpack('>d', struct.pack('>Q', binary_as_int))[0]
    return float_value

def concat_binary(vals, bit_width=64):
    result = 0
    for val in vals:
        result = (result << bit_width) | val
    return result

# Example usage
# float_number = 1.5
# binary_as_int = float_to_binary(float_number)
# print(f"Float: {float_number}")
# print(f"Binary as int: {binary_as_int}")

# print("convert back to float: ", binary_to_float(binary_as_int))


binary = float_to_binary(1.5)
binary += 0x002_0000000000000
print(binary_to_float(binary))