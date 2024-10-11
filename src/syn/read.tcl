##############################################################################
#                                                                            #
#                               READ DESIGN RTL                              #
#                                                                            #
##############################################################################

# Get configuration settings
source configuration.tcl

# Define the location that you keep your verilog files to ease path definition
set BASE "$PROJECT_DIR/src/verilog"
set TOPLEVEL "$DESIGN"

# Set the verilog files that you would like to be read in
set RTL_SOURCE_FILES "\
$BASE/fsm_pkg.sv \
$BASE/fsm.sv \ 
"

set_svf ./$results/$TOPLEVEL.svf
define_design_lib WORK -path ./WORK
analyze -format sverilog $RTL_SOURCE_FILES
elaborate fsm 

link
current_design $TOPLEVEL
