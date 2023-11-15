# |=======================================================================
# |  
# | Created by         :PSyLab                                           
# | Filename           :config.tcl                                  
# | Author             :sathe(Ga Tech.)                              
# | Created On         :2022-09-23 09:55                   
# | Last Modified      :                                                 
# | Update Count       :2022-09-23 09:55                   
# | Description        :                                                 
# |                                                                      
# |                                                                      
# |=======================================================================

# ==========================================================================
# Project design and directories
# ==========================================================================

set PROCESS "65GP"; # Unused by tech_node.tcl 
set CORNER "LOW"
set TOPLEVEL "cordic_wrapper"
source -echo -verbose ./tech_node_config.tcl

  
# ICC runtime 
# ==========================================================================

if {$TOOL_NAME == "ICC"} {
    set_fast_mode "false" ;           # Forces place_opt/route_opt to run with low effort
    set_host_options -max_cores 4;
}

# Silence the unholy number of warnings that are known to be harmless
suppress_message "DPI-025"
suppress_message "PSYN-485"

# Library setup
# ==========================================================================
set design_name ${TOPLEVEL}

set DESIGN_MW_LIB_NAME "${TOPLEVEL}_lib"
set TECH2ITF_MAP_FILE "star.map_9M"
set MW_TECHFILE "tsmcn65_9lmT2.tf"

set MW_ADDITIONAL_REFERENCE_LIBS {}
set ADDITIONAL_TARGET_LIBS {}
set ADDITIONAL_SYMBOL_LIBS {}

# nand2 gate name for area size calculation
set NAND2_NAME    "ND2D1"

if {$TOOL_NAME == "PTPX"} {
    return
}
# POWER NETWORK CONFIG - EXAMINING THE POWER GRID SETUP IS NOT NECESSARY!!
# ==========================================================================
# - The script expects cordic_wrapper_rings.tpl to be in the run directory
# - This template file contains the template for core ring generation.
# - It is sourced at the time of power planning.
# - The ring file contains the template that describes the  
set RING_FILE "rings.tpl"
set RING_VSS_NAME "core_ring_vss"
set RING_VDD_NAME "core_ring_vdd"
set MESH_FILE "mesh.tpl"
set LOWER_MESH_NAME "core_lower_mesh"
set UPPER_MESH_NAME "core_upper_mesh"
set CUSTOM_POWER_PLAN_SCRIPT "macro_power.tcl"

# FUNCTIONAL CONFIG
# ==========================================================================


# Power and ground net names 
set POWER_NET  "VDD"
set GROUND_NET "VSS"
set LIB_POWER_PIN "VDD"
set LIB_GROUND_PIN "VSS"


# Placement options
set LOW_POWER_PLACEMENT 0
set PLACE_OPT_EFFORT "high"
set TWO_PASS_PLACEOPT 0

# Pinplacement
set PINPLACEMENT_TXT "${SRC_DIR}/pin_placement.txt"
set PINPLACEMENT_TCL "${SRC_DIR}/pin_placement.tcl"

# ==========================================================================
# Routing metal configurations
# ==========================================================================
# As mentioned in the lecture, we set even level metals to be horizontal
# Odder metals are designated a vertical direction.
# Set Min/Max Routing Layers and routing directions
set MAX_ROUTING_LAYER "M7"
set MIN_ROUTING_LAYER "M1"
set HORIZONTAL_ROUTING_LAYERS "M2 M4 M6 M8"
set VERTICAL_ROUTING_LAYERS "M3 M5 M7 M9"


#It's necessary to run this command only after the top level design (top cell) has been defined
#To avoid throwing unnecessary errors, these statements are encased in an if clause to check that the
#current design has been defined. This clause won't be exercised in the initial calls to this config.tcl file
#but it will in subsequent ones. Statements at the end insist that route go no higher than max_routing_layer
#and stay above min-routing layer. The last command penalizes wrong way route by adding a cost multiplier to routes in
#"nonpreferred directions you just set up"
if {$TOOL_NAME != "PTPX"} {
    if {[current_design_name] != ""} {
	    set_preferred_routing_direction \
	    -layers $HORIZONTAL_ROUTING_LAYERS \
	    -direction horizontal

	    set_preferred_routing_direction \
	    -layers $VERTICAL_ROUTING_LAYERS \
	    -direction vertical
	    if { $MAX_ROUTING_LAYER != ""} {set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER}
        if { $MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER}
        for { set i 2 } { $i <= 9 } { incr i } {
            set metal [format "M%d"  $i]
            set_route_zrt_common_options -extra_nonpreferred_direction_wire_cost_multiplier_by_layer_name [list [list $metal 2]]
        }
    }
}

# Zroute and the common router do not respect macro blockage layers by default. 
#  force matters using the set_route_zrt_common options. A very handy command for several other "tweaks".
if {$TOOL_NAME == "ICC"} {
   set_route_zrt_common_options -global_max_layer_mode hard
   set_route_zrt_common_options \
       -read_user_metal_blockage_layer "true" \
       -wide_macro_pin_as_fat_wire "true"
}


# ==========================================================================
# Clock network and synthesis related configurations
# ==========================================================================
# Min/Max routing layers for the clock
set CLOCK_ROUTING_LAYERS {M1 M2 M3 M4 M5}

# Names of the clocks/clock trees in the design
set CLOCKS "i_clk"

# Shield the clock nets
set SHIELD_CLOCK 0

# Any critical nets to route before general signal routing
# All nets are equal but some nets are more equal than others :)
set CRITICAL_NETS ""

# Build a buffer tree for the reset signal (should be mutually exclusive with CRITICAL_NETS)
# Notice! The buffer tree net names list here identifies i_rst as a tree to have buffer 
# insertion done for. This net was listed as an ideal_network in synthesis.
set BUILD_BUFFER_TREES 1
set BUFFER_TREE_NET_NAMES [list \
    "i_async_rst" \
    "sync_rst" \
] 

# Routing optimization effort
set ROUTE_OPT_EFFORT "high"
set MAX_DETAIL_ROUTE_ITER 40 ; # Default is 40

# Diode insertion for antenna violations, and ESD
set FIX_ANTENNA 1
set USE_ANTENNA_DIODES 1
set PORT_PROTECTION_DIODE ""
set PORT_PROTECTION_DIODE_EXCLUDE_PORTS ""
set ROUTING_DIODES "ANTENNA"

# Replace fill cells with decap at the end 
set FINISH_WITH_DECAP 1
set DECAP_CELLS {DCAP16 DCAP8 DCAP4 DCAP}
set FILL_CELLS {FILL8 FILL4 FILL2 FILL1}

# ==========================================================================
# RESULT GENERATION AND REPORTING
# ==========================================================================
set reports "reports" ; # Directory for reports
set results "results" ; # For generated design files

# MISC
# ==========================================================================
# - Useful for iterating on specific segments of the flow
if {$TOOL_NAME == "ICC"} {
    alias open_init   "close_mw_cel;open_mw_cel ${design_name}_init"
    alias open_fplan  "close_mw_cel;open_mw_cel ${design_name}_fplan"
    alias open_pgrid  "close_mw_cel;open_mw_cel ${design_name}_pgrid"
    alias open_placed "close_mw_cel;open_mw_cel ${design_name}_placed"
    alias open_clocked "close_mw_cel;open_mw_cel ${design_name}_clocked"
    alias open_routed "close_mw_cel;open_mw_cel ${design_name}_routed"
    alias open_finished "close_mw_cel;open_mw_cel ${design_name}_finished"

}

# source common tcl functions
# ==========================================================================
source ${SRC_DIR}/create_metal_blockage.tcl
source ${SRC_DIR}/create_via_blockage.tcl
