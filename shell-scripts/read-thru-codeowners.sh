#!/bin/bash

# This is its own separate script for a couple of reasons:
# 1. As an example of how a script can be called from another script (main-script.sh calls this one)
# 2. As an example of how to call a script from Github Actions
# 3. Some third reason TBD


# This is called from the test-pr-action. It depends the following variables being defined in the action
# TARGET_BRANCH, PR_NUMBER, ORG

# echo "read_thru_codeowners.sh was hit!"

declare -a codeowners_lines

#Open/Get CODEOWNERS via Github CLI/Github API


# gh api repos/${REPO_PATH}/contents/.gitignore/CODEOWNERS | jq -r '.content' | base64 --decode 
# gh api cmd here gives a million outputs, so use mapfile to put them in arr
mapfile -t codeowners_raw_lines < <(gh api repos/${REPO_PATH}/contents/.gitignore/CODEOWNERS | jq -r '.content' | base64 --decode )

# Get filepath (in PR), see if path is in 

# echo "codeowners_raw_lines[0] = ${codeowners_lines[0]}"
# echo "codeowners_raw_lines[1] = ${codeowners_lines[1]}"

# Filter out the comments in the array (essentially this is array mapping)
for line in "${codeowners_lines[@]}"
do
    if [[ "${line}" != "#"* ]]
    then
        codeowners_lines+=($line)
    fi
done

echo "${codeowners_lines[1]}"
# for line in "${codeowners_lines[@]}"
# do
#     filepath=
# done

