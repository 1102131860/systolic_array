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
$BASE/cordic_wrapper_pkg.sv \
$BASE/pseudo_rand_num_gen_pkg.sv \
$BASE/async_reset.sv \
$BASE/lfsr.sv \
$BASE/misr.sv \
$BASE/pseudo_rand_num_gen.sv \
$BASE/signature_analyzer.sv \
$BASE/cordic_top_<group_num>.sv \
$BASE/cordic_wrapper_<group_num>.sv \
"

set_svf ./$results/$TOPLEVEL.svf
define_design_lib WORK -path ./WORK
analyze -format sverilog $RTL_SOURCE_FILES
elaborate fsm 

link
current_design $TOPLEVEL
