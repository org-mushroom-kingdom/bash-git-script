#!/bin/bash

# Try to use Github CLI to add labels to a PR...

# gh auth login

# Get the members of a team
# gh api \
# --method GET \
# -H "Accept: application/vnd.github+json" \
# -H "X-GitHub-Api-Version: 2022-11-28" \
# /orgs/org-mushroom-kingdom/teams/team-peach/members

# Add labels to PR based on target branch

# We can reference $PR_NUMBER from test-pr-action 
echo "pr-labels.sh says: pr_number = ${PR_NUMBER}"
# Given the PR and target branch  

echo "Target branch = ${TARGET_BRANCH} ."

LABEL=$(echo "$TARGET_BRANCH" | cut -d'/' -f2)
echo "LABEL = $LABEL"
if [[ "${TARGET_BRANCH}" == "env/dev" ]]
then
    echo 'label adding logic for label 'dev' here!'
    gh pr edit "$PR_NUMBER" --add-label 'dev'
elif [[ "${TARGET_BRANCH}" == "env/qa1" ]]
then
    gh pr edit "$PR_NUMBER" --add-label 'qa1'
fi