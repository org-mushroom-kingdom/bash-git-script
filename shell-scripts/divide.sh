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
    DIVIDES_BY_2="is false!!"

    if (( NUM % 2 == 0 ))
    then
        # echo "Divisible by 2"
        DIVIDES_BY_2="is true!!"
    else
        # echo "NOT Divisible by 2"
        DIVIDES_BY_2="is false!!"
    fi
    echo "${DIVIDES_BY_2}"
}

# Double brackets in Bash are more versatile than single brackets, but single brackets could be used here too. 
# (Double brackets don't do word splitting, allows easier use of ==, BUT aren't usable with all shells)
# Brackets are needed in any case because parentheses won't work (parentheses are used for commands) 
# Brackets test expressions inside [] (or [[]]). True expressions evaluate to result code 0, false evaluates to result code 1. (You could literally do if [ 0 ] to prove this)
if [[ "$FXN_TO_CALL" == "is_divisible_by_2" ]]
then
    # echo "NUM_TO_DIVIDE = $NUM_TO_DIVIDE"
    # echo "$NUM_TO_DIVIDE is_divisible_by_2 = " $(is_divisible_by_2 $NUM_TO_DIVIDE)
    IS_IT_DIVISIBLE=$(is_divisible_by_2 "${NUM_TO_DIVIDE}")
    echo -n $IS_IT_DIVISIBLE | tr -d '\n'
fi
