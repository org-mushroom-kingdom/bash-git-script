#!/bin/bash

# This gets the branch protection rules based on what the user input was in get-branch-protection-rules.yml (default is all branches with rules)

# Please note: Detailed descriptions are mostly taken directly from the 'Available rules for rulesets' page in Github Documentation. See: https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
# TODO: Disclaimer is that this only reads back info about rules, DOES NOT do logic check about rulesets

#TODO: DELETE THIS AND BELOW LINE
# README markdown documentation: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax

#TODO: COmment about what Action vars this receives

echo "You picked $GET_RULES_FOR "
declare -a all_rules_json_arr
BRANCH="env%2Fqa1"
readonly BRANCH_PROT_FILE="./docs/branch-protection-rules.md"


# FOR ALL RULESETS
mapfile -t ruleset_ids < <(gh api \
-H "Accept: application/vnd.github+json" \
-H "X-GitHub-Api-Version: 2022-11-28" \
-H "Authorization: Bearer $REPO_READ_TOKEN" \
repos/org-mushroom-kingdom/bash-git-script/rulesets | jq -r '.[].id')

# FOR ONE RULESET
# ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/8111052 -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
# echo "Branch ruleset: $ruleset"

add_rule_chunk()
{
    # Formats a chunk of text relating to the rule, and adds it to the corresponding ruleset README.md
    rule_json_str="$1"
    rule_chunk="-------------------------------------------------------------"
    br="<br>"
    
    # echo "rule json str= $rule_json_str"
    rule_name=$(echo "$rule_json_str" | jq -r '.name')
    rule_chunk+="Name: $rule_name $br"
    rule_active=$(echo "$rule_json_str" | jq -r '.enforcement')
    # ${var}^ capitalizes the first letter
    rule_chunk+="Status: ${rule_active^} $br"
    rule_updated_date_TZ=$(echo "$rule_json_str" | jq -r '.updated_at') #ex. "2025-10-01T03:12:39.393Z"
    rule_updated_date_EST=$(TZ='America/New_York' date -d "$rule_updated_date_TZ" +'%m-%d-%Y %H:%M')
    rule_chunk+="Last Updated: $rule_updated_date_EST EST $br"
    rule_chunk+="This branch protection ruleset effects the following branches/branch patterns: $br"
    rule_effected_branches=$(echo "$rule_json_str" | jq -r '.effected_branches')
    for effected in "${rule_effected_branches[@]}"
    do
        #Attempt tabulation
        rule_chunk+="    - $effected $br"
    done
    # mapfile -t rule_json_arr< <(echo "$rule_json_str" | jq -r '.rules') # This doesn't work because it does literally every string "[" "{" }
    # rule_json=$(echo "$rule_json_str" | jq -r '.[].rules') This doesn't work Cannot index string with string 'rules'
    rule_json=$(echo "$rule_json_str" | jq -c '.rules[]')
    # echo "rule_json = ${rule_json}"
    rule_json_type=$(echo "$rule_json" | jq -r '.type')
    echo "rule_json_type = $rule_json_type"
    # for rule_json in "${rule_json_arr[@]}"
    # do
    #     echo "rule_json = ${rule_json}"
    # done
    # rule_json_arr=$(echo "$rule_json_str" | jq '.rules')
    # echo "rule_json_arr = ${rule_json_arr}"
    # echo "rule_json_arr[0] = ${rule_json_arr[0]}"
    # echo "rule_json_arr = ${rule_json_arr[@]}"
    # echo "rule_json_arr[0] = ${rule_json_arr[0]}"
    mapfile -t rule_ruletype_list < <(echo "$rule_json_str" | jq -r '.rules' | jq -r '.[].type')
    # echo "rule_rules = $rule_rules"
    # echo "rule_ruletype_list[0] = ${rule_ruletype_list[0]}"
    for ruletype_list_item in "${rule_ruletype_list[@]}"
    do
        rule_description=$(get_rule_description "$rulelist_item")
        # get_rule_description "$rulelist_item"
        # echo "rule_description = $rule_description"
        rule_chunk+="${rule_description} $br"
    done
}

get_rule_description()
{
    #Given a rule_type, return a detailed description of the rule (rule_desc)
    rule_type=$1
    rule_desc="" # A detailed description of the rule
    # echo "get_rule_description() firing! rule_type = '$rule_type'"
    begin_desc="If selected, "
    case "$rule_type" in
    "deletion" | "creation" | "update")
        if [[ ! "update" = "$rule_type" ]]
        then
            # Replace ion with e (ex. creation --> create)
            verb=$( echo "$rule_type" | sed 's/ion/e/')
        else
            verb="$rule_type"
        fi
        rule_desc="If selected, only users with bypass permissions can ${verb} branches or tags whose name matches the pattern(s) specified."
        ;;
    "non_fast_forward")
        # TODO: Fill this out
        rule_desc="${begin_desc} TBD"
        ;;
    "required_linear_history")
        rule_desc="A required linear history prevents collaborators from pushing merge commits to the targeted branches or tags. This means that any pull requests merged into the branch or tag must use a squash merge or a rebase merge. A strictly linear commit history can help teams revert changes more easily."
        rule_desc+="<br>For this logic to work, your repository must allow squash merging or rebase merging. Check the TODO NAME ME section to ensure this is the case."
        ;;
    "merge_queue")
        #TODO: Figure this out
        rule_desc="This ruleset uses a merge queue. For more information on how merge queues work and their benefits see [relevant documentation] (https://docs.github.com/en/enterprise-cloud@latest/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request-with-a-merge-queue#about-merge-queues)"
        echo "This returns two keys, one is the standard 'type' queue but the other 'parameters' is a JSON. So will have to sort thru that..."
        ;;
    "required_deployments")
        #TODO: Figure this out. Also need a deployment environment in repo for this to really work.
        echo "This returns two keys, one is the standard 'type' queue but the other 'parameters' is a JSON with one key that is an array. So will have to sort thru that..."
        ;;
    "required_signatures")
        rule_desc="Required commit signing on a branch means that contributors and bots can only push commits that have been signed and verified to the branch."
        rule_desc+="<br>*Please note: This activity differs somewhat between rulesets and branch protection rules. Please see the [relevant documentation] (https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-signed-commits) for more details.*"
        ;;
    "pull_request")
        #TODO: Figure this out. .
        echo "This returns two keys, one is the standard 'type' queue but the other 'parameters' is a JSON. One of the keys is an array. So will have to sort thru that..."
        ;;
    "required_status_checks")
        #TODO: Figure this out. 
        echo "This returns two keys, one is the standard 'type' queue but the other 'parameters' is a JSON. One of the keys is a JSON array. So will have to sort thru that..."
        ;;
    "code_scanning")
        #TODO: Figure this out.
        echo "This returns two keys, one is the standard 'type' queue but the other 'parameters' is a JSON with one key that is a JSON array. So will have to sort thru that..."
        ;;
    "copilot_code_review")
        #TODO: Figure this out. Also need a deployment environment in repo for this to really work.
        echo "This returns two keys, one is the standard 'type' queue but the other 'parameters' is a JSON. So will have to sort thru that..."
        ;;
    esac
    # echo "rule_desc = $rule_desc"
    echo "${rule_desc}"
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
    # echo "all_rules_json_arr[0] = ${all_rules_json_arr[0]}"
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
    # echo "$changed_files_output" > ./docs/branch-protection-rulesets/branch-protection-rules.md 
    # git add ./docs/branch-protection-rules.md #prepare for commit
    # git commit -m "Update branch-protection-rules"
    # git push origin main

else
    echo "Specific logic TBD'"
fi