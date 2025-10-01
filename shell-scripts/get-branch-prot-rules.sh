#!/bin/bash

# This gets the branch protection rules based on what the user input was in get-branch-protection-rules.yml (default is all)

echo "You picked $GET_RULES_FOR "

if [[ "$GET_RULES_FOR" != "all" ]]
then
    ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/branches/$GET_RULES_FOR/protection --header "Authorization: Bearer $REPO_READ_TOKEN")
    echo "Branch ruleset: $ruleset"
else
    echo "'all' logic TBD'"
fi