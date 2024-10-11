set_host_options -max_cores 4
set_app_options -name plan.pgroute.disable_floating_removal -value true
set_app_options -name plan.pgroute.via_site_threshold -value 1.0
set_app_options -name plan.pgroute.maximize_total_cut_area -value all
set_app_options -name plan.pgroute.fix_via_drc_multiple_viadef -value true
set_app_options -name plan.pgroute.treat_fixed_stdcell_as_macro -value true
set_app_options -name plan.pgroute.patch_via_enclosure -value false
set_app_options -name plan.pgroute.realign_straps_for_cell_gap -value true

set_pg_strategy_via_rule NO_VIA  -via_rule { {{intersection: undefined}{via_master: NIL}} }

set_app_options -name plan.pgroute.patch_via_enclosure -value false
set_app_options -name plan.pgroute.treat_fixed_stdcell_as_macro -value false

create_pg_std_cell_conn_pattern PG_M1_M2_RAIL_M1_PTRN \
    -rail_width $M1_RAIL_WIDTH \
    -layers M1
create_pg_std_cell_conn_pattern PG_M1_M2_RAIL_M2_PTRN \
    -rail_width $M1_RAIL_WIDTH \
    -layers M2

set_pg_strategy PG_M1_M2_RAIL_M1_STR \
    -pattern { {name: PG_M1_M2_RAIL_M1_PTRN}{nets: {VDD VSS}}} \
    -pg_regions CORE
set_pg_strategy PG_M1_M2_RAIL_M2_STR \
    -pattern { {name: PG_M1_M2_RAIL_M2_PTRN}{nets: {VDD VSS}}} \
    -pg_regions CORE

compile_pg -strategies {PG_M1_M2_RAIL_M1_STR PG_M1_M2_RAIL_M2_STR } -via_rule NO_VIA -tag PG_M1_M2_RAIL

reset_app_options plan.pgroute.patch_via_enclosure
reset_app_options plan.pgroute.treat_fixed_stdcell_as_macro


create_pg_mesh_pattern PG_M3_M4_MESH_PTRN \
    -layers { \
         {{vertical_layer:M3}{width:0.38 }\
             {spacing:interleaving}{pitch:3.6}{trim: false}{offset:0}} \
         {{horizontal_layer:M4}{width:0.38 }\
             {spacing:interleaving}{pitch:3.6}{trim: false}{offset:0.33}} \
             }\
    -via_rule {{intersection : all}{via_master:NIL}}

set_pg_strategy PG_M3_M4_MESH_STR \
    -pattern { {name: PG_M3_M4_MESH_PTRN}{nets: {VDD VSS}}} \
    -pg_regions CORE_EXPAND

compile_pg -strategies PG_M3_M4_MESH_STR -via_rule NO_VIA -tag PG_M3_M4_MESH

create_pg_mesh_pattern PG_M5_M6_MESH_PTRN \
    -layers { \
         {{vertical_layer:M5}{width:0.38 }\
             {spacing:interleaving}{pitch:3.6}{trim: false}{offset:0}} \
         {{horizontal_layer:M6}{width:0.38 }\
             {spacing:interleaving}{pitch:7.2}{trim: false}{offset:0.33}} \
             }\
    -via_rule {{intersection : all}{via_master:NIL}}

set_pg_strategy PG_M5_M6_MESH_STR \
    -pattern { {name: PG_M5_M6_MESH_PTRN}{nets: {VDD VSS}}} \
    -pg_regions CORE_EXPAND

compile_pg -strategies PG_M5_M6_MESH_STR -via_rule NO_VIA -tag PG_M5_M6_MESH

create_pg_mesh_pattern PG_M7_M8_MESH_PTRN \
    -layers { \
         {{vertical_layer:M7}{width:2.0 }\
             {spacing:interleaving}{pitch:14.4}{trim: false}{offset:0}} \
         {{horizontal_layer:M8}{width:2.0 }\
             {spacing:interleaving}{pitch:14.4}{trim: false}{offset:0.33}} \
             }\
    -via_rule {{intersection : all}{via_master:NIL}}

set_pg_strategy PG_M7_M8_MESH_STR \
    -extension {{{stop: outermost_ring}}} \
    -pattern { {name: PG_M7_M8_MESH_PTRN}{nets: {VDD VSS}}} \
    -pg_regions CORE_EXPAND

compile_pg -strategies PG_M7_M8_MESH_STR -via_rule NO_VIA -tag PG_M7_M8_MESH
set_app_options -name plan.pgroute.optimize_via_when_maximize_cutarea -value false
set_app_options -name plan.pgroute.fix_via_drc_multiple_viadef -value false
set_app_options -name plan.pgroute.treat_fixed_stdcell_as_macro -value true
set_app_options -name plan.pgroute.patch_via_enclosure -value true

create_pg_vias -from_layers M3 -to_layers M2 -nets {VDD VSS} -via_masters {VIA23 FATVIA23}

create_pg_vias -from_layers M4 -to_layers M3 -nets {VDD VSS} -via_masters {VIA34 FATVIA34}

create_pg_vias -from_layers M5 -to_layers M4 -nets {VDD VSS} -via_masters {VIA45 FATVIA45}

create_pg_vias -from_layers M6 -to_layers M5 -nets {VDD VSS} -via_masters {VIA56 FATVIA56}

create_pg_vias -from_layers M7 -to_layers M6 -nets {VDD VSS} -via_masters {VIA67 FATVIA67}

create_pg_vias -from_layers M8 -to_layers M7 -nets {VDD VSS} -tag PG_VIA_M7_M8 -via_masters {VIA78 FATVIA78}
reset_app_options plan.pgroute.optimize_via_when_maximize_cutarea
reset_app_options plan.pgroute.fix_via_drc_multiple_viadef
reset_app_options plan.pgroute.treat_fixed_stdcell_as_macro
reset_app_options plan.pgroute.patch_via_enclosure
