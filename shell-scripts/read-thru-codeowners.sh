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
# 1. See IF the line in codeowners_lines is an exact match (rare is the occassion)
# 2?. See IF almost a match? (See if CODEOWNERS path is everything but the file/extension? ex. docs/other/sub1/) 
# ELIF not an exact match Split the path into an array of strings (file_path_segs) (ex. "docs/other" becomes ['docs','other']) --> IFS probably
#
# For each file_path_seg: (Or WHILE )
# 2. See if partial match TODO: FIGURE THIS OUT
#   FOR example if a changed file is docs/other/sub1/dummy-txt1.txt
    # See if the CODEOWNERS filepath == "docs/"
    # If it is don't add to is_in_codeowners, exit early
    # If it isn't go to next iteration and check again (ex. is CODEOWERNS filepath == "docs/other/")
    # Repeat this until end of loop is reached. If still no matches, add to is_not_in_codeowners string
# 
for changed_file_path in changed_file_list
  #Examples of changed_file_path = .github/workflows/test-pr-action-2.yml, README.md, shell-scripts/info.txt, sandbox/other/sub_a/Jenkinsfile
  # Bash doesn't have native boolean datatypes, so we use strings
  in_codeowners="false"
  files_not_in_codeowners=""
    #TODO instead of how this currently is, establish an array of objects/hashes like {'filepath' : 'owner'} 
    for line in "${codeowners_lines[@]}"
    do
        # echo "line = $line"
        codeowners_filepath=$(echo "$line" | cut -d' ' -f1)
        owner=$(echo "$line" | cut -d' ' -f2)
        # echo "filepath = $filepath"
        # echo "owner = $owner"
        #
        # if [[ "$codeowners_filepath" == "$changed_file_path" ]]
        # then
        #   in_codeowners=true
        #   break
        # else
            # TODO: Any line below that begins with !-- is experimental. Try messing with it after you can do the initial granular search
            # !-- # Use rev to reverse the c_filepath, do a cut f2 to get the "super" directory, do another rev to unreverse cut piece 
            # !-- # Ex. If the path is sandbox/other/sub1/dummy-txt1.txt, then look to see if "sandbox/other/sub_a/" is a path 
            # !-- changed_file_path_lastDir=$(echo "$changed_file_path" | rev | cut -d '/' -f2 | rev)
            # !-- If [[ "$codeowners_filepath" == "$changed_file_path_lastDir" ]]
            
            # TODO: This logic at the moment doesn't account for extensionless files really, or if it does it does it crappily
            
            # If the path is a top-level file don't do anything else? (ex. test-json-output.txt)
            # is_top_level_file="false"
            # If cutting the path using / results in only two pieces...
            # if 
            
            # Perform the granular search
            # changed_file_path_segs = the changed_file_path (string) broken into an array of strings using / as delim
            # ex. sandbox/other/sub2/dummy-txt2.txt becomes ["sandbox","other","sub1","dummy-txt1.txt"]
            # There may not be a specific owner for the file, but there may be an owner for sandbox/other/sub2 (Hint: there is)
            # So we should look to see if there is an owner for the directory above us, but really anything above that too (ex. If someone owned sandbox/other they own all subdirectories in it)
            
            #TODO: Need a better name for this...
            # IFS='/' changed_file_path_segs=($changed_file_path) 
            
            # Making a str arr with IFS will omit the delim, so let's add it back in
            # TODO: We don't want to do this for the last element, because it may already have a slash or a slash isn't applicable (i.e. a file)
            # TODO: Figure out a better way to map
            # for ((i=0; i<="${#changed_file_path_segs[a]}"-2; i++)); do changed_file_path_segs[i]+="/"; done
            # changed_file_path_collective=""
            # changed_file_path_collective="${#changed_file_path_segs[0]}" # (ex. "sandbox/")

            # Add seg to changed_file_path_collective, then see if that path is in CODEOWNERS (ex. "sandbox/" --> "sandbox/other/" --> "sandbox/other/sub2/" ...) 
            # for seg in changed_file_path_segs
            # do
            #   changed_file_path_collective+="$seg"
            #   if [[ "$filepath" == "$changed_file_path" ]]
            #   then
            #       in_codeowners=true
            #       break
            #   fi
            # done
        # fi

    done
    # If not in CODEOWNERS, add to 
    if [[ "$in_codeowners" == "false" ]]
    then 
        files_not_in_codeowners+="${changed_file_path},"
    fi
done

# Remove the last comma
# files_not_in_codeowners="${files_not_in_codeowners%,}"
# echo $files_not_in_codeowners

# Use this stuff below to test other vars
# echo "read-thru-codeowners says var = $CHANGED_FILES_STR"