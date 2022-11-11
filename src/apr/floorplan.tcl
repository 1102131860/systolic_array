
# Load variable definitions
source config.tcl -echo 
source phys_vars.tcl -echo
source common_procs.tcl -echo

# Create logical power and ground network (all nets/ports called VDD or VSS)
derive_pg_connection -power_net VDD -power_pin VDD\
                     -ground_net VSS -ground_pin VSS

# Connect tie-high and tie-low pins
derive_pg_connection -power_net VDD -ground_net VSS\
                     -tie \
                     -create_ports all

# The pin location syntax that icc likes is not very human readable. Editing that pin location file
# readily gives rise to errors. We wrote a quick script to be able to define pin locations using our 
# own syntax, which is also not as readable but once you get the hang of it, it's very efficient :).
exec python3.6 $SRC_DIR/genPinPlacement.py -t pin_placement.txt -o pin_placement.tcl
# Fix the pin metal layer change problem
set_fp_pin_constraints -hard_constraints {layer location} -block_level -use_physical_constraints on

#Open the pinPlacement.tcl file to see the format that the script expect. Offsets for icc are always
#bottom to top for E and W edges and left-to-right for N and S edges.
source pin_placement.tcl


# set the shape and size of the core. It's customary to start with a "loose" geometry to get a sense 
# of how much area your design takes up. This can be done by method 2: specifying aspect ratio and targeted core_utilization
# of the design at the time of floorplanning (remember that you need space for clock buffers and hold-fix buffers etc).
# Once you know the approximate geometry, you can then set the core_width and core_height of your design with method 1.
# Qn: Where are all these geometric variables defined?

#==== Method 1 =================================================================================
create_floorplan -control_type width_and_height \
                 -core_width  [expr $CORE_WIDTH_IN_SUPERTILES * $SUPERTILE_SIZE] \
                 -core_height [expr $CORE_HEIGHT_IN_SUPERTILES * $SUPERTILE_SIZE] \
                 -left_io2core $POWER_RING_CHANNEL_WIDTH \
                 -right_io2core $POWER_RING_CHANNEL_WIDTH \
                 -top_io2core $POWER_RING_CHANNEL_WIDTH \
                 -bottom_io2core $POWER_RING_CHANNEL_WIDTH 
#===============================================================================================

#==== Method 2 =================================================================================
# create_floorplan  -core_aspect_ratio 1.0 \
#                   -left_io2core $POWER_RING_CHANNEL_WIDTH \
#                   -right_io2core $POWER_RING_CHANNEL_WIDTH \
#                   -top_io2core $POWER_RING_CHANNEL_WIDTH \
#                   -bottom_io2core $POWER_RING_CHANNEL_WIDTH \
#                   -core_utilization 0.1
#===============================================================================================

# Power straps are not created on the very top and bottom edges of the core, so to 
# prevent cells (especially filler) from being placed there, later to create LVS 
# errors, remove all the rows and then re-add them with offsets 
cut_row -all
add_row \
   -within [get_attribute [get_core_area] bbox] \
   -top_offset $CELL_HEIGHT \
   -bottom_offset $CELL_HEIGHT

