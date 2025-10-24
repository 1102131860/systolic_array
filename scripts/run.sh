#!/bin/bash
in_bit=3 # make input range -2^(WIDTH - in_bit) to 2^(WIDTH - in_bit) - 1
test_num=1 # number of random tests to run

# configure matrix size
# Input * Weight = Output
# [M, K] * [K, N] = [M, N]
M=6
K=4
N=4
output_stat=0
mode='memory'
# external

COL=$N
I_SIZE=$((M + K - 1))
if [ "$output_stat" -eq 1 ]; then
    ROW=$M
    O_SIZE=$M
    W_SIZE=$((N + K - 1))
else
    ROW=$K
    O_SIZE=$((N + M - 1))
    W_SIZE=$K
fi

# code from tutorial 1p2 for coloring
HEADER='\033[95m'
OKBLUE='\033[94m'
OKCYAN='\033[96m'
OKGREEN='\033[92m'
WARNING='\033[93m'
FAIL='\033[91m'
ENDC='\033[0m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

make link_src
# run tests with randomly generated inputs
rm -rf logs/error.log
rm -rf logs/final_log.txt

for mode in memory external bist
do
    echo -e "================ Running mode: $mode ================\n"
    # if bist mode, the how to write?
    if [ "$mode" = "bist" ]; then
        make clean
        python3.8 generate_golden.py --in_bit $in_bit --M $M --N $N --K $K --output_stat $output_stat
        make vcs TESTNAME=$mode RAND_SEED=$((i+1))
        # no check verify and checks need
    else
        for (( i = 0; i < $test_num; i++ ));
        do
            make clean
            python3.8 generate_golden.py --in_bit $in_bit --M $M --N $N --K $K --output_stat $output_stat
            make vcs TESTNAME=$mode RAND_SEED=$((i+1))
            python3.8 verify_output.py --mode $mode

            FILE=./logs/error.log
            if [ -f "$FILE" ]; then
                echo -e "${FAIL}****************************************************************************************************${ENDC}\e"
                echo -e "${FAIL}****** summary: FAIL *******************************************************************************${ENDC}\e"
                echo -e "${FAIL}****************************************************************************************************${ENDC}\e"
                echo -e "\n"

                exit 1
            fi
        done

        # run with zero input
        make clean
        python3.8 generate_golden.py --in_bit $in_bit --mode zero --M $M --N $N --K $K --output_stat $output_stat # enable input=zero mode
        make vcs TESTNAME=$mode RAND_SEED=$((i+1))
        python3.8 verify_output.py --mode $mode


        # run with all inputs saturated
        make clean
        python3.8 generate_golden.py --in_bit $in_bit --mode full --M $M --N $N --K $K --output_stat $output_stat # enable input=saturated mode
        make vcs TESTNAME=$mode RAND_SEED=$((i+1))
        python3.8 verify_output.py --mode $mode
    fi

    # pass us if there is no error log 
    FILE=./logs/error.log
    if [ -f "$FILE" ]; then
        echo -e "${FAIL}****************************************************************************************************${ENDC}\e"
        echo -e "${FAIL}****** summary: FAIL *******************************************************************************${ENDC}\e"
        echo -e "${FAIL}****************************************************************************************************${ENDC}\e"
    else 
        echo -e "${OKGREEN}****************************************************************************************************${ENDC}\e"
        echo -e "${OKGREEN}****** summary: PASS *******************************************************************************${ENDC}\e"
        echo -e "${OKGREEN}****************************************************************************************************${ENDC}\e"
    fi
    echo -e "\n"

done
