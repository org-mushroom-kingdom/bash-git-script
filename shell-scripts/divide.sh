#!/bin/bash

# This shell script shows how to use Bash modulo. 
# Really, it was made to be referenced by a couple of things.

# To call a specific function from this script from Git Bash:
# $ source ./shell-scripts/divide.sh
# function_name arg1 arg2 arg3 ...

FXN_TO_CALL=$1
NUM_TO_DIVIDE=$2

# The current situation is that $NUM_TO_DIVIDE appears to not be passing to is_divisible_by_2, resulting in
# ./shell-scripts/divide.sh: line 21: ((: = % 2 == 0: syntax error: operand expected (error token is "= % 2 == 0")
# ./shell-scripts/divide.sh: line 36: is: command not found
# BUT echoing NUM_TO_DIVIDE on its own is working so maybe above errors due to something else? Look in Bash docs
is_divisible_by_2()
{
    NUM=$1 # Integer
    DIVIDES_BY_2="is false!!"

    # echo "NUM = $NUM"
    echo "${NUM}"
    # if (( NUM % 2 == 0 ))
    # then
    #     # echo "Divisible by 2"
    #     DIVIDES_BY_2="is true!!"
    # else
    #     # echo "NOT Divisible by 2"
    #     DIVIDES_BY_2="is false!!"
    # fi
    # echo "${DIVIDES_BY_2}"
}

if ( "$FXN_TO_CALL" = "is_divisible_by_2" )
then
    # echo "NUM_TO_DIVIDE = $NUM_TO_DIVIDE"
    # echo "$NUM_TO_DIVIDE is_divisible_by_2 = " $(is_divisible_by_2 $NUM_TO_DIVIDE)
    IS_IT_DIVISIBLE=$(is_divisible_by_2 "${NUM_TO_DIVIDE}")
    echo $IS_IT_DIVISIBLE
fi
# echo "NUM_TO_DIVIDE = $NUM_TO_DIVIDE"
# echo "DIVIDING"