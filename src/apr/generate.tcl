# |=======================================================================
# |  
# | Created by         :PSyLab                                           
# | Filename           :generate.tcl                                  
# | Author             :sathe(Ga Tech.)                              
# | Created On         :2022-09-22 17:08                   
# | Last Modified      :                                                 
# | Update Count       :2022-09-22 17:08                   
# | Description        :                                                 
# |                                                                      
# |                                                                      
# |=======================================================================


#TODO ITEMS
#1: sathe to get the GP libraries compiled.

# This is the MW design library that will contain your design. Eventually the chip integrator
# will include your design library name and path into his/her target and link libraries so it can be used 
# to instantiate your module as a macro at the top level

# ==========================================================================
# GENERATE DESIGN FILES
# ==========================================================================

# These naming rules provide some guidelines to the tool on how to produce verilog output for eventual
# tapeout. In this case, this rule is insisting that only lower-case letters be used for naming. Don't comment
# these rules out.
define_name_rules LOW_ONLY -type net -allow "a-z 0-9_"
change_names -rules LOW_ONLY -hierarchy -verbose

#  SPEF
extract_rc
write_parasitics \
   -output ./$results/$design_name.apr.spef \
   -no_name_mapping

# LEF+DEF
write_def -lef ./$results/$design_name.lef \
          -output ./$results/$design_name.def \
          -all_vias

# Verilog
write_verilog ./$results/$design_name.no_pg.apr.v \
    -unconnected_ports \
    -no_core_filler_cells \
    -diode_ports \
    -supply_statement "none"

write_verilog ./$results/$design_name.apr.v \
    -pg \
    -unconnected_ports \
    -no_core_filler_cells \
    -diode_ports \
    -supply_statement "none"

# SDF
write_sdf -context verilog ./$results/$design_name.apr.sdf

# SDC
write_sdc -nosplit $results/$design_name.apr.sdc

#Investigate the need to do this...commenting for now
# foreach powerNet [list VDD VSS] {
# create_port -direction inout $powerNet
# connect_net $powerNet [get_ports $powerNet] 
# }

#This command is needed to convert power wire shapes into pins so that they can be identified as connection 
#targets at the higher level during module assembly. The idea is to run power/groun over this module at a higher
#level of metal and make the connection to it: OTM. If there's no pin shape, this wire will be registered as an obstruciton
#in the FRAM and be invisible as a target at the higher level.
change_selection [get_net_shapes -filter \
"(net_type == Ground || net_type == Power) && route_type == \"P/G Strap\""]
convert_wire_to_pin [get_selection]

#Fram generation.. THIS METHOD NEEDS GOOD ALIGNMENT OF THE TRACK TO THE CENTER OF THE POWER PIN!!!!!!
#FRAM generation creates an abstract view of your macro for use at the higher level.
# change_selection [get_net_shapes -filter \
#   "(net_type == Ground || net_type == Power) && (route_type == \"P/G Strap\" || route_type == \"P/G Ring\")"]
# foreach_in_collection shape [get_selection] {
#     set bbox [get_attribute $shape bbox]
#     set layer [get_attribute $shape layer]
#     set owner_net [get_attribute $shape owner_net]
#     create_terminal -bbox $bbox -layer $layer -port $owner_net
# }
#  convert_wire_to_pin [get_selection]
  create_macro_fram -extract_blockage_by_block_core_with_margin {M8 -1 M9 -1}



# GENERATE REPORTS
# ==========================================================================

# Timing
check_timing > "./$reports/check_timing.rpt"
report_constraints -all_violators -verbose -nosplit > "./$reports/constraints.rpt"
report_timing -path end   -derate -delay max -max_paths 200 -nosplit > "./$reports/paths.max.rpt"
report_timing -path full  -derate -delay max -max_paths 50  -nosplit > "./$reports/full_paths.max.rpt";
report_timing -path end   -derate -delay min -max_paths 200 -nosplit > "./$reports/paths.min.rpt";
report_timing -path full  -derate -delay min -max_paths 50  -nosplit > "./$reports/full_paths.min.rpt";

# Area
report_area -physical -hier -nosplit > "./$reports/area.rpt"

# Power and backannotation
report_power -verbose -hier -nosplit > "./$reports/power.hier.rpt"
report_power -verbose -nosplit > "./$reports/power.rpt"
report_saif -hier > "./$reports/saif_anno.rpt"
report_saif -missing >> "./$reports/saif_anno.rpt"

# Floorplanning and placement
report_fp_placement > "./$reports/placement.rpt"

# Clocking
report_clock_tree -nosplit > "./$reports/clocktree.rpt"

# QoR
report_qor -nosplit > "./$reports/qor.rpt"

