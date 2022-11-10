Project Description
====================
You will implement and tapeout a **CORDIC** (COordinate Rotation DIgital Computer) in pre-assigned teams. This will involve (1) understanding the CORDIC algorithm and  modelling its behavior using a high level programming language; (2) Describing your design in RTL; and (3) perform synthesis and APR on your design. You will verify that the module is functional, and meets target specifications at each intermediate stage of the process. Eventually, your CORDIC design will be taped out and you will test the chip, and characterize its performance and power.

**:date: Milestone 1 Due Date: 11/3 11:59pm (:warning:PLEASE START EARLY:warning:)**

## Objectives
1.1.1 Understand CORDIC algorithm. Properly.

1.1.2 Demonstrate your ability to implement a given algorithm in RTL using the best-practices learned in this class

1.1.3. Construct a good verification flow to ensure a successful tapeout

1.2.1. Add input source and output select logic for your module, including LFSR and BIST function.

1.2.2. Perform synthesis to meet provided functional specifications

1.2.3. Perform auto place and route to generate a tapeout ready design

1.2.4. Construct a good verification flow to validate your post-apr design.

1.2.5. Understand what files to provide for the final chip integration. Deliver the FRAM view of your design.

1.3.1. Understand how your module is intergrated and interacts with the peripharals

1.3.2. Understand and perform several methods to test the chip

1.3.3. Observe how the chip performs and think about how each step of the flow affects the end result

1.3.4. Successfully tapeout a CORDIC that meets target specifications

This section of the project will focus on understanding and writing 


## CORDIC Algorithm
CORDIC is a shift-and-add algorithm that can calculate trigonometric functions, hyperbolic functions, square roots and more. Due to its simplicity and efficiency, CORDIC was used in the navigation system of the Apollo program's Lunar Roving Vehicle, processors such as Intel 8087, and FPGAs. Please read the provided [slide](doc/CORDIC_slide.pdf) and [paper](doc/CORDIC_paper.pdf) to clearly unsdrstand the operations. By now you would have appreciated the value of building a firm foundation upon which to mount your effort. Doing otherwise typically takes up even more time, and leads to poor quality.

## Specifications
Here are the specifiacaitons of the CORDIC design you are implementing:

| Feature                             | Description                      |
|-------------------------------------|----------------------------------|
| Number of micro-rotations           | 12 (make it user-programmable)   |
| Number of pipline stages            | Designer to decide               |
| Input data timing assumptions       | Data can appear every cycle      |
| Input data format                   | Two's complement                 |
| Input data width                    | 16 bits (1 sign, 2 int, 13 frac) |
| Output data width                   | 18 bits (1 sign, 4 int, 13 frac) :bangbang:|
| Scaling factor                      | Compensate the scaling           :bangbang:|
| Coordinates supported               | Circular                         |
| Modes supported                     | Rotation & Vectoring             |
| IO ports                            | [cordic_top.sv](src/verilog/cordic_top.sv)|
| Process node                        | TSMC 65GP                        |
| Timing model                        | NLDM                             |
| Power supply                        | 0.8 ~ 1 V                        |
| Target corner                       | TT                               |
| Minimum clock frequency             | 100 Mhz                          |
| Highest metal allowed               | M5                               |

Shown below is the input and expected output pattern. Input data along with ucr carrying operation code are fed to your CORDIC module for one cycle with enable bit. After processing, the output result is presented with done signal indicating the completion for one cycle.
<p align="center">
<img src="./img/behavior.png" alt="" width="700"/>
</p>


Explore use of _genvar_ to build a customizable number of stages.
**The header verilog file for the design has been provided**

## CORDIC Wrapper
The CORDIC wrapper includes 3 main blocks: driver, monitor and your cordic. In driver mode 0, driver flops the incoming test patteren, and sends it out to CORDIC in the next cycle. In driver mode 1, LFSR inside the driver generates the test patterens and feed it to CORDIC. Monitor in mode 0 flops the CORDIC output and pops it out the next cycle to external modules. In monitor mode 1, the signature analyzer inside the monotor collects the CORDIC ouputs and compresses those until it receives the stop signal, and one ouput will be sent out from the monitor. The valid and data input ports are also used to set the seed of LFSR and SA when in driver mode 1 or monitor mode 1. Send the seed through data port with one cycle of valid in the beginning of your test sequence if you are using LFSR or SA. LFSR stops when the generated pattern matches the stop pattern from the stop code input port. Please start by running the simulation with the provided sequence in task.sv, alter the modes and see how driver and monitor behave when CORDIC is bypassed. Other than the 3 main modules, there's a reset synchronizer in the wrapper that makes sure the reset is in sync with the clock wrapper receives.

| Driver Mode | Description      |
|-------------|------------------|
| 0           | External Input   |
| 1           | LSFR             |

| Monitor Mode| Description      |
|-------------|------------------|
| 0           | Direct Output    |
| 1           | Signature Analyzer  |

<p align="center">
<img src="./img/cordic_wrapper.png" alt="" width="700"/>
</p>


## Milestone timeline
| Milestone | Date            | Item                                                 |
|-----------|-----------------|------------------------------------------------------|
| 1         | ~~11/3~~  11/4  | Verilog block-level complete & regression flow       |
| 2         | ~~11/10~~ 11/15 | Integration with wrapper, SAPR complete, FRAM export |
| 3         | ~~11/17~~ 11/22 | Chip-level Validation, Final SAPR Delivery           |

## Milestone 1 Deliverables
Each team will submit one tar.gz through Canvas with filename _<team_x>.tar.gz_. The file should include below deliverables structured as the directories we have been following in tutorials.
 1. Script written in high level programing language that models the CORDIC behavior. We have specified the format of the [input data file](scripts/cordic_input.txt).
 3. Synthesizable CORDIC RTL design
 4. Test framework used to verify your design
 5. Readme that clearly explains the organization of your design and how to run both high level simulation and verilog.


## Team common directories on ECE Linux Machine
You only have the permission to write to files taht are in your group. Please `cd` the full path directly to access. 
``` bash
/tools/projects/ece4804/group01
/tools/projects/ece4804/group02
/tools/projects/ece4804/group03
/tools/projects/ece4804/group04
```
**:muscle: Collaboration is highly encouraged. However, NO COPYING:x:**
