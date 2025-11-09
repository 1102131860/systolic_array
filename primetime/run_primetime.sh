#!/bin/bash

rm -rf *.log
rm -rf *.rpt
cp ../sim/apr/matrix_mult_wrapper_03_postapr.vcd ./
vcd2saif -input ./matrix_mult_wrapper_03_postapr.vcd -output ./matrix_mult_wrapper_03_postapr.saif

pt_shell -f primetime.tcl | tee primetime.log
