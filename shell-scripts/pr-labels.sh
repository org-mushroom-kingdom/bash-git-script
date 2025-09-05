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
# Given a PR number from test-pr-action
pr_number=$1
echo "pr-labels.sh says: pr_number = $pr_number" 