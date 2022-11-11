
# PLACEMENT OPTIMIZATION
# ================================

# Get variable definitions
source ${SRC_DIR}/config.tcl
source ${SRC_DIR}/phys_vars.tcl

# some helpers
set CORE_BBOX [join [get_core_bbox]]
set CORE_LLX  [lindex $CORE_BBOX 0]
set CORE_LLY  [lindex $CORE_BBOX 1]
set CORE_URX  [lindex $CORE_BBOX 2]
set CORE_URY  [lindex $CORE_BBOX 3]

# Optimize with the effort listed in config.tcl
set place_opt_args "-effort $PLACE_OPT_EFFORT -congestion"
set_app_var placer_congestion_effort medium
set_app_var placer_show_zroutegr_output true



#Identify clock gating and merge any clock gates first
#This performs a blanket merging of the gates. Split can happen later.
#Review this approach at some point in time.
identify_clock_gating
merge_clock_gates


# Run initial placement, legalization, and high-effort placement all using "place_opt"
echo "place_opt $place_opt_args"
eval "place_opt $place_opt_args"

# Insert standard cell fill cells to enable contiguous FEOL layers.
insert_stdcell_filler \
   -cell_with_metal {FILL8 FILL4 FILL2 FILL1} \
   -respect_keepout

# Connect all power and ground pins
derive_pg_connection -all -reconnect -create_ports all
verify_pg_nets

# Temporarily set interconnect delays to zero and check for constraint violations
# - if we can't even meet timing here, we probably need to re-floorplan...assuming
# meeting the timing target is a must :)
set_zero_interconnect_delay_mode true
report_constraint -all -nosplit >   "./$reports/constraint_zero_delay.rpt"
report_timing -delay max -nosplit > "./$reports/paths_zero_delay.max.rpt"
report_timing -delay min -nosplit > "./$reports/paths_zero_delay.min.rpt"
set_zero_interconnect_delay_mode false

