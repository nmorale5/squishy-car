WORLD_BITS = 32

num_hex_digits = ((WORLD_BITS - 1) // 4 + 1)

def decimal_to_hex(decimal_str):
    decimal_list = decimal_str.split()
    each_val = [hex(int(num))[2:].upper() for num in decimal_list]
    each_val_with_padding = ['0' * (num_hex_digits - len(each_val[i])) + each_val[i] for i in range(len(each_val))]
    each_line = [each_val_with_padding[i] + each_val_with_padding[i + 1] for i in range(0, len(each_val_with_padding), 2)]
    return '\n'.join(each_line)

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
