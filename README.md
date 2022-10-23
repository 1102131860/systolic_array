Project
============
In this project, you will implement and tapeout **CORDIC** (COordinate Rotation DIgital Computer) as a team. You will undrstand the CORDIC algorithm, model its behavior with high level programming language. Then, you will design it in RTL, and perform synthesis and APR. You are going to also verify the module in each intermediate stages are functional and meet the constraints. Evnetually, your CORDIC design will be taped out and you will test the chip and measure its performance and power.

**:date: Milestone 1 Due Date: 11/3 11:59pm (:warning:PLEASE START EARLY:warning:**)

## Objectives
1. Successfully tapeout CORDIC that meets the specifications
2. Understand CORDIC algorithm
3. Demonstrate your ability to implement a given algorithm in RTL with best-practices
4. Perform synthesis that meets the specifications
5. Perform auto place and route to generate a tapeout ready design
6. Construct a good verification flow to ensure a successful tapeout
7. Understand what files to provide for the final chip integration
8. Understand how your module is intergrated and interacts with the peripharals
9. Understand and perform several methods to test the chip
10. Observe how the chip performs and think about how each step of the flow affects the end result

## CORDIC Algorithm
CORDIC is a shift-and-add algorithm that can calculate trigonometric functions, hyperbolic functions, square roots and more. Due to its simplicity and efficiency, CORDIC is used in the navigation system of the Apollo program's Lunar Roving Vehicle, processors such as Intel 8087, and FPGAs. Please read the provided [slide](doc/CORDIC_slide.pdf) and [paper](doc/CORDIC_paper.pdf) to clearly unsdrstand the operations.

## Specifications
Here are the specifiacaitons of the CORDIC design you are implementing:

| Feature                             | Description                  |
|-------------------------------------|------------------------------|
| Number of micro-rotations           | 14                           |
| Scaling factor                      | Ignored                      |
| Modes supported                     | Rotation & Vectoring         |
| IO ports                            | [cordic_top.sv]              |
| Process node                        | TSMC 65GP                    |
| Power supply                        | 0.8 ~ 1 V                    |
| Minimum clock frequency             | 100 Mhz                      |

 ## Milestone 1 Deliverables
 Each team will submit one tar.gz through Canvas with filename _<team_x>.tar.gz_. The file should include below deliverables structured as the directories we have been following in tutorials.
 1. Script written in high level programing language that models the CORDIC behavior
 2. Synthesizable CORDIC RTL design
 3. Test framework used to verify your design
 4. Readme that clearly explains usages and how to run
