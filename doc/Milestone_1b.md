# Milestone 1-b: Individual RTL

For this milestone you will be designing and implementing a 3x3 Weight Stationary Systolic-based Matrix Multiplication Unit. This is meant to be a simplified version of your final design.

**Before you proceed** switch to the milestone_1b branch if you haven't already:
```bash
git checkout milestone_1b
```

## Simplified Specifications
| Feature                             | Description                      |
|-------------------------------------|----------------------------------|
| Number of rows                      | 3 (Programable by Designer)      |
| Number of columns                   | 3 (Programable by Designer)      |
| Input data assumptions              | Data is stored on global memories |
| Input data format                   | Signed Integer (2's Complement)  |
| Input data width                    | 8 bits                           |
| Output data width                   | 8 bits                           |
| Handling data overflow              | Saturation                       |
| Modes supported                     | Only Memory                      |
| IO ports                            | See [matrix_mult.sv](../src/verilog/matrix_mult/matrix_mult.sv)|
| Reset                               | Active-Low Reset (Reset when 0)  |

**Additional simplifying assumptions (For Milestone 1-b ONLY)**:
1. Systolic array dimensions: 3x3
2. You **DO NOT** need the matrix_mult_wrapper for milestone 1-b
3. You can assume that the data will start at address 0x00 at each corresponding memory (input, weight, output)
4. You **ONLY** need to support input matrices that are: input [3x3], and weight [3x3], where: [#rows x #cols]. Note that this results in an output [3x3] matrix.
    1. Tiling is NOT needed (you can ignore partial sums)
    2. Input streaming dimension is FIXED (#rows in input activation matrix is fixed)
5. Only one pair of input matrices will be loaded onto the memory for each test. The design is restarted and memory is re-loaded before the following test.
    1. This is the reason why the provided [testbench](../src/verilog/tb_matrix_mult.sv) contains memory instances with fixed dimensions that exactly match the input, weight, and output matrices dimensions (including staggering). Go over them and try to understand why those are the given dimensions. **You do not need to modify the provided memory sizes**.
    2. The expected bahavior is described in the section below. Please make sure your design's output **matches 1-to-1** the expected output.

**Matrices & Memory Description**
The given memory will be expected to have the following dimensions and matrix values will be loaded as shown. The output activation memory shows the expected output.
<p align="center">
<img src="../img/ms_1b/matrix_mem_dim.png" alt="" width="600"/>
</p>

*Notice that X denotes a don't care. Will be set to 0.*

**Testbench Overview**
The provided testbench is representative of the testbench that will be used to grade your designs. However, you **MUST** fully verify your RTL. The provided tasks will NOT suffice. Please refer to Tutorial 1 for verification basics.
<p align="center">
<img src="../img/ms_1b/tb_diagram.png" alt="" width="600"/>
</p>

## Expected Behavior of your Matrix Mult Unit
For this assignment, your module **MUST** behave as follows:
<p align="center">
<img src="../img/ms_1b/behav_waveform.png" alt="" width="600"/>
</p>

*Note: The states provided above are illustrative. Your design can (and probably should) use different states.*

1. After reset, input and weight memories are loaded (using $readmem[b/h]) with the corresponding staggering as shown in the specifications section
2. start_i is pulsed high for 1 cycle
3. Your design begins the computation of the loaded matrices
4. After it is done, the done_o signal must be pulled high (by your design), indicating that output memory contains the final computed matrix

You are free to extend the functionality of your design as long as it still meets the expected behavior specified in this section.

## Hints & Tips
1. Try to really understand how the Weight Stationary Dataflow works. It is very helpful to list down every single multiply-accumulate computation and find how data "moves" across your 2D pipeline.
2. Make your design parameterizable! It will boost productivity in the long run, especially if you need to make changes to your design for future milestones.
3. Verification will easily consume 60-70% of your total time. Start verifying your design early and plan accordingly!
4. During grading the TA will check the resulting data on the output buffer memory. Make sure this matches with the provided expected output. If it doesn't match you will fail the testcase.

Here's a sample diagram of how the Matrix Multiplication Unit should look like. This is just a sugestion and you are free to implement it however you wish.
<p align="center">
<img src="../img/ms_1b/dut_diagram.png" alt="" width="300"/>
</p>