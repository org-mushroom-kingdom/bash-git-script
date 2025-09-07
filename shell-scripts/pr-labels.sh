#!/bin/bash

# Try to use Github CLI to add labels to a PR...

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

declare -a LABEL_LIST=()

# This gives a JSON array of teams, which we want the value that corresponds to the 'name' key
# Use \ to split the command into multiline
# Use jq command line tool to process JSON: Bash jq is like sed for JSON. map(.name) takes the value of each JSON's 'name' key and throws it into array
# This is an example of using Github CLI (with jq) to call the Github API

#TODO: don't hard code to org name, use an ORG var in test-pr-action and pass it in that way. Make sure to Ctrl+F for org-mushroom-kingdom and update all refs
TEAM_NAMES=$(gh api \
-H "Accept: application/vnd.github+json" \
-H "X-GitHub-Api-Version: 2022-11-28" \
-H "Authorization: Bearer $TEAMS_READ_TOKEN" \
orgs/org-mushroom-kingdom/teams | jq 'map(.name)')

echo "TEAMS = $TEAM_NAMES"

# For each team, look to see if $PR_CREATOR is a part of that team
# By getting the members of that team (array), then seeing if $PR_CREATOR is in that array
# for team in "${TEAM_NAMES[@]}"
# do
#   Use jq to get array of usernames in that team
#   TEAM_MEMBERS=$(gh api \
#   -H "Accept: application/vnd.github+json" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   -H "Authorization: Bearer $TEAMS_READ_TOKEN"  \
#   /orgs/org-mushroom-kingdom/teams/$team/members | jq 'map(.login)')

# ex. [team-mario would be ["mcummings128"], team-peach would be ["mcummings128","mcummings129"]
# for username in "${TEAM_MEMBERS[@]}"
# do
#   if [[ "${username}" == "{$PR_CREATOR}"" ]]
#   then
#       # Assuming team name is same as label name...
#       LABEL_LIST+=($team)
#       Let's say it wasn't though. Like team-luigi has a corresponding 'luigi' label
#       Or there's a 'bowser' team with no 'team-' prefix
#   done
# done

# gh api --method GET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/org-mushroom-kingdom/teams/team-peach/members
echo -e "team-peach members below: \n"
gh api --method GET -H "Authorization: Bearer $TEAMS_READ_TOKEN"  /orgs/org-mushroom-kingdom/teams/team-peach/members


# Add labels to PR based on target branch

# We can reference $PR_NUMBER from test-pr-action 
echo -e "\n pr-labels.sh says: pr_number = ${PR_NUMBER}"
# Given the PR and target branch  

echo "Target branch = ${TARGET_BRANCH} ."

env_label=$(echo "$TARGET_BRANCH" | cut -d'/' -f2)
echo "env_label = $env_label"

if [[ "${TARGET_BRANCH}" == "env/dev" || "${TARGET_BRANCH}" == "env/qa1" ]]
then
    gh pr edit "$PR_NUMBER" --add-label "$env_label"
fi