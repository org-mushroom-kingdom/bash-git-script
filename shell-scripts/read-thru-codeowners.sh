#!/bin/bash

# This is its own separate script for a couple of reasons:
# 1. As an example of how a script can be called from another script (main-script.sh calls this one)
# 2. As an example of how to call a script from Github Actions
# 3. Some third reason TBD


# This is called from the test-pr-action. It depends the following variables being defined in the action
# TARGET_BRANCH, PR_NUMBER, ORG, CHANGED_FILES_STR

# echo "read_thru_codeowners.sh was hit!"


declare -a codeowners_raw_lines # String arr with ALL lines from CODEOWNERS
declare -a codeowners_lines # String arr mapped from above, only lines that aren't comments (or empty)

#Open/Get CODEOWNERS via Github CLI/Github API

CHANGED_FILE_STR=$1 #or $CHANGED_FILES_STR

# gh api repos/${REPO_PATH}/contents/.gitignore/CODEOWNERS | jq -r '.content' | base64 --decode 
# gh api cmd here gives a million outputs, so use mapfile to put them in arr
mapfile -t codeowners_raw_lines < <(gh api repos/${REPO_PATH}/contents/.gitignore/CODEOWNERS | jq -r '.content' | base64 --decode )

# Get filepath (in PR), see if path is in 

# echo "codeowners_raw_lines[0] = ${codeowners_lines[0]}"
# echo "codeowners_raw_lines[1] = ${codeowners_lines[1]}"

# Filter out the comments in the array (essentially this is array mapping)
# Filter out lines that begin with # or are empty (use ${#line} to assess string length)
for line in "${codeowners_raw_lines[@]}"
do
    if [[ ${#line} -gt 0 && "${line}" != "#"* ]]
    then
        # echo "LINE! ${line}"
        codeowners_lines+=($line)
    fi
done

# echo "${codeowners_lines[1]}"

# for line in "${codeowners_lines[@]}"
# do
#     # echo "line = $line"
#     filepath=$(echo "$line" | cut -d' ' -f1)
#     owner=$(echo "$line" | cut -d ' ' -f2)
#     # echo "filepath = $filepath"
#     # echo "owner = $owner"
# done

# for changed_filename in changed_file_list
#   in_codeowners=false
#     for line in "${codeowners_lines[@]}"
#     do
#         # echo "line = $line"
#         filepath=$(echo "$line" | cut -d' ' -f1)
#         owner=$(echo "$line" | cut -d ' ' -f2)
#         # echo "filepath = $filepath"
#         # echo "owner = $owner"
#     done
# done

echo "read-thru-codeowners says var = $CHANGED_FILES_STR"