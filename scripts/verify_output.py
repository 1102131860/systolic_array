# ===================================================================================
# ECE4804 Project: Milestone 1a
# Weight-stationary systolic array-based matmul
# Andrey Li 10.3.2025
# ===================================================================================
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--mode', default='memory')
args = vars(parser.parse_args())
mode_arg = args['mode']

# set parameters
output_path = f"golden_log/{mode_arg}.log"
golden_path = "golden_outputs/GOLD_OUTPUTS.txt"
big_path = "logs/final_log.txt"
error_path = "logs/error.log"

# compare golden output log vs. output log
error_flag = 0  
try: # if verilog sim failed, can't open output_path. then print error log automatically
    with open(output_path, 'r') as output_file, open(golden_path, 'r') as golden_file, open(big_path, "a") as big_file:
        for line_num, (line1, line2) in enumerate(zip(output_file, golden_file), start=1):
            if mode_arg != 'memory': line1 = line1[8:]
            if line1.strip().replace('x', '0') != line2.strip(): # take XX as 00 in DUT output log
                print(f"❌ERROR❌: Difference at line {line_num}:")
                print(f"DUT output: {line1.strip()}")
                print(f"Golden output: {line2.strip()}")
                big_file.write(f"\n❌ERROR❌: Difference at line {line_num}:\n")
                big_file.write(f"DUT output: {line1.strip()}\n")
                big_file.write(f"Golden output: {line2.strip()}\n\n")
                error_flag = 1
                with open(error_path, "a") as file:
                    file.write("Error found! Tests not passed.\n")
                    file.write(f"DUT output: {line1.strip()}\n")
                    file.write(f"Golden output: {line2.strip()}\n")

    if (error_flag == 0):
        with open(output_path, 'r') as output_file, open(big_path, "a") as big_file:
            big_file.write("\nDUT Outputs:\n")
            for line in output_file:
                big_file.write(line.strip() + "\n")
            big_file.write("\nNo mismatches. PASSED! ✅✅✅\n\n")
            print("\nNo mismatches. PASSED! ✅✅✅")

except:
    with open(error_path, "a") as file:
        file.write("❌❌❌❌ ERROR: verilog simulation failed.\n")
