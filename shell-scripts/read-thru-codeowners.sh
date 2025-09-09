#!/bin/bash

# This is its own separate script for a couple of reasons:
# 1. As an example of how a script can be called from another script (main-script.sh calls this one)
# 2. As an example of how to call a script from Github Actions
# 3. Some third reason TBD


# This is called from the test-pr-action. It depends the following variables being defined in the action
# TARGET_BRANCH, PR_NUMBER, ORG

echo "read_thru_codeowners.sh was hit!"


#Open/Get CODEOWNERS via Github CLI/Github API
# Get filepath (in PR), see if path is in 
gh api repos/${REPO_PATH}/contents/.gitignore/CODEOWNERS