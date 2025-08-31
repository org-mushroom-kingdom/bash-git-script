#!/bin/bash

# This shell script shows how to use Bash modulo. 
# Really, it was made to be referenced by a couple of things.

# To call a specific function from this script from Git Bash:
# $ source ./shell-scripts/divide.sh
# function_name arg1 arg2 arg3 ...
is_divisible_by_2()
{
    NUM_TO_DIVIDE=$1 # Integer
    DIVIDES_BY_2=false

    echo "NUM_TO_DIVIDE = $NUM_TO_DIVIDE"
    if (($NUM_TO_DIVIDE % 2 == 0))
    then
        echo "Divisible by 2"
        DIVIDES_BY_2=true
    else
        echo "NOT Divisible by 2"
        DIVIDES_BY_2=false
    fi
    echo "NUM_TO_DIVIDE divisible by 2 = ${DIVIDES_BY_2}"
}