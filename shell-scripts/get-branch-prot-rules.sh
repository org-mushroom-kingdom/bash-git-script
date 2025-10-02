#!/bin/bash

# This gets the branch protection rules based on what the user input was in get-branch-protection-rules.yml (default is all branches with rules)

echo "You picked $GET_RULES_FOR "
declare -a all_rules_json_arr
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
if [[ "$GET_RULES_FOR" == 'all branches with rules' ]]
then
    for id in "${ruleset_ids[@]}"
    do
        # echo "Branch ruleset id: $id"
        ruleset_json=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/$id -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN") 
        # ruleset_name=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/$id -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN" | jq '.name') 
        echo "$ruleset_json"
        # ruleset_json=$(echo "$ruleset_json" | jq '[.[] | {name, enforcement}') 
        
        all_rules_json_arr+=("$ruleset_name")
        #TODO: Use this as a scaffold to write to a file
        # echo "$changed_files_output" > test-json-output.txt 
        # git add test-json-output.txt
        # git commit -m "Capture output from Github 'get changed files' call"
        # git push origin main
    done
    echo "all_rules_json_arr[0] = ${all_rules_json_arr[0]}" 
else
    echo "Specific logic TBD'"
fi