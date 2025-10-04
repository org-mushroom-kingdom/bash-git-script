#!/bin/bash

# This gets the branch protection rules based on what the user input was in get-branch-protection-rules.yml (default is all branches with rules)

# TODO: It would be great to schedule this like once a week/day to get the most current info on the rules
echo "You picked $GET_RULES_FOR "
declare -a all_rules_json_arr
BRANCH="env%2Fqa1"
readonly BRANCH_PROT_FILE="./docs/branch-protection-rules.md"
# ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/branches/env/qa1/protection -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
# ruleset=$(gh api repos/org-mushroom-kingdom/bash-git-script/rules/branches -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
# ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/8111052 -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
mapfile -t ruleset_ids < <(gh api \
-H "Accept: application/vnd.github+json" \
-H "X-GitHub-Api-Version: 2022-11-28" \
-H "Authorization: Bearer $REPO_READ_TOKEN" \
repos/org-mushroom-kingdom/bash-git-script/rulesets | jq -r '.[].id')
# echo "Branch ruleset: $ruleset"

add_rule_chunk()
{
    rule_json_str="$1"
    rule_chunk="-------------------------------------------------------------"
    br="<br>"
    
    echo "rule json str= $rule_json_str"
    rule_name=$(echo "$rule_json_str" | jq -r '.name')
    rule_chunk+="Name: $rule_name $br"
    rule_active=$(echo "$rule_json_str" | jq -r '.enforcement')
    rule_chunk+="Status: ${rule_active^} $br"
    rule_updated_date_TZ=$(echo "$rule_json_str" | jq -r '.updated_at') #ex. "2025-10-01T03:12:39.393Z"
    rule_updated_date_EST=$(TZ='America/New_York' date -d "$rule_updated_date_TZ" +'%m-%d-%Y %H:%M')
    rule_chunk+="Last Updated: $rule_updated_date_EST EST $br"
    rule_chunk+="This rule effects the following branches/branch patterns: $br"
    rule_effected_branches=$(echo "$rule_json_str" | jq -r '.effected_branches')
    for effected in "${rule_effected_branches[@]}"
    do
        rule_chunk+="    - $effected $br"
    done
    mapfile -t rule_rulelist < <(echo "$rule_json_str" | jq -r '.rules' | jq -r '.[].type')
    # echo "rule_rules = $rule_rules"
    echo "rule_rulelist[0] = ${rule_rulelist[0]}"
    for rulelist_item in "${rule_rulelist[@]}"
    do
        # rule_description=$(get_rule_description "$rulelist_item")
        get_rule_description "$rulelist_item"
        echo "rule_description = $rule_description"
        rule_chunk+="    - $effected $br"
    done
}

get_rule_description()
{
    rule_type=$1
    rule_desc="" # A description of the rule
    echo "get_rule_description() firing! rule_type = '$rule_type'"
    case "$rule_type" in
    "deletion")
        rule_desc="Only allow users with bypass permissions to delete matching refs."
        ;;
    esac
    echo "$rule_desc"
}

if [[ "$GET_RULES_FOR" == 'all branches with rules' ]]
then
    for id in "${ruleset_ids[@]}"
    do
        # echo "Branch ruleset id: $id"
        ruleset_json=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/$id -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN") 
        # ruleset_name=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/$id -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN" | jq '.name') 
        # echo "$ruleset_json"
        # Example of how to filter a single JSON for the desired values (ex. original JSON returns things like id, source_type, etc) 
        # This essentially creates a new JSON (note the {})
        # The 'effected_branches:' syntax creates a key called 'effected_branches' in the new JSON. 
        # In ruleset_json, 'conditions' has a JSON value. The 'ref_name' key in THAT JSON is another JSON. 'include' is a key (with an array value) in the ref_name JSON.
        ruleset_json=$(echo "$ruleset_json" | jq '{name, effected_branches: .conditions.ref_name.include, enforcement, rules, updated_at}') 
        
        all_rules_json_arr+=("$ruleset_json")
    done
    #  [rule1,rule2] length 2, last index is 1
    echo "all_rules_json_arr[0] = ${all_rules_json_arr[0]}"
    # clear out the existing contents of ./docs/branch-protection-rules.md
    #  echo -n "" > $BRANCH_PROT_FILE
    # TODO: Add template text (e.g. "this doc blablabla, last updated $TIMESTAMP)
    # TODO: Get a nice formatted timestamp
    for (( i=0; i<"${#all_rules_json_arr[@]}"; i++ ))
    do
        add_rule_chunk "${all_rules_json_arr[$i]}"
        #TODO: DELETE THIS
        # exit
    done
    
    # TODO: Use this as a scaffold to push to a file
    # echo "$changed_files_output" > ./docs/branch-protection-rules.md 
    # git add ./docs/branch-protection-rules.md #prepare for commit
    # git commit -m "Update branch-protection-rules"
    # git push origin main

else
    echo "Specific logic TBD'"
fi