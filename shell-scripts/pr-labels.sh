#!/bin/bash

# This uses the Github CLI and Github API to add labels to a PR based on
# - The target branch of the PR (the branch being merged into)
# - The teams the user is a part of

# It depends on being passed the following variables
# TODO: PUT THE VARIABLES

# gh auth login

# Get the members of a team
# gh api \
# --method GET \
# -H "Accept: application/vnd.github+json" \
# -H "X-GitHub-Api-Version: 2022-11-28" \
# /orgs/org-mushroom-kingdom/teams/team-peach/members

#TODO: Idea--spin off this script and a corresponding action that does the following and put it into Marketplace:
# Searches through all organization teams for a member/PR creator
# For each hit, add corresponding team label to string or array
# Use string/array to add labels to the PR
# 

declare -a TEAM_LABEL_LIST=()

# This gives a JSON array of teams, which we want the value that corresponds to the 'name' key
# Use \ to split the command into multiline
# This is an example of using Github CLI (with jq) to call the Github API

# Use jq command line tool to process JSON: Bash jq is like sed for JSON. map(.name) takes the value of each JSON's 'name' key and throws it into array
#TODO: don't hard code org name, use an ORG var in test-pr-action/other actions and pass it in that way. Make sure to Ctrl+F for org-mushroom-kingdom and update all refs
# TEAM_NAMES=$(gh api \
# -H "Accept: application/vnd.github+json" \
# -H "X-GitHub-Api-Version: 2022-11-28" \
# -H "Authorization: Bearer $TEAMS_READ_TOKEN" \
# orgs/$ORG/teams)
# orgs/$ORG/teams | jq 'map(.name)')

# Had to use AI to help me come up with a solution but you can bet damn well I'm not going to use something without figuring out how it works. Cue long explanation

# Use gh api command orgs/$ORG/teams to get a JSON array of teams (as output--this is important for later), which has various team info. We only want the name, so...
# Use jq command line tool to process JSON: Bash jq is like sed for JSON.
# Pipe with 'jq .[].slug' which breaks down to: 
# -r = use raw output (uses raw output instead of JSON strings which are wrapped in double quotes. ex. without -r --> "team-luigi" would be an output. WITH -r it would be team-luigi (no quotes) )
# . = filter for current JSON (result of gh api). If we just did jq . it would give the output of the JSON array (though it looks a little different when testing with the Actions page vs gh api with no jq present)
# [] = iterate thru each element of JSON array and give a separate output for each
# .slug = filter for just the 'slug' value (return just the team slug instead of the whole team JSON)

# At this point let's say you have 3 separate outputs which doesn't translate well for usability (ex. "team-mario" "team-luigi" "team-peach")
# mapfile command to read lines from stdinput or a file and assign each line an index of an array (TEAM_NAMES)
# Specifically mapfile syntax is 'mapfile [options (ex. -t to rmv trailing newlines)] [array_variable] < [some input with lines (ex. a file)]' 

# Mapfile reads input, but we have OUTPUT from the jq command (really 3 separate outputs)
# To translate our output into input we need to feed the output of jq as input. To do this use process substituion
# Process substitution allows commands that normally accept input to consume the output of other commands by treating the output as a file
# Specifically <(gh api...) takes the output of gh api and treats it as a multiline file (more or less)
# mapfile then "thinks" <(gh api...) is a file/input and takes each line (formerly separate outputs) and puts each line as element in indexed array
mapfile -t TEAM_NAMES < <(gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -H "Authorization: Bearer $TEAMS_READ_TOKEN" orgs/$ORG/teams | jq -r '.[].slug')
# gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -H "Authorization: Bearer $TEAMS_READ_TOKEN" orgs/$ORG/teams | jq '.[]'

# echo "TEAMS = ${TEAM_NAMES[@]}"
# echo "repo owner = $ORG"

# echo "TEAM_NAMES[0] = ${TEAM_NAMES[0]}"
# TODO: fxn? Name something like add_team_labels
# For each team, look to see if $PR_CREATOR is a part of that team
# By getting the members of that team (array), then seeing if $PR_CREATOR is in that array

# team="team-peach"
# gh api --method GET \
#     -H "Accept: application/vnd.github+json" \
#     -H "X-GitHub-Api-Version: 2022-11-28" \
#     -H "Authorization: Bearer $TEAMS_READ_TOKEN" \
#      orgs/$ORG/teams/${team}/members
     
# Temp exit. DELETE THIS WHEN TESTING COMPLETE!
# echo "Temporarily Early exit."
# exit
for team in "${TEAM_NAMES[@]}"
do
    # There is no Github API endpoint that does logic like 'get all teams a user is in', so we must come up with our own way.
    # Use jq to get array of usernames in that team
    # Issue: $team doesn't return one team, it returns the whole array. Why?
    echo "team = $team"
    
    echo "URL TO USE: orgs/$ORG/teams/${team}/members"
    # Use the same mapfile/process substitution approach as above to get array of usernames in team
    mapfile -t TEAM_MEMBERS < <(gh api --method GET \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Authorization: Bearer $TEAMS_READ_TOKEN" \
     orgs/$ORG/teams/${team}/members | jq -r '.[].login')
    
    echo -e "\nMembers of team ${team}:\n" 
    # printf is basically an enhanced version of echo. Still writes to stdout. 
    # %s=take arg as string, \\n = newline. So print the string, then a newline. 
    # [@] expands the array so each element is a separate word. Each element/word is considered a separate argument for printf
    printf "%s\\n" "${TEAM_MEMBERS[@]}"

    # Loop thru the members of a team. If the PR_CREATOR == username in team, add the corresponding team label
    # ex. [team-mario would be ["mcummings128"], team-peach would be ["mcummings128","mcummings129"]
    for username in "${TEAM_MEMBERS[@]}"
    do
        if [[ "${username}" == "{$PR_CREATOR}" ]]
        then
            # Assuming team name is same as label name, add to array (+=)
            TEAM_LABEL_LIST+=($team)
            #   Let's say it wasn't though. Like team-luigi has a corresponding 'luigi' label
            #   Or there's a 'bowser' team with no 'team-' prefix
            #   Probably have some sort of JSON or csv file where headers are team, labels
            #   So if username=$PR_CREATOR, then look at $team in JSON/csv and get corresponding value 
        fi
    done
done


# gh api --method GET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/org-mushroom-kingdom/teams/team-peach/members
# echo -e "team-peach members below: \n"
# gh api --method GET -H "Authorization: Bearer $TEAMS_READ_TOKEN"  /orgs/org-mushroom-kingdom/teams/team-peach/members

# Loop thru TEAM_LABEL_LIST and add all the labels
for team_label in "${TEAM_LABEL_LIST[@]}"
do
    echo "team_label = ${team_label}"
    # gh pr edit "$PR_NUMBER" --add-label "$team_label"
done

# Temp exit. DELETE THIS WHEN TESTING COMPLETE!
echo "Temporarily Early exit."
exit
# Add labels to PR based on target branch

# We can reference $PR_NUMBER from test-pr-action 
echo -e "\n pr-labels.sh says: pr_number = ${PR_NUMBER}"
# Given the PR and target branch  

echo "Target branch = ${TARGET_BRANCH} ."

#TODO: fxn? Name like add_branch_labels
# Assume all environment branches begin with env. Use cut and -d for delimiter, with / being the delimiter. Get the 2nd piece of that cut (stuff after /)
# Also assume that env labels are just the name of the environment branch after the / (ex. env/dev has corresponding 'dev' label)
env_label=$(echo "$TARGET_BRANCH" | cut -d'/' -f2)
echo "env_label = $env_label"

if [[ "${TARGET_BRANCH}" == "env/dev" || "${TARGET_BRANCH}" == "env/qa1" ]]
then
    gh pr edit "$PR_NUMBER" --add-label "$env_label"
fi