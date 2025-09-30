#!/bin/bash

echo "You picked $GET_RULES_FOR "

if [[ "$GET_RULES_FOR" != "all" ]]
then
    ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/branches/$GET_RULES_FOR/protection)
    echo "Branch ruleset: $ruleset"
else
    echo "'all' logic TBD'"
fi