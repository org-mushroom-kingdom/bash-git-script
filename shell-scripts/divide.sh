#!/bin/bash

# This shell script shows how to use Bash modulo. 
# Really, it was made to be referenced by a couple of things.

# To call a specific function from this script from Git Bash:
# $ source ./shell-scripts/divide.sh
# function_name arg1 arg2 arg3 ...

FXN_TO_CALL=$1
NUM_TO_DIVIDE=$2



is_divisible_by_2()
{
    NUM=$1 # Integer
    DIVIDES_BY_2=false

    echo "NUM = $NUM"
    if (($NUM % 2 == 0))
    then
        # echo "Divisible by 2"
        DIVIDES_BY_2=true
    else
        # echo "NOT Divisible by 2"
        DIVIDES_BY_2=false
    fi
    echo "${DIVIDES_BY_2}"
}

# if ( "$FXN_TO_CALL" = "is_divisible_by_2")
# then
#     # echo "NUM_TO_DIVIDE = $NUM_TO_DIVIDE"
#     # echo "$NUM_TO_DIVIDE is_divisible_by_2 = " $(is_divisible_by_2 $NUM_TO_DIVIDE)
# fi
echo "NUM_TO_DIVIDE = $NUM_TO_DIVIDE"
# echo "DIVIDING"