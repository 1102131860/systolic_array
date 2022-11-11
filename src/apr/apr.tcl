# |=======================================================================
# |  
# | Created by         :PSyLab                                           
# | Filename           :apr.tcl                                  
# | Author             :sathe(Ga Tech.)                              
# | Created On         :2022-09-23 11:22                   
# | Last Modified      :                                                 
# | Update Count       :2022-09-23 11:22                   
# | Description        :                                                 
# |                                                                      
# |                                                                      
# |=======================================================================
# This script is the "master-script" which sources all the other .tcl files.
# The construction flow is in-line with the material covered in the lecture:
# Data/Library, synthesis netlist read-in:: floorplanning :: placement :: clock_tree
# routing :: chip_finishing :: data_preparation
# This spar script is what you will use to *** tape out your final design ****
# Some instructions:
# 1. Please go through it carefully, step by step. Hopefully for some of you, your experiences
#    with tutorial 1 and tutorial 2 will have convinced you of the value in doing this
# 2. Treat power.tcl as a black box. There's a lot of detail and other files hiding underneath that do
#    not offer sufficient value to you guys. Your time (IMO) is better spent focusing on other more 
#    important aspects of the design process.
# 3. This flow is not a "2-level" flow. This scripts will call other .tcl files, which will call
#    other .py, .tcl files. The only exception is the pinPlacement.txt file which is how you specify 
#    pin locations in your design.
#
set TOOL_NAME "ICC"
set SRC_DIR "."


# ==============================================================================================
# CONFIGURATION: Read in config.tcl file with paths to essential SAPR "collateral" and synthesis 
# netlist files. Collateral refers to all the technology, stdcell, macro (memory compilers, other 
# design blocks used in the design. The phys_vars.tcl file will contain a lot of variables that are 
# relevant to the physical geometry of the design. 
# # ==============================================================================================

# start timing the SAPR run
set start_time [clock seconds]; echo [clock format $start_time -gmt false]

remove_design -all

source ${SRC_DIR}/config.tcl -echo -verbose
source ${SRC_DIR}/phys_vars.tcl -echo -verbose

file mkdir $results
file mkdir $reports

source ${SRC_DIR}/library.tcl -echo -verbose

# READ IN THE SYNTHESIS NETLIST
# ==========================================================================
# Read in the verilog, uniquify and save the CEL view.
import_designs $design_name.syn.v -format verilog -top $design_name
link

# ===============================================================================================
# TIMING CONSTRAINTS 
# Source all the timing constraints that have been summarized by the .sdc file in synthesis. 
# In addition, create any path groups that you would like to and verify that you are able to do 
# timing analysis on the synthesized netlist.
# ===============================================================================================
source ${SRC_DIR}/constraints.tcl -echo
save_mw_cel -as ${design_name}_init

# ==================================================================================================
# FLOORPLAN CREATION: This floorplan does a number of tasks.
# 1. Establish the location of a physical "pin" on the boundary for each port in your design
# 2. Allow you to run floorplanning: There's 2 ways to do this
#    a. Rectangular modules (the most common shape, and the only one you'll use in this class) can use 
#    the core_utilization and aspect ratio method to first establish the approximate area that is needed.
#    b. Then, once you know approximately what the geometry of your module is (in the aspect ratio that you wanted
#    you can be more specific about the width and height of the module. REMEMBER, these geometries are not even
#    multiples of routing track pitch (0.2um) - they are multiples of SPG (super-pg tiles, see earlier discussion i
#    in phys_vars.tcl)
# ==================================================================================================
# Create core shape and pin placement
source ${SRC_DIR}/floorplan.tcl -echo

# ==========================================================================
# PHYSICAL POWER NETWORK
# Build a power network, rings and power mesh based on a power grid topology 
# defined by power template files (.tpl files). Note that we don't need you 
# to go through this one .tcl file to follow along each step of the way. 
# It is of limited value.
# ==========================================================================
save_mw_cel -as ${design_name}_prepns
source ${SRC_DIR}/power.tcl -echo

#Now is the time to go back and measure the geometries of the rings, space to 
#the core, space between rings, and space to the die-area to corroborate them 
#with what is written in the phys_vars.tcl file.


# ==========================================================================
# PLACEMENT OPTIMIZATION
# Place all logic and std-cells into the core area and place them based on
# power/timing/congestion based objectives.
# ==========================================================================
save_mw_cel -as ${design_name}_preplaceopt
source ${SRC_DIR}/placeopt.tcl -echo

# ==========================================================================
# CTS & CLOCK ROUTING
# Route the clock. We do not perform mesh-based or H-Tree based topologies in
# this course. We stick to the standard CTS-generated unstructured tree.
# ==========================================================================
save_mw_cel -as ${design_name}_preclock
source ${SRC_DIR}/clocks.tcl

# ==========================================================================
# SIGNAL ROUTING, AND HOLD FIXING!
# Connect up all the cells and perform hold fixing-insertion of user-configurable
# delay cells to alleviate hold violations.
# ==========================================================================
save_mw_cel -as ${design_name}_preroute
source ${SRC_DIR}/route.tcl -echo

# ==========================================================================
# FINAL FINISHING
# Add antenna diodes. Perform final checks for DRC/LVS replace fill with decap 
# ==========================================================================
save_mw_cel -as ${design_name}_prefinished
source ${SRC_DIR}/finishing.tcl -echo

# ==========================================================================
# GENERATE DESIGN FILES AND REPORTS
# ==========================================================================
save_mw_cel -as ${design_name}_finished
source ${SRC_DIR}/generate.tcl -echo
save_mw_cel -as ${design_name}


# ==========================================================================
# FINAL DRC CHECK
# ==========================================================================
# report_drc -highlight -color green
source ${SRC_DIR}/report_drc.tcl -echo

# ==========================================================================
# RUNTIME and MESSAGE SUMMARY
# ==========================================================================

print_message_info

set end_time [clock seconds]; echo [string toupper inform:] End time [clock format ${end_time} -gmt false]

# Total script wall clock run time
echo "[string toupper inform:] Time elapsed: [format %02d \
                     [expr ($end_time - $start_time)/86400]]d \
                    [clock format [expr ($end_time - $start_time)] \
                    -format %Hh%Mm%Ss -gmt true]"
