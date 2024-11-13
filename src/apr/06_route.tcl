# 6. route
set step      "06_route"

set_scenario_status [all_scenarios] -active false
set_scenario_status func1_wc -active true
set_scenario_status func1_bc -active true

set_max_transition 0.55 -scenarios func1_wc [current_design]
set_max_transition 0.45 -scenarios func1_bc [current_design]

# route options
set_app_options -name route.global.timing_driven -value true
set_app_options -name route.track.timing_driven -value true
set_app_options -name route.detail.timing_driven -value true
set_app_options -name opt.common.user_instance_name_prefix -value "RO_"

source $ANTENNA_RULES_FILE ; # route.detail.antenna as true, hopping layer instead of inserting diode
set_app_options -name route.detail.antenna -value true ;
report_antenna_rules

# Route - critical command
set cmd "route_auto -max_detail_route_iterations $ITER"
eval $cmd

#verify that antenna rules haven't been violated
check_routes -antenna true

# Fix any constraints violated by routing
route_opt

# DRC violation search
check_route

check_routes -antenna true

#detail routing
route_detail -incremental true -initial_drc_from_input true

# Connect pg net to added cells
connect_pg_net -automatic

puts "**INFO: check pg connection"
check_pg_connectivity

# runnig extraction and upating the timing
update_timing
