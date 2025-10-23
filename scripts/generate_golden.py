# ===================================================================================
# ECE4804 Project: Milestone 1a
# Weight-stationary systolic array-based matmul
# Andrey Li 10.3.2025
# ===================================================================================
import numpy as np
import argparse

# parse arguments
parser = argparse.ArgumentParser()
parser.add_argument('--mode', default=0)
parser.add_argument('--in_bit', default=3)
parser.add_argument('--M', default=4)
parser.add_argument('--N', default=4)
parser.add_argument('--K', default=4)
parser.add_argument('--output_stat', default=0)
args = vars(parser.parse_args())
mode_arg = args['mode']
in_bit = int(args['in_bit'])
M = int(args['M'])
N = int(args['N'])
K = int(args['K'])
output_stat = int(args['output_stat'])

# set parameters
width = 8
col = N
i_size = M + K - 1
if output_stat:
    row = M
    o_size = N
    w_size = N + K - 1
else:
    row = K
    o_size = N + M - 1
    w_size = K
min_val = -1*2**(width-1)
max_val = 2**(width - 1) - 1
in_min_val = -1*2**(width - in_bit - 1)
in_max_val = 2**(width - in_bit - 1) - 1
input_path = "inputs/INPUTS.txt"
weight_path = "inputs/WEIGHTS.txt"
golden_path = "golden_outputs/GOLD_OUTPUTS.txt"
big_path = "logs/final_log.txt"

# generate random input and weight array to test systolic_model
with open(input_path, "a") as input_file, open(weight_path, "a") as weight_file, open(big_path, "a") as big_file:
    # generate random array
    if (mode_arg == "zero"):
        inputs = np.zeros((M, K), dtype=int)
        weights = np.zeros((K, N), dtype=int)
    elif (mode_arg == "full"):
        inputs = np.random.choice([min_val, max_val], (M, K))
        weights = np.random.choice([min_val, max_val], (K, N))
    else:
        inputs = np.random.randint(in_min_val, in_max_val, (M, K))
        weights = np.random.randint(in_min_val, in_max_val, (K, N))
    
    if output_stat:
        inputs_mem = np.zeros((i_size, M), dtype=int)
        inputs_T = inputs.T
        for i in range(K):
            for j in range(M):
                inputs_mem[i + j, j] = inputs_T[i, j]
        inputs_mem = np.array([row[::-1] for row in inputs_mem])
    else:
        inputs_mem = np.zeros((i_size, row), dtype=int)
        for i in range(M):
            for j in range(K):
                inputs_mem[i + j, j] = inputs[i, j]
        inputs_mem = np.array([row[::-1] for row in inputs_mem])

    print("Generating inputs...")
    print("Inputs:")
    print(inputs)
    print("\nInput Memory:")
    print(inputs_mem)

    # print input & weights files
    big_file.write('Inputs\n')
    for line in inputs_mem:
        input_file.write(''.join(f'{x & 0xFF:02x}' for x in line) + "\n")
    for line in inputs:
        big_file.write(' '.join(map(str, line)) + "\n")

    big_file.write('\nWeights\n')
    for line in weights:
        big_file.write(' '.join(map(str, line)) + "\n")
    
    if output_stat:
        weight_mem = np.zeros((w_size, N), dtype=int)
        for i in range(K):
            for j in range(N):
                weight_mem[i + j, j] = weights[i, j]
        weight_mem = np.array([row[::-1] for row in weight_mem])
    else:
        reversed_weights = weights[::-1]
        weight_mem = np.array([row[::-1] for row in reversed_weights])
    for line in weight_mem:
        weight_file.write(''.join(f'{x & 0xFF:02x}' for x in line) + "\n")
    print("\nGenerating weights...")
    print("Weights:")
    print(weights)
    print("\nWeight Memory:")
    print(weight_mem)

with open(golden_path, "a") as golden_file, open(big_path, "a") as big_file:
    # compute & print golden output log
    golden_output = np.zeros((M, N))
    for i in range(M):             # iterate over rows of A
        for j in range(N):         # iterate over columns of B
            for k in range(K):     # iterate over rows of B (or columns of A)
                partial_sum = np.clip(inputs[i][k] * weights[k][j], min_val, max_val)
                golden_output[i][j] += partial_sum
                golden_output[i][j] = np.clip(golden_output[i][j], min_val, max_val)
    golden_output = golden_output.astype(int)

    if output_stat:
        reversed_golden = golden_output[::-1]
        golden_mem = np.array([row[::-1] for row in reversed_golden])
    else:
        golden_mem = np.zeros((o_size, N), dtype=int)
        for i in range(M):
            for j in range(N):
                golden_mem[i + j, j] = golden_output[i, j]
        golden_mem = np.array([row[::-1] for row in golden_mem])

    big_file.write('\nGolden Outputs:\n')
    for line in golden_output:
        big_file.write(' '.join(map(str, line)) + "\n")

    big_file.write('\nGolden Outputs in Memory:\n')
    for line in golden_mem:
        big_file.write(''.join(f'{x & 0xFF:02x}' for x in line) + "\n")
        golden_file.write(''.join(f'{x & 0xFF:02x}' for x in line) + "\n")
    print("\nGenerating golden output...")
    print("Golden Output:")
    print(golden_output)
    print("\nGolden output Memory:")
    print(golden_mem)
    

