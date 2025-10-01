#!/bin/bash

# This gets the branch protection rules based on what the user input was in get-branch-protection-rules.yml (default is all branches with rules)

echo "You picked $GET_RULES_FOR "

if [[ "$GET_RULES_FOR" == 'all branches with rules' ]]
then
    BRANCH="env%2Fqa1"
    # ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/branches/env/qa1/protection -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
    # ruleset=$(gh api repos/org-mushroom-kingdom/bash-git-script/rules/branches -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
    # ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/8111052 -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
    mapfile -t ruleset_ids < <(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Authorization: Bearer $REPO_READ_TOKEN" \
    repos/org-mushroom-kingdom/bash-git-script/rulesets | jq -r '.[].id')
    # echo "Branch ruleset: $ruleset"
    for id in "${ruleset_ids[@]}"
    do
        echo "Branch ruleset id: $id"
    done 
else
    echo "Specific logic TBD'"
fi