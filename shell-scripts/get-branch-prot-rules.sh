#!/bin/bash

# This gets the branch protection rules based on what the user input was in get-branch-protection-rules.yml (default is all branches with rules)
# There is no current (10-16-25) way for users without admin permissions to know the details of branch protection rulesets, so this action proves quite useful
# as it gets the branch ruleset information and writes this to a file.

# Please note: Detailed descriptions are mostly taken directly from the 'Available rules for rulesets' page in Github Documentation. See: https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
# Additionally this only reads back info about rules, it DOES NOT do any sort of logic check regarding rulesets

# This script receives and uses the following env variables:
#   GET_RULES_FOR -- directs which ruleset(s) to add to file
#   REPO_READ_TOKEN: A token with admin read permission, which is needed to get ruleset info
#   VERBOSE: When enabled, does way more print statements 
# Note that the file being written to is a README (.md) file.  
# README markdown documentation: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax


echo "You picked $GET_RULES_FOR "
declare -a all_rules_json_arr
BRANCH="env%2Fqa1"
readonly BRANCH_PROT_FILE="./docs/branch-protection-rules.md"
readonly SPACER="    " #Use this for tabulation. Four spaces, essentially a tab
readonly br="<br>" 

# FOR ALL RULESETS
mapfile -t ruleset_ids < <(gh api \
-H "Accept: application/vnd.github+json" \
-H "X-GitHub-Api-Version: 2022-11-28" \
-H "Authorization: Bearer $REPO_READ_TOKEN" \
repos/org-mushroom-kingdom/bash-git-script/rulesets | jq -r '.[].id')

# FOR ONE RULESET
# TODO: This might become vestigial...
# ruleset=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/8111052 -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN")
# echo "Branch ruleset: $ruleset"

add_rule_chunk()
{
    # Formats a chunk of text relating to the rule, and adds it to the corresponding ruleset README.md
    rule_json_str="$1"
    rule_chunk="-------------------------------------------------------------"
    
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
        rule_chunk+="${SPACER}- $effected $br"
    done
    
    # The 'rules' key is a JSON array. Use jq -c to output each item in 'rules' as a single-line JSON object. (ex. [{}{}{}] ) 
    # Use '.rules[]' to indicate we are targeting the 'rules' key and we want to iterate/output (indicated by []) over the elements inside it
    # Use mapfile and <() to take those outputs and put into array.
    mapfile -t rule_json_arr< <(echo "$rule_json_str" | jq -c '.rules[]')
    echo "rule_json_arr = ${rule_json_arr[@]}"
    # echo "rule_json_arr[0] = ${rule_json_arr[0]}"

    for rule_json in "${rule_json_arr[@]}"
    do
        rule_json_type=$(echo "$rule_json" | jq -r '.type')
        # TODO: Have a header here? That way description goes right under it
        rule_description=$(get_rule_description "$rule_json_type")
        rule_chunk+="${rule_description} $br"
        
        rule_json_parameters=$(echo "$rule_json" | jq -r '.parameters')
        
        # If no parameters key exists, rule_json_parameters will be null
        if [[ $rule_json_parameters != null ]]
        then
            [[ $VERBOSE == "true" ]] && echo "JSON with type ${rule_json_type} has a parameters key"
            echo "rule_json_parameters = $rule_json_parameters"
            # TODO: Reminder Github Copilot has similar structure, so can reuse this logic!!
            if [[ "$rule_json_type" == "merge_queue" ]]
            then
                # TODO Mention structuring of rule_chunk ${SPACER}${ruleset_page_name} (${mq_desc}${addl_details}): ${value}
                rule_chunk+="The merge queue specifications are: $br"
                # to_entries takes an object and transforms each key value pair into an array element (ex {name: "square", sides: 4} --> [{key: "name", value: "square"}])
                # [] will unwrap this array and [would] output each piece as a separate JSON
                # Then piping to .key, .value filters that output to only output the key, then the value (on two separate lines due to -r)
                echo "$rule_json_parameters" | jq -r 'to_entries[] | .key, .value' | \
                # The last pipe takes those 2 outputs and treats them as inputs to the while loop
                
                # Use read to take the 2 inputs from above and store in variables named $key and $value
                # IFS uses \n as delimiter (2 outputs on 2 separate lines, separated by \n)
                # The while here is saying 'while I am able to assign values to $key and $value (from the two inputs I am receiving)'
                # When there are no more inputs, read returns a non-zero (bad) status code which evaluates to false so loop is closed
                while IFS=$'\n' read -r key && read -r value; do
                    # First remove all(//) '_' from key, replace with ' '. Then use sed to capitalize (\U&) first (^) char (.) (ex. "merge_method" --> "Merge method")
                    mq_desc=$(echo "${key//_/ }" | sed 's/^./\U&/')
                    echo "mq_desc: $mq_desc, Value: $value"
                    # ruleset_page_name="" #The name of the setting as it appears on the rulesets page
                    # addl_details=", " #Additional details/description of the setting as it appears on the rulesets page
                    ruleset_page_name=$(get_ruleset_page_name "${rule_json_type}" "${mq_desc}")
                    addl_details=$(get_addl_details "${rule_json_type}" "${mq_desc}")
                    if [[ "$mq_desc" == "Merge method" ]]
                    then
                        mq_desc="" #Set this to '' so rule_chunk formatting isn't duplicated
                    fi
                    #TODO: Italicize ruleset_page_name or mq_desc
                    rule_chunk+="${SPACER}${ruleset_page_name} (${mq_desc}${addl_details}): ${value}"
                    [[ $VERBOSE == "true" ]] && echo "merge queue ruleset_page_name = ${ruleset_page_name}"
                    [[ $VERBOSE == "true" ]] && echo "merge queue addl_details = ${addl_details}"
                done
                    # exit
            elif [[ "$rule_json_type" == "pull_request" ]]
            then
                rule_chunk+="The pull request specifications are: $br"
                #Everything in the pull_request parameter JSON aside from one entry is a number or boolean. (allowed_merge_methods is key that points to array)
                # Use jq to_entries to get [{key: "key_name", value: "value_of"} ,{}] again
                # Use select to filter out things where value key DOES not correlate to an array
                # Then output key and value on separate lines, use while with reads to process and add to rule_chunk
                echo "$rule_json_parameters" | jq -r 'to_entries[] | select(.value | type != "array") | .key, .value' | \
                while IFS=$'\n' read -r key && read -r value; do
                    # echo "value of pull_request param: ${value}"
                    pr_desc=$(echo "${key//_/ }" | sed 's/^./\U&/')
                    echo "pr_desc: $pr_desc, Value: $value"
                    ruleset_page_name=$(get_ruleset_page_name "${rule_json_type}" "${pr_desc}")
                    addl_details=$(get_addl_details "${rule_json_type}" "${pr_desc}")
                    rule_chunk+="${SPACER}${ruleset_page_name} (${mq_desc}${addl_details}): ${value}"
                    [[ $VERBOSE == "true" ]] && echo "pull request ruleset_page_name = ${ruleset_page_name}"
                    [[ $VERBOSE == "true" ]] && echo "pull request addl_details = ${addl_details}"
                done
                # Deal with the merge methods array, an array of strings. Note: This array will always have at least 1 value, so no need to check if key exists.
                mapfile -t merge_methods< <(echo "$rule_json_parameters" | jq -r '.allowed_merge_methods[]')
                rule_chunk+="${SPACER}The allowed merged methods are: $br"
                for merge_method in "${merge_methods[@]}"
                do
                    # Use double spacer b/c 'merge methods' is already tab'd
                    rule_chunk+="${SPACER}${SPACER}- ${merge_method} $br"
                done
                # exit
            elif [[ "$rule_json_type" == "required_status_checks" ]]
            then
                rule_chunk+="The required status checks specifications are: $br"
                echo "$rule_json_parameters" | jq -r 'to_entries[] | select(.value | type != "array") | .key, .value' | \
                while IFS=$'\n' read -r key && read -r value; do
                    rsc_desc=$(echo "${key//_/ }" | sed 's/^./\U&/')
                    [[ $VERBOSE == "true" ]] && echo "rsc_desc: $rsc_desc, Value: $value"
                    ruleset_page_name=$(get_ruleset_page_name "${rule_json_type}" "${rsc_desc}")
                    addl_details=$(get_addl_details "${rule_json_type}" "${rsc_desc}")
                    #TODO: Italicize ruleset_page_name or rsc_desc
                    rule_chunk+="${SPACER}${ruleset_page_name} (${rsc_desc}${addl_details}): ${value}"
                    [[ $VERBOSE == "true" ]] && echo "status checks ruleset_page_name = ${ruleset_page_name}"
                    [[ $VERBOSE == "true" ]] && echo  "status checks addl_details = ${addl_details}"
                done
                # Remember that the syntax '.key[]' essentially means iterate thru [the array] at that key
                # Use jq -c to output each item in 'required_status_checks' as a single-line JSON object. 
                # Use // [] here as the alternative--if required_status_checks is null, then use an empty array (so you don't get an 'cannot iterate over null' error)
                # The final .[] is just saying to iterate over what is piped before it (so a JSON array or nothing)
                mapfile -t status_checks_arr < <(echo "$rule_json_parameters" | jq -c '.required_status_checks // [] | .[]')
                # Only process status_checks if there's something to process (status_checks_arr will just be [] if required_status_checks is null)
                if [[ ${#status_checks_arr[@]} > 0 ]]
                then
                    rule_chunk+="${SPACER}The details about each status check can be seen below $br"
                    for status_check_json in "${status_checks_arr[@]}"
                    do
                        context=$(echo "$status_check_json" | jq -r '.context')
                        integration_id=$(echo "$status_check_json" | jq -r '.integration_id' )
                        if [[ $integration_id != null ]]
                        then
                            #TODO: Make a status check in the rule that has an integration ID (some dummy action or something)
                            # Make sure you update the all-restrictions-example.json accordingly!
                            [[ $VERBOSE == "true" ]] && echo "context =${SPACER}${SPACER}- Name: ${context} | Integration ID: ${integration_id}"
                        else
                            rule_chunk+="context =${SPACER}${SPACER}- Name: ${context} | Integration ID: any source $br"
                        fi
                    done
                fi
                # exit
            elif [[ "$rule_json_type" == "code_scanning" ]]
            then
                mapfile -t scanning_tools_arr < <(echo "$rule_json_parameters" | jq -c '.code_scanning_tools // [] | .[]')
                rule_chunk+="The required tools and their thresholds are listed below: $br"
                # Table formatting 
                rule_chunk+="| Tool Name | Security Alerts Threshold | Alerts Threshold |"
                for scanning_tool_json in "${scanning_tools_arr[@]}"
                do
                    tool=$(echo "$scanning_tool_json" | jq -r '.tool')
                    security_alerts_threshold=$(echo "$scanning_tool_json" | jq -r '.security_alerts_threshold' | sed 's/_/ /g' | sed 's/^./\U&/')
                    alerts_threshold=$(echo "$scanning_tool_json" | jq -r '.alerts_threshold' | sed 's/_/ /g' | sed 's/^./\U&/')
                    [[ $VERBOSE == "true" ]] && echo "| ${tool} | ${security_alerts_threshold} | ${alerts_threshold} |"
                done
                exit
            elif [[ "$rule_json_type" == "copilot_code_review" ]]
            then
                echo "TBD"
            fi
        fi # End if parameters JSON != null
    done
}

get_rule_description()
{
    # Given a rule_type, return a detailed description of the rule (rule_desc)
    # TODO: Where it says 'Do something' of 'Figure this out' that means make another method to deal w parameters JSON and account for this part
    rule_type=$1
    rule_desc="" # A detailed description of the rule
    # echo "get_rule_description() firing! rule_type = '$rule_type'"
    begin_desc="If this check is enabled,"
    case "${rule_type}" in
    "deletion" | "creation" | "update")
        if [[ ! "update" = "$rule_type" ]]
        then
            # Replace 'ion' with e (ex. creation --> create)
            verb=$( echo "$rule_type" | sed 's/ion/e/')
        else
            verb="$rule_type"
        fi
        rule_desc="${begin_desc} only users with bypass permissions can ${verb} branches or tags whose name matches the pattern(s) specified."
        ;;
    "non_fast_forward")
        # TODO: Fill this out
        rule_desc="${begin_desc} TBD"
        ;;
    "required_linear_history")
        rule_desc="A required linear history prevents collaborators from pushing merge commits to the targeted branches or tags. This means that any pull requests merged into the branch or tag must use a squash merge or a rebase merge. A strictly linear commit history can help teams revert changes more easily."
        rule_desc+="<br>For this logic to work, your repository must allow squash merging or rebase merging. Check the 'Settings --> General --> Pull Requests' section to ensure this is the case."
        ;;
    "merge_queue")
        #Note: Has parameters JSON. Done.
        rule_desc="This ruleset uses a merge queue. For more information on how merge queues work and their benefits see [relevant documentation] (https://docs.github.com/en/enterprise-cloud@latest/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request-with-a-merge-queue#about-merge-queues)"
        ;;
    "required_deployments")
        #TODO: Fill this out ON HOLD (see third TODO about deployment environment)
        #TODO: Has parameters JSON with one key that is an array. Do something.
        #TODO: Also need a deployment environment in repo for this to really work.
        echo "TODO"
        ;;
    "required_signatures")
        rule_desc="Required commit signing on a branch means that contributors and bots can only push commits that have been signed and verified to the branch."
        rule_desc+="<br>*Please note: This activity differs somewhat between rulesets and branch protection rules. Please see the [relevant documentation] (https://docs.github.com/en/enterprise-cloud@latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-signed-commits) for more details.*"
        ;;
    "pull_request")
        #TODO: Has parameters JSON with several keys, "allowed_merge_methods" is an array. PRELIM Done.
        echo "Require all commits be made to a non-target branch and submitted via a pull request before they can be merged."
        ;;
    "required_status_checks")
        #TODO: Has parameters JSON with several keys, "required_status_checks" is a JSON array. Need a status check with a real ID to fully test this.
        # Note: Paraphrased from ruleset page
        rule_desc="${begin_desc} certain status checks must pass before the ref is updated. Associated commits must first be pushed to another ref where the checks pass."
        ;;
    "code_scanning")
        # Note: Text in parentheses paraphrased from 'About code scanning' Github documentation page 
        rule_desc="${begin_desc} selected tools must provide code scanning results before the reference is updated. (Code scanning analyzes the code in a GitHub repository to determine security vulnerabilities and coding errors.) When configured, code scanning must be enabled and have results for both the commit and the reference being updated."
        ;;
    "copilot_code_review")
        #TODO: Has parameters JSON. Do something
        echo "${begin_desc} Copilot code review for new pull requests will be automatically requested if the author has access to Copilot code review."
        ;;
    esac
    # echo "rule_desc = $rule_desc"
    echo "${rule_desc}"
}

get_ruleset_page_name()
{
    #TODO: Could this be merged with get_addl_details to make a json with keys that point to these strings instead? Would it be faster?
    rule_type=$1
    desc=$2
    ruleset_page_name=""
    if [[ "$rule_type" == "merge_queue" ]]
    then 
        case "${desc}" in
            "Merge method")
                ruleset_page_name="${desc}" #mq_desc and page name are the same
                ;;
            "Max entries to build")
                ruleset_page_name="Build concurrency"
                ;;
            "Min entries to merge")
                ruleset_page_name="Minimum group size"
                ;;
            "Max entries to merge")
                ruleset_page_name="Maximum group size"
                ;;
            "Min entries to merge wait minutes")
                ruleset_page_name="Wait time to meet minimum group size (minutes)"
                ;;
            "Grouping strategy")
                ruleset_page_name="Require all queue entries to pass required checks"
                ;;
            "Check response timeout minutes")
                ruleset_page_name="Status check timeout (minutes)"
                ;;
        esac
    elif [[ "$rule_type" == "pull_request" ]]
    then
        case "${desc}" in
            "Required approving review count")
                ruleset_page_name="Required approvals"
                ;;
            "Dismiss stale reviews on push")
                ruleset_page_name="Dismiss stale pull request approvals when new commits are pushed"
                ;;
            "Require code owner review")
                ruleset_page_name="Require review from Code Owners"
                ;;
            "Require last push approval")
                ruleset_page_name="Require approval of the most recent reviewable push"
                ;;
            "Required review thread resolution")
                ruleset_page_name="Require conversation resolution before merging"
                ;;
            "Automatic copilot code review enabled")
                ruleset_page_name="Automatically request Copilot code review"
                ;;
            "Allowed merge methods")
                ruleset_page_name="Allowed merge methods"
                ;;
        esac
    elif [[ "$rule_type" == "required_status_checks" ]]
    then
        case "${desc}" in
            "Strict required status checks policy")
                ruleset_page_name="Require branches to be up to date before merging"
                ;;
            "Do not enforce on create")
                ruleset_page_name="Do not require status checks on creation"
                ;;
        esac
    elif [[ "$rule_type" == "copilot_code_review" ]]
    then
        case "${desc}" in
            "Review on push")
                ruleset_page_name="Review new pushes"
                ;;
            "Review draft pull requests")
                ruleset_page_name="${desc}"
                ;;
        esac
    fi
    echo "${ruleset_page_name}"
}

get_addl_details()
{
    rule_type=$1
    desc=$2
    addl_details=", "
    if [[ "$rule_type" == "merge_queue" ]]
    then
        case "$desc" in
            "Merge method")
                addl_details="Method to use when merging changes from queued pull requests."
                ;;
            "Max entries to build")
                #TODO: What is this actually saying
                addl_details+="Limit the number of queued pull requests requesting checks and workflow runs at the same time."
                ;;
            "Min entries to merge")
                addl_details+="The minimum number of PRs that will be merged together in a group."
                ;;
            "Max entries to merge")
                addl_details+="The maximum number of PRs that will be merged together in a group."
                ;;
            "Min entries to merge wait minutes")
                addl_details+="The time merge queue should wait after the first PR is added to the queue for the minimum group size to be met. After this time has elapsed, the minimum group size will be ignored and a smaller group will be merged."
                ;;
            "Grouping strategy")
                addl_details+="When this setting is disabled, only the commit at the head of the merge group, i.e. the commit containing changes from all of the PRs in the group, must pass its required checks to merge."
                ;;
            "Check response timeout minutes")
                addl_details="Maximum time for a required status check to report a conclusion. After this much time has elapsed, checks that have not reported a conclusion will be assumed to have failed."
                ;;
        esac
    elif [[ "$rule_type" == "pull_request" ]]
    then
        case "${desc}" in
            "Required approving review count")
                addl_details="The number of approving reviews that are required before a pull request can be merged."
                ;;
            "Dismiss stale reviews on push")
                addl_details="New, reviewable commits pushed will dismiss previous pull request review approvals."
                ;;
            "Require code owner review")
                addl_details="Require an approving review in pull requests that modify files that have a designated code owner."
                ;;
            "Require last push approval")
                addl_details="Whether the most recent reviewable push must be approved by someone other than the person who pushed it."
                ;;
            "Required review thread resolution")
                addl_details="All conversations on code must be resolved before a pull request can be merged."
                ;;
            "Automatic copilot code review enabled")
                addl_details="Request Copilot code review for new pull requests automatically if the author has access to Copilot code review."
                ;;
            "Allowed merge methods")
                # Note: This ISN'T from the ruleset page, but paraphrased from it.
                addl_details="The allowed methods a pull request can be performed. One must always be enabled."
                ;;
        esac
    elif [[ "$rule_type" == "required_status_checks" ]]
    then
        case "${desc}" in
            "Strict required status checks policy")
                addl_details="If true, pull requests targeting a matching branch must be tested with the latest code. This setting will not take effect unless at least one status check is enabled."
                ;;
            "Do not enforce on create")
                addl_details="If true, allow repositories and branches to be created if a check would otherwise prohibit it."
                ;;
        esac
    elif [[ "$rule_type" == "copilot_code_review" ]]
    then
        case "${desc}" in
            "Review on push")
                addl_details="Copilot automatically reviews each new push to the pull request."
                ;;
            "Review draft pull requests")
                addl_details="Copilot automatically reviews draft pull requests before they are marked as ready for review."
                ;;
        esac
    fi
    echo "${addl_details}"
}

if [[ "$GET_RULES_FOR" == 'all branches with rules' ]]
then
    #TODO: Descriptor section
    descriptor="Details about rules are generally formatted in the following way ([Name of item as it appears on the Rulesets page UI]) ([Name of JSON key for ruleset item] [Additonial details about that item])"
    for id in "${ruleset_ids[@]}"
    do
        # echo "Branch ruleset id: $id"
        
        # Get the JSON for a particular rule
        ruleset_json=$(gh api /repos/org-mushroom-kingdom/bash-git-script/rulesets/$id -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $REPO_READ_TOKEN") 
        # echo "$ruleset_json"
        
        # Example of how to filter a single JSON for the desired values (ex. original JSON returns things like id, source_type, etc) 
        # This essentially creates a new JSON (note the {})
        # The 'effected_branches:' syntax creates a key called 'effected_branches' in the new JSON. 
        # In ruleset_json, 'conditions' key has a JSON value. The 'ref_name' key in THAT JSON is another JSON. 'include' is a key (with an array value) in the ref_name JSON.
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