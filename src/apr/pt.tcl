set PROCESS "65GP"
set TECH_LABEL "tsmc65gplus"

puts $PROCESS

set TSMC_PATH "/tools/pdk/designkits/tsmc/tsmc65gp/tcbn65gplus_200a/TSMCHOME/digital"
set TARGETCELLLIB_PATH "$TSMC_PATH/Front_End/timing_power_noise/NLDM/tcbn65gplus_200a"
set MW_TECHFILE_PATH "$TSMC_PATH/Back_End/milkyway/tcbn65gplus_200a/techfiles"
set MW_REFERENCE_LIBS "$TSMC_PATH/Back_End/milkyway/tcbn65gplus_200a/cell_frame/tcbn65gplus"

set MW_TLUPLUS_PATH "$MW_TECHFILE_PATH/tluplus"
set MW_TECHFILE "tcbn65gplus.tf"
set MAX_TLUPLUS_FILE "cln65g+_1p09m+alrdl_rcbest_top2.tluplus"
set MIN_TLUPLUS_FILE "cln65g+_1p09m+alrdl_rcworst_top2.tluplus"
set TECH2ITF_MAP_FILE "star.map_9M"

set SYNOPSYS_SYNTHETIC_LIB "dw_foundation.sldb"

set TARGET_LIBS [list \
   "tcbn65gplustc.db" \
   "tcbn65gplusbc.db" \
   "tcbn65gpluswc.db" \
]

set STD_CELL_LIB_NAME "tcbn65gplustc"
set SYMBOL_LIB "tcbn65gplustc.db"
# Worst case library
set LIB_WC_FILE   "tcbn65gpluswc.db"
set LIB_WC_NAME   "tcbn65gpluswc"
# Best case library
set LIB_BC_FILE   "tcbn65gplusbc.db"
set LIB_BC_NAME   "tcbn65gplusbc"
# Typical case library
set LIB_TC_FILE   "tcbn65gplustc.db"
set LIB_TC_NAME   "tcbn65gplustc"
# Operating conditions
set LIB_WC_OPCON  "NC1D0COM"
set LIB_BC_OPCON  "BC1D1COM"
set NDM_DIR "./ndm"
set ANTENNA_RULES_FILE "antennaRule_n65_9lm.icc2.tcl"

set search_path  [list \
      "$TARGETCELLLIB_PATH" \
      "$MW_TECHFILE_PATH" \
      "$MW_REFERENCE_LIBS" \
      "$synopsys_root/libraries/syn" \
      "./db" \
      "./" \
   ]


set search_path "./ $search_path \
                    $synopsys_root/libraries/syn \
                    $MW_TECHFILE_PATH \
                    $MW_TLUPLUS_PATH \
                    ${NDM_DIR}/${PROCESS}"
                    
                    


set power_enable_analysis FALSE
#set target_library
set link_library $TARGET_LIBS 


#set link_create_black_boxes false


#reading the netlist
#read_db $targer_library

set toplevel "matrix_mult_wrapper_03"
set filename [format "%s%s" $toplevel ".apr.v"]
read_verilog ./results/$filename
current_design $toplevel
#link_design $toplevel


set filename [format "%s%s" $toplevel ".func1_wc.sdc"]
read_sdc -echo ./results/$filename

set filename [format "%s%s" $toplevel ".wc.spef.wc_125.spef"]
read_parasitics -format spef ./results/$filename
update_timing

report_analysis_coverage > ./reports/pt_coverage.rpt
report_constraint -all > ./reports/pt_constraint.rpt
#report_timing_histogram > ./reports/timing_histogram.rpt
#report_violations > ./reports/timing_violations.rpt
report_net > ./reports/pt_net_report.rpt


report_timing -delay_type max -max_paths 100 -nworst 1 > ./reports/pt_setup_report.rpt
report_timing -delay_type min -max_paths 100 -nworst 1 > ./reports/pt_hold_report.rpt

#exit

