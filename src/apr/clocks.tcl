# ==========================================================================
# CTS & CLOCK ROUTING
# ==========================================================================

# Get variable definitions
source ${SRC_DIR}/config.tcl
source ${SRC_DIR}/phys_vars.tcl
source ${SRC_DIR}/common_procs.tcl

# Make sure placement is good before CTS
check_legality -verbose

# Set options for compile_clock_tree (all are pretty much default, except the routing rule)
set_clock_tree_options \
   -layer_list_for_sinks $CLOCK_ROUTING_LAYERS \
   -layer_list $CLOCK_ROUTING_LAYERS \
   -use_leaf_routing_rule_for_sinks 0 \
   -max_transition 0.080 \
   -leaf_max_transition 0.080 \
   -use_leaf_max_transition_on_exceptions TRUE \
   -use_leaf_max_transition_on_macros TRUE \
   -max_capacitance 0.08 \
   -max_fanout 12 \
   -target_early_delay 0.000 \
   -target_skew 0.000 \
   -gate_sizing TRUE \
   -buffer_sizing TRUE 

#Block off metal layers from being routed
create_metal_blockage 6 10

############################################################################
# CLOCK GATING
############################################################################
# Balanced clock tree -> best clock tree timing results
# the setup recommendation before iserting the integrated cg cells
# Use a small maximum clock-gating fanout value
set_clock_gating_style \
    -sequential_cell latch \
    -control_point before \
    -control_signal scan_enable \
    -minimum_bitwidth 10 \
    -max_fanout 128 \
    -positive_edge_logic {integrated}

# set the power_cg_all_registers to true
set power_cg_all_registers true ; # insert always-enabled cg cells for ungated registers
set power_remove_redundant_clock_gates false  ; # prevent DC from optimizing away the cg cells that are used for balancing

# after placing, split_clock_net command to balance the clock tree fanout before cts
split_clock_net -objects i_clk -gate_sizing -gate_relocation -operating_condition min_max

set_optimize_pre_cts_power_options -low_power_placement true -merge_clock_gates true
set placer_disable_auto_bound_for_gated_clock true
optimize_pre_cts_power -operating_condition min_max -update_clock_latency -verbose
compile_clock_tree



#Run the clock synthesis step
set_fix_hold [all_clocks]
clock_opt

# Fix hold violations
#psynopt -only_hold_time

# Pre-route shielding
if {$SHIELD_CLOCK} {
create_zrt_shield \
   -mode new \
   -with_ground VSS \
   -preferred_direction_only true
}

# Check again in case hold fixing broke stuff
verify_zrt_route

