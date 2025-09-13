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

# Use cut to split a string based upon a delimiter. -d specifies the delimiter (here an empty space)
# A CODEOWNERS line is generally in the format of "/some/file/path/* @owner"
# So splitting on ' ' works 
# for line in "${codeowners_lines[@]}"
# do
#     # echo "line = $line"
#     filepath=$(echo "$line" | cut -d' ' -f1)
#     owner=$(echo "$line" | cut -d ' ' -f2)
#     # echo "filepath = $filepath"
#     # echo "owner = $owner"
# done

#TODO: TEST THIS WITH A RUN HERE
# Make an array out of the comma-delimited string (ex. "/shell-scripts/*.sh,/images" becomes ["/shell-scripts/*.sh","/images"])
IFS="," changed_file_list=($CHANGED_FILES_STR)
echo "changed_file_list[0] = ${changed_file_list[0]}"

# Early exit DELETE THIS WHEN DONE TESTING
# exit

#Examples of changed_file_path = .github/workflows/test-pr-action-2.yml, README.md, shell-scripts/info.txt
# Using .github/workflows/test-pr-action-2.yml as an example...
# Split the path into strings via / ? Or maybe use cut and regex.
# First see if '.github' or '.github/' or '.github/*' is in CODEOWNERS
# A. If it is can mark in_codeowners as true (exit early?)
# B. If not, do nothing
# If B Then see if '.github/workflows' or '.github/workflows/*' is in CODEOWNERS
# A/B (see above)
# If B then do the whole filepath   

# Look at each changed file and do the following:
# Split the path into an array of strings (file_path_segs) (ex. "docs/other" becomes ['docs','other']) --> IFS probably
# For each file_path_seg:
# 1. see IF the line in codeowners_lines is an exact match (rare is the occassion)
# 2. ELIF not an exact match, see if partial match TODO: FIGURE THIS OUT
for changed_file_path in changed_file_list
  #Examples of changed_file_path = .github/workflows/test-pr-action-2.yml, README.md, shell-scripts/info.txt
  # Bash doesn't have native boolean datatypes, so we use strings
  in_codeowners="false"
    #TODO instead of how this currently is, establish an array of objects/hashes like {'filepath' : 'owner'} 
    for line in "${codeowners_lines[@]}"
    do
        # echo "line = $line"
        filepath=$(echo "$line" | cut -d' ' -f1)
        owner=$(echo "$line" | cut -d ' ' -f2)
        # echo "filepath = $filepath"
        # echo "owner = $owner"
        #
        # if [[  ]]

    done
done

# echo "read-thru-codeowners says var = $CHANGED_FILES_STR"