#!/bin/bash

# Try to use Github CLI to add labels to a PR...

# gh auth login

gh api \
--method GET \
-H "Accept: application/vnd.github+json" \
-H "X-GitHub-Api-Version: 2022-11-28" \
/orgs/org-mushroom-kingdom/teams/team-peach/members