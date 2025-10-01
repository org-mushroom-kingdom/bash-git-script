#!/bin/bash

# This gets the branch protection rules based on what the user input was in get-branch-protection-rules.yml (default is all branches with rules)

echo "You picked $GET_RULES_FOR "

if [[ "$GET_RULES_FOR" == 'all branches with rules' ]]
then
    BRANCH="env/qa1"
    ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/branches/$BRANCH/protection --header "Authorization: Bearer $REPO_READ_TOKEN")
    echo "Branch ruleset: $ruleset"
else
    echo "'all' logic TBD'"
fi