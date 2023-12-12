WORLD_BITS = 18

num_hex_digits = ((WORLD_BITS * 2 - 1) // 4 + 1)

def decimal_to_hex(decimal_str):
    decimal_list = decimal_str.split()
    bin_vals = [bin(int(num))[2:] for num in decimal_list]
    bin_vals_with_padding = ['0' * (WORLD_BITS - len(bin_vals[i])) + bin_vals[i] for i in range(len(bin_vals))]
    concatenated_bin_vals = [bin_vals_with_padding[i] + bin_vals_with_padding[i + 1] for i in range(0, len(bin_vals_with_padding), 2)]
    hex_vals = [hex(int(bin_val, 2))[2:] for bin_val in concatenated_bin_vals]
    padded_hex_vals = ['0' * (num_hex_digits - len(hex_val)) + hex_val for hex_val in hex_vals]
    return '\n'.join(padded_hex_vals)

# File names
input_file = 'level.txt'
output_file = 'level.mem'

try:
    with open(input_file, 'r') as file:
        # Read decimal numbers from input file
        decimal_numbers = file.read().strip()

        # Convert decimal numbers to hexadecimal
        hex_numbers = decimal_to_hex(decimal_numbers)

        # Write hexadecimal numbers to output file
        with open(output_file, 'w') as output:
            output.write(hex_numbers)

    print(f"Conversion successful. Hexadecimal numbers written to '{output_file}'.")

except FileNotFoundError:
    print(f"Error: '{input_file}' not found.")
except Exception as e:
    print(f"An error occurred: {e}")
