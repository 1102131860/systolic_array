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
$BASE/matrix_mult/matrix_mult_pkg.sv \
$BASE/bist/pseudo_rand_num_gen_pkg.sv \
$BASE/misc/async_nreset_synchronizer.sv \
$BASE/bist/lfsr.sv \
$BASE/bist/misr.sv \
$BASE/bist/pseudo_rand_num_gen.sv \
$BASE/bist/signature_analyzer.sv \
$BASE/matrix_mult/processing_element.sv \
$BASE/matrix_mult/systolic_array.sv \
$BASE/matrix_mult/controller.sv \
$BASE/matrix_mult/matrix_mult.sv \
$BASE/matrix_mult/matrix_mult_wrapper.sv \
"

set_svf ./$results/$TOPLEVEL.svf
define_design_lib WORK -path ./WORK
analyze -format sverilog $RTL_SOURCE_FILES
elaborate $TOPLEVEL

link
current_design $TOPLEVEL
