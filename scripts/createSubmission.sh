#!/bin/tcsh

# Tars results for submission
# source ./createSubmission {Milestone} {GroupNumber}
# Call this from the scripts directory

if ($1 == "" || $2 == "") then
    echo "Incorrect Format: source ./createSubmission {Milestone} {GroupNumber}"
    exit
endif

echo "Milestone $1"
echo "Group $2"

if ($1 == 1) then
    echo "Tarring Files. Please ensure APR and SYN Folders are Empty of Outputs"
    cd ../
    tar --exclude="*.tar.gz" -czf "group$2_ms1.tar.gz" *     
    cd scripts
endif

if ($1 == 2) then
    echo "Tarring Synthesis Files"
    cd ..
    tar -czf "group$2_ms2.tar.gz" syn/results syn/reports
    cd scripts
endif

if ($1 == 3) then
    echo "Tarring APR Files"
    cd ..
    tar -czf "group$2_ms3.tar.gz" apr/results apr/reports apr/matrix_mult_wrapper_$2_lib
    cd scripts
endif

if ($1 == 4) then
    echo "Tarring APR Files"
    cd ..
    tar -czf "group$2_ms4.tar.gz" apr/results apr/reports apr/matrix_mult_wrapper_$2_lib
    cd scripts
endif
