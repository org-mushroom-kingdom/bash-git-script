#!/bin/bash

# This is its own separate script for a couple of reasons:
# 1. As an example of how a script can be called from another script (main-script.sh calls this one)
# 2. As an example of how to call a script from Github Actions (test-pr-action-2.yml calls this)
# 3. Some third reason TODO: Elaborate


# This is called from the test-pr-action. It depends the following variables being defined in the action
# TARGET_BRANCH, PR_NUMBER, ORG, CHANGED_FILES_STR, REPO_PATH

# echo "read_thru_codeowners.sh was hit!"


declare -a codeowners_raw_lines # String arr with ALL lines from CODEOWNERS
declare -a codeowners_lines # String arr mapped from above, only lines that aren't comments (or empty)
total_output="" #Experimental. Build on this so the Action can spit out everything?
CHANGED_FILE_STR=$1 #or $CHANGED_FILES_STR


# gh api cmd here gives a million outputs, so use mapfile to put them in arr
# Github API contents endpoint has a 'content' key whose value is in base 64, so use base64 --decode on it
# mapfile -t codeowners_raw_lines < <(gh api repos/${REPO_PATH}/contents/.gitignore/CODEOWNERS | jq -r '.content' | base64 --decode )

# DELETE THIS! For Git Bash testing
# Get the CODEOWNERS file
FILE_PATH="./.github/CODEOWNERS"
# echo $PWD
# exec cat .gitignore
exec 7< .github/CODEOWNERS
mapfile -u 7 codeowners_raw_lines
echo "codeowners_raw_lines[0] = ${codeowners_lines[0]}"
exec 7&-
exit
# END DELETE THIS!!
# Comment out the above mapfile line, and comment in the line below to see the output
# gh api repos/${REPO_PATH}/contents/.gitignore/CODEOWNERS | jq -r '.content' | base64 --decode 

# Comment in these lines to see specific values of the array created by mapfile 
# echo "codeowners_raw_lines[0] = ${codeowners_lines[0]}"
# echo "codeowners_raw_lines[1] = ${codeowners_lines[1]}"

# Filter out the comments in the array or are empty (essentially this is array mapping) (use ${#line} to assess string length)

# COMMENT ME BACK IN 
# for line in "${codeowners_raw_lines[@]}"
# do
#     if [[ ${#line} -gt 0 && "${line}" != "#"* ]]
#     then
#         # echo "LINE! ${line}"
#         codeowners_lines+=($line)
#     fi
# done

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
# IFS="," changed_file_list=($CHANGED_FILES_STR)
# echo "changed_file_list[0] = ${changed_file_list[0]}"

# DELETE THIS! Use For testing from Bash
changed_file_list=("test-json-output.txt" "sandbox/other/sub_a/sub_b/Jenkinsfile" "sandbox/other/sub_a/sub_b/wordTypes-marioOnly.csv" "shell-scripts/say-hello.sh")

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
    # If it is don't add to in_codeowners, exit early
    # If it isn't go to next iteration and check again (ex. is CODEOWERNS filepath == "docs/other/")
    # Repeat this until end of loop is reached. If still no matches, add to is_not_in_codeowners string
# 
files_not_in_codeowners=""

for changed_file_path in changed_file_list
    #Examples of changed_file_path = .github/workflows/test-pr-action-2.yml, README.md, shell-scripts/info.txt, sandbox/other/sub_a/sub_b/Jenkinsfile
    # Bash doesn't have native boolean datatypes, so we use strings
    in_codeowners="false"
    
    #Use this to capture all output
    total_output+=$(echo -e "changed_file_path = $changed_file_path \n")
    
    #TODO instead of how this currently is, establish an array of objects/hashes like {'filepath' : 'owner'} ??
    
    # For each line in CODEOWNERS, search for the changed_file_path or other lines that would indicate ownership
    for line in "${codeowners_lines[@]}"
    do
        echo "line = $line"
        codeowners_filepath=$(echo "$line" | cut -d' ' -f1)
        owner=$(echo "$line" | cut -d' ' -f2)
        echo "codeowners_filepath = $codeowners_filepath"
        # echo "owner = $owner"
        # total_output+=$(echo -e "filepath = $codeowners_filepath \n")
        # total_output+=$(echo -e "owner = $owner \n")
        
        # Look for the whole path first to see if the file is specifically listed
        # Use / here to account for root
        if [[ "/${changed_file_path}" == "$codeowners_filepath" ]]
        then
          in_codeowners="true"
          echo "FOUND!"
          # Break out of inner loop/stop looking thru CODEOWNERS lines because we found a match
          break
        else
            # TODO: Any line below that begins with !-- is experimental. Try messing with it after you can do the initial granular search
            # !-- # Use rev to reverse the c_filepath, do a cut f2 to get the "super" directory, do another rev to unreverse cut piece 
            # !-- # Ex. If the path is sandbox/other/sub1/dummy-txt1.txt, then look to see if "sandbox/other/sub_a/" is a path 
            # !-- changed_file_path_lastDir=$(echo "$changed_file_path" | rev | cut -d '/' -f2 | rev)
            # !-- If [[ "$codeowners_filepath" == "$changed_file_path_lastDir" ]]
            
            # TODO: This logic at the moment doesn't account for extensionless files really, or if it does it does it crappily
            # TODO: Nor does it account for **/ logic
            # !-- If the path is a top-level file don't do anything else? (ex. test-json-output.txt)
            # !-- is_top_level_file="false"
            # !-- If cutting the path using / results in only 0?,1? pieces... 
            
            # ex test-json-output has no / in it, so results in 0
            # TODO: This should work but DOESN'T account for 'test-json-output.txt' as a line, which would account for ANY instance of 'text-json-output.txt' at ANY level
            # grep -o means "only matching" which prints only matching instances of the term, on separate output lines (so only print /) 
            # wc is word count which is used to count bytes/words/lines. The -l option prints only the newline counts (each output line = newline)
            num_of_slashes=$(echo "${changed_file_path}" | grep -o "/" | wc -l)
            if [ $num_of_slashes == 0 ]
            then
              in_codeowners="false"
              # Don't bother searching because we already tested for the full file path, and lack of / means this file is top-level (but not in CODEOWNERS)
              break
            fi
            # Perform the granular search
            # changed_file_path_segs = the changed_file_path (string) broken into an array of strings using / as delim
            # ex. sandbox/other/sub2/dummy-txt2.txt becomes ["//sandbox","other","sub1","dummy-txt1.txt"]
            # There may not be a specific owner for the file, but there may be an owner for sandbox/other/sub2 (Hint: there is)
            # So we should look to see if there is an owner for the directory above us, but really anything above that too (ex. If someone owned sandbox/other they own all subdirectories in it)
            
            IFS='/' changed_file_path_segs=($changed_file_path) 
            # Add / to beginning of file path (first element) to match how CODEOWNERS is written (first / indicates root)
            # Also add terminating / to account for subfolders
            changed_file_path_segs[0]="/${changed_file_path_segs[0]}/"
            
            # Making a str arr with IFS will omit the delim, so let's add it back in
            # Initialize at i=1 because we just took care of first element
            # Use -2 as loop terminal condition b/c We don't want to do this for the last element, because a slash isn't applicable (i.e. because it's a file)
            if [[ ${#changed_file_path_segs[@]} -ge 3 ]]
            then
                for ((i=1; i<="${#changed_file_path_segs[@]}"-2; i++)); do changed_file_path_segs[i]+="/"; done
            fi
            
            

            # TODO: Figure out a better way to map
            # changed_file_path_collective=""
            
            # Clone to be safe for now
            # You can't simply do '=$changed_file_path_segs'. To clone an array, you need to use [@] which treats every element as a single word/string
            # Use double quotes to ensure every string stays intact (ex. without "" ["hello world", "goodbye"] becomes ["hello" "world" "goodbye"])
            # Then you have to wrap in () so each string is made its own array element
            changed_file_path_segs_clone=("${changed_file_path_segs[@]}")
            for (( i="${#changed_file_path_segs[@]}"-1;i<0;i--))
            do
                # unset is used to unset variables and array elements (essentially deletes array element, like JS pop()). 
                # TODO: With arrays, if you added another index after you deleted one, the index will not be continuous. SHOW THIS IN MAIN-SCRIPT
                unset 'changed_file_path_segs_clone[${changed_file_path_segs_clone[@]}-1]'
                # Use IFS to join the arr to a string, with '' as the delimiter to preserve /'s
                changed_file_path_str=$(IFS='' ; echo ${changed_file_path_segs_clone[*]})
                if [[ "${changed_file_path_str}" == "$codeowners_filepath" ]]
                then
                    in_codeowners=true
                    echo "FOUND via segs!"
                    # Break out of inner-inner loop early because we got a match
                    break
                fi
            done # End seg-matching AKA inner-inner loop

            # Missy Elliot this and reverse it
            # ex. if path is sandbox/other/sub1/sub2/dummy-txt2.txt first search for sandbox/other/sub1/sub2/ --> sandbox/other/sub1/ --> sandbox/other
            # Pop last element part off segs (ex. first iteration would be popping off filename)
            # Join the rest together (with no delim to preserve /'s)
            # See if joined_line == codeowners_filepath
            # If not repeat the process: Pop last element off, join, see if joined_line == codeowners_filepath
            # Do this until i=0 


            # changed_file_path_collective="${#changed_file_path_segs[0]}" # (ex. "sandbox/")
            # Add seg to changed_file_path_collective, then see if that path is in CODEOWNERS (ex. "sandbox/" --> "sandbox/other/" --> "sandbox/other/sub1/" "sandbox/other/sub1/sub2" ...) 
            # for seg in changed_file_path_segs
            # do
            #   changed_file_path_collective+="$seg"
            #   if [[ "$filepath" == "$changed_file_path" ]]
            #   then
            #       in_codeowners=true
            #       # This break stops the 'for seg' loop
            #       break
            #   fi
            # done

            if [[ "$in_codeowners" == "true" ]]
            then
                # if in_codeowners is true (due to seg-matching loop above), exit inner loop early b/c we found a match
                break
            fi
        fi
    done # End for line in CODEOWNERS loop (AKA inner loop)
    
    # If not in CODEOWNERS, add to files_not_in_codeowners
    if [[ "$in_codeowners" == "false" ]]
    then 
        files_not_in_codeowners+="${changed_file_path},"
    fi
done #End for changed_file_path in changed_file_list

echo "$total_output"
# Remove the last comma TODO: % syntax elaborate
# files_not_in_codeowners="${files_not_in_codeowners%,}"
# echo $files_not_in_codeowners

# Use this stuff below to test other vars
# echo "read-thru-codeowners says var = $CHANGED_FILES_STR"