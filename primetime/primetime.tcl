set TOOL_NAME "DC"
set DESIGN_MW_LIB_NAME "${TOOL_NAME}.db"
set TSMC_PATH "/tools/pdk/designkits/tsmc/tsmc65gp/tcbn65gplus_200a/TSMCHOME/digital"
set TARGETCELLLIB_PATH "$TSMC_PATH/Front_End/timing_power_noise/NLDM/tcbn65gplus_200a"
set TYPICAL_LIB_FILE "$TSMC_PATH/digital/Front_End/timing_power_noise/NLDM/tcbn65gplustc.lib"
set ADDITIONAL_SEARCH_PATHS [list \
   "$TARGETCELLLIB_PATH" \
   "$TSMC_PATH/Back_End/milkyway/tcbn65gplue_200a/cell_frame/tcbn65gplus/LM/*" \
   "$synopsys_root/libraries/syn" \
   "./db" \
   "./" \
]

set TARGET_LIBS [list \
   "tcbn65gplustc.db" \
   "tcbn65gplusbc.db" \
   "tcbn65gpluswc.db" \
]
set ADDITIONAL_TARGET_LIBS []
set STD_CELL_LIB_NAME "tcbn65gplustc"
set SYMBOL_LIB "tcbn65gplustc.db"
set SYNOPSYS_SYNTHETIC_LIB "dw_foundation.sldb"

set MW_REFERENCE_LIBS "$TSMC_PATH/Back_End/milkyway/tcbn65gplus_200a/cell_frame/tcbn65gplus/"
set MW_ADDITIONAL_REFERENCE_LIBS []
set LIB_WC_FILE   "tcbn65gplustc.db"
set LIB_WC_NAME   "tcbn65gplustc"

# Best case library
set LIB_BC_FILE   "tcbn65gplusbc.db"
set LIB_BC_NAME   "tcbn65gplusbc"
set MW_TECHFILE_PATH "$TSMC_PATH/Back_End/milkyway/tcbn65gplus_200a/techfiles"
set MW_TLUPLUS_PATH "$MW_TECHFILE_PATH/tluplus"
set MW_TECHFILE "tsmcn65_9lmT2.tf"
set MAX_TLUPLUS_FILE "cln65g+_1p09m+alrdl_rcbest_top2.tluplus"
set MIN_TLUPLUS_FILE "cln65g+_1p09m+alrdl_rcworst_top2.tluplus"
set TECH2ITF_MAP_FILE "star.map_9M"

set_app_var search_path [concat $search_path $ADDITIONAL_SEARCH_PATHS]
set_app_var target_library "$TARGET_LIBS $ADDITIONAL_TARGET_LIBS"
set_app_var link_path [list "*" $TARGET_LIBS]
set_app_var link_library "* $TARGET_LIBS $SYNOPSYS_SYNTHETIC_LIB"
if {[llength $ADDITIONAL_TARGET_LIBS] > 0} {
   set_app_var target_library "$target_library $ADDITIONAL_TARGET_LIBS"
   set_app_var link_path "$link_path $ADDITIONAL_TARGET_LIBS"
   set_app_var link_library "$link_library $ADDITIONAL_TARGET_LIBS"
}
set_app_var symbol_library $SYMBOL_LIB



set power_enable_analysis true
set power_enable_multi_corner_analysis true
set toplevel "matrix_mult_wrapper_03"
read_db $TARGET_LIBS
read_ndm ../apr/ndm/65GP/tcbn65gplus_physical_only.ndm/reflib.ndm
read_ndm ../apr/ndm/65GP/tcbn65gplus.ndm/reflib.ndm
read_verilog ../apr/results/$toplevel.apr.v
current_design $toplevel
link_design
report_reference > design_reference.rpt
set_false_path -from [get_ports test_config_i]
set_false_path -from [get_ports data_config_i]
set_false_path -from [get_ports ext_inputs_i]
set_false_path -from [get_ports ext_en_i]
set_false_path -to [get_ports sample_clk_o]
set_false_path -to [get_ports ext_result_o]
set_false_path -to [get_ports ext_valid_o]
read_sdc -version 2.1 ../apr/results/$toplevel.func1_wc.sdc
read_parasitics -format spef ../apr/results/$toplevel.wc.spef.wc_125.spef

update_timing
report_timing -delay_type max -max_paths 100 > pt_wc_setup.rpt
report_analysis_coverage > pt_wc_coverage.rpt
report_constraints -all > pt_wc_constraints.rpt


read_sdc -version 2.1 ../apr/results/$toplevel.func1_bc.sdc
read_parasitics -format spef ../apr/results/$toplevel.bc.spef.bc_0.spef
update_timing
report_timing -delay_type min -max_paths 100 > pt_bc_hold.rpt
report_analysis_coverage > pt_bc_coverage.rpt
report_constraints -all > pt_bc_constraints.rpt

set power_analysis_mode averaged
set filename [format "%s%s" $toplevel "_postapr.vcd"]
read_vcd ./$filename -strip_path tb_matrix_mult_wrapper/matrix_mult_wrapper_0
set filename [format "%s%s" $toplevel "_postapr.saif"]
read_saif ./$filename -strip_path tb_matrix_mult_wrapper/matrix_mult_wrapper_0
report_switching_activity -list_not_annotated > pt_switching_activity.rpt
read_parasitics -format spef ../apr/results/$toplevel.wc.spef.wc_125.spef
update_power
report_power > pt_avg_power.rpt
report_power -hierarchy -level 4 -nosplit > pt_hierarchical_avg_power.rpt


set power_analysis_mode time_based
read_vcd ./$filename -strip_path tb_matrix_mult_wrapper/matrix_mult_wrapper_0
read_parasitics -format spef ../apr/results/$toplevel.wc.spef.wc_125.spef
update_power
report_power > pt_time_power.rpt
exit




