#!/bin/bash

# This is almost identical to read-thru-codeowners but makes it work locally via Git Bash (easier to test like this. 
# There's probs some workarounds one could do but Github Actions outputs isn't great when it comes to running a script and doing echo's)
# You won't see TODO


# This is the local version, so there's no reliance on variables defined by Github Actions.

readonly GREEN="\e[32m"
readonly COLOR_DONE="\e[0m"
declare -a codeowners_raw_lines # String arr with ALL lines from CODEOWNERS
declare -a codeowners_lines # String arr mapped from above, only lines that aren't comments (or empty)
total_output="" #Experimental. Build on this so the Action can spit out everything?
num_of_slashes=0
num_of_stars=0

# Everything in here is accounted for in CODEOWNERS except sandbox/not-in-codeowners/README.md
changed_file_list=("test-json-output.txt" "sandbox/other/sub_a/sub_b/Jenkinsfile" "sandbox/other/sub_a/sub_b/wordTypes-marioOnly.csv" "sandbox/other/sub1/dummy-script1.sh" "sandbox/other/sub_a/enemyTypes1.csv" "sandbox/not-in-codeowners/README.md")

echo -e "\n Going to search for the following files: \n"
for file in "${changed_file_list[@]}"
do
    echo "- $file"
done

# Get the CODEOWNERS file
# mapfile -t -u 3 codeowners_raw_lines

# mapfile draws from standard input and makes an array from it
# We use < to redirect our file as standard input, and the -t option to remove trailing \n 
# We also use process substitution <() to treat the output of sed as a file/input. (sed syntax is 'sed whateverSedCommands fileName') (See sed command example below)
# s = substitution ; /pattern/ is regex to look for (look >=1 (+) for whitespace chars ([[:space:]]); /replacement/ is replacement str (' ') ; g is global flag (replace all occurences not just the first) 
# This is much faster than looping thru an array and using sed that way TODO: WHY 
mapfile -t codeowners_raw_lines < <( sed 's/[[:space:]]\+/ /g' .github/CODEOWNERS)

# echo "codeowners_raw_lines[0] = ${codeowners_raw_lines[0]}"
# echo "codeowners_raw_lines length = ${#codeowners_raw_lines[@]}"

# Comment in these lines to see specific values of the array created by mapfile 
# echo "codeowners_raw_lines[0] = ${codeowners_lines[0]}"
# echo "codeowners_raw_lines[1] = ${codeowners_lines[1]}"

# Filter out the comments in the array or are empty (essentially this is array mapping) (use ${#line} to assess string length)

echo -e "\nFiltering out comments and empty lines in CODEOWNERS..."
for line in "${codeowners_raw_lines[@]}"
do
    # xargs is a command line utility tool that takes from standard input (we use | to redirect echo output to stdin)
    # It's really meant more for filenames, but we can use it here to trim whitespace from line.  
    # line=$(echo "$line" | xargs -0)

    if [[ ! -z "$line" && ! "${line}" == "#"* ]]
    then
        # echo "LINE! ${line}"
        # echo "line length = ${#line}"
        codeowners_lines+=("${line}")
    fi
done
# echo "codeowners_lines length = ${#codeowners_lines}"
# echo "codeowners_lines[0]  = ${codeowners_lines[0]}"
# echo "codeowners_lines[2]  = ${codeowners_lines[2]}" # This index reflects a line with multiple spaces between filepath and owner


#DELETE THIS WHEN TESTING COMPLETE
# echo "!!!!Early exit!!!"
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
echo -e "\n \e[36mBEGIN SEARCH!!\e[0m \n"
c_f_p_iterator=0
for changed_file_path in "${changed_file_list[@]}"
do
    #Examples of changed_file_path = .github/workflows/test-pr-action-2.yml, README.md, shell-scripts/info.txt, sandbox/other/sub_a/sub_b/Jenkinsfile
    # Bash doesn't have native boolean datatypes, so we use strings
    in_codeowners="false"
    echo -e "\n------------------------------------------------------------------------\n"
    echo "c_f_p_iterator=$c_f_p_iterator"
    #TODO: Why is this syntax needed
    c_f_p_iterator=$((c_f_p_iterator+1))
    #TODO: DELETE THIS or modify it for testing purposes
    # if [[ $c_f_p_iterator -eq 2 ]]
    # then
    #     echo "EXITING"
    #     exit
    # fi
    #Use this to capture all output
    # total_output+=$(echo -e "changed_file_path = $changed_file_path \n")
    echo -e "\nSearching for ownership for changed_file_path = /${changed_file_path}...\n"
    #TODO instead of how this currently is, establish an array of objects/hashes like {'filepath' : 'owner'} ??
    
    # For each line in CODEOWNERS, search for the changed_file_path or other lines that would indicate ownership
    for line in "${codeowners_lines[@]}"
    do
        echo "codeowners line = ${line}"
        # exit
        codeowners_filepath=$(echo "$line" | cut -d' ' -f1)
        owner=$(echo "$line" | cut -d' ' -f2)
        echo "codeowners_filepath = $codeowners_filepath"
        # echo "owner = $owner"
        # total_output+=$(echo -e "filepath = $codeowners_filepath \n")
        # total_output+=$(echo -e "owner = $owner \n")
        
        # Look for the whole path first to see if the file is specifically listed (Exact match)
        # Use / here to account for root
        # TODO: Enhance this somehow to just kick off to next line so full-line checks can be done first? (see num_of_slashes stuff below)
        if [[ "/${changed_file_path}" == "$codeowners_filepath" ]]
        then
          in_codeowners="true"
          echo -e "${GREEN}FOUND! (Exact file match) ${COLOR_DONE}"
          # Break out of inner loop/stop looking thru CODEOWNERS lines because we found a match
          break
        else
            # TODO: Any line below that begins with !-- is experimental. Try messing with it after you can do the initial granular search

            # TODO: This logic at the moment doesn't account for extensionless files really, or if it does it does it crappily
            # TODO: Nor does it account for **/ logic
            # !-- If the path is a top-level file don't do anything else? (ex. test-json-output.txt)
            # !-- is_top_level_file="false"
            # !-- If cutting the path using / results in only 0?,1? pieces... 
            
            IFS='/' changed_file_path_segs=($changed_file_path) 
            # TODO: This should work but DOESN'T account for 'test-json-output.txt' as a line, which would account for 'text-json-output.txt' at CODEOWNERS level
            # TODO: (See above) Maybe handle this in first if
            # Assess path is top-level by looking at slashes. Can count arr length (top-level = 1) or count the slashes in string like below (for Bash learning purposes)
            # grep -o means "only matching" which prints only matching instances of the term, on separate output lines (so only print /) 
            # wc is word count which is used to count bytes/words/lines. The -l option prints only the newline counts (each output line = newline)
            # Putting it all together each / is on a new line so by counting new lines we effectively count /'s
            # ex test-json-output has no / in it, so results in 0. shell-scripts/whatever.sh would be 1
            num_of_slashes=$(echo "${changed_file_path}" | grep -o "/" | wc -l)
            if [ $num_of_slashes == 0 ]
            then
              in_codeowners="false"
            # TODO: A path without /'s means to match a file
            # Don't bother searching because we already tested for the full file path, and lack of / means this file is top-level (but not in CODEOWNERS)
            else
                # Add / to beginning of file path (first element) to match how CODEOWNERS is written (first / indicates root)
                # Also add terminating / to account for subfolders
                changed_file_path_segs[0]="/${changed_file_path_segs[0]}/"
            fi
            # Perform the granular search
            # changed_file_path_segs = the changed_file_path (string) broken into an array of strings using / as delim
            # ex. sandbox/other/sub1/sub2/dummy-txt2.txt becomes ["sandbox","other","sub1","sub2","dummy-txt1.txt"]
            # There may not be a specific owner for the file, but there may be an owner for sandbox/other/sub2 (Hint: there is)
            # So we should look to see if there is an owner for the directory above us, but really anything above that too (ex. If someone owned sandbox/other they own all subdirectories in it)
            
            # Making a str arr with IFS will omit the delim, so let's add it back in as a suffix
            # Initialize at i=1 because we just took care of first element
            # Use -2 as loop terminal condition b/c We don't want to do this for the last element, because a slash isn't applicable (i.e. because it's a file)
            # Only do this if array length >= 3 b/c if length is 1 or 2 then suffixed /'s are not applicable
            # To get arr length, use @ to expand array then ${#} to count the elements. ge means >= 3
            if [[ ${#changed_file_path_segs[@]} -ge 3 ]]
            then
                for ((i=1; i<="${#changed_file_path_segs[@]}"-2; i++)); do changed_file_path_segs[i]+="/"; done
            fi
            
            # Clone to be safe for now TODO: See if clone is really needed, or am I being paranoid?
            # You can't simply do '=$changed_file_path_segs'. To clone an array, you need to use [@] whichach treats every element as a single word/string
            # Use double quotes to ensure every string stays intact (ex. without "" ["hello world", "goodbye"] becomes ["hello" "world" "goodbye"])
            # Then you have to wrap in () so each string is made its own array element
            changed_file_path_segs_clone=("${changed_file_path_segs[@]}")
            # TODO: Explain $(())
            segs_last_ele_index=$((${#changed_file_path_segs[@]}-1))
            segs_last_ele="${changed_file_path_segs[$segs_last_ele_index]}"
            # echo "segs_last_ele_index=${segs_last_ele_index}"
            # echo "segs_length = ${segs_length}"
            changed_file_extensionless=$( echo "${segs_last_ele}" | cut -d '.' -f1)
            # TODO: Explain how this works, more about the sed stuff than anything else
            changed_file_extension=$( echo "${changed_file_path_segs[$segs_last_ele_index]}" | cut -d '.' -f2 | sed 's/^/./')
            # echo "changed_file_extension = $changed_file_extension"
            for (( i=$segs_last_ele_index;i>0;i-- ))
            do
                #TODO: Eventually refactor this with regex or grep or both
                # unset is used to unset variables and array elements (essentially deletes array element, like JS pop()). First unset removes file ext 
                # TODO: With arrays, if you added another index after you deleted one, the index will not be continuous. SHOW THIS IN MAIN-SCRIPT
                unset 'changed_file_path_segs_clone[${#changed_file_path_segs_clone[@]}-1]'
                # Use IFS to join the arr to a string, with '' as the delimiter to preserve /'s
                changed_file_path_str=$(IFS='' ; echo ${changed_file_path_segs_clone[*]})
                echo "changed_file_path_str = ${changed_file_path_str}"
                echo "changed_file_path_str w extension = ${changed_file_path_str}*${changed_file_extension}"
                # This accounts for anything ending in SOLELY / (ex. sandbox/other/sub1/sub2/, sandbox/other/sub1/, sandbox/other/, sandbox/ )
                if [[ "${changed_file_path_str}" == "$codeowners_filepath" ]]
                then
                    in_codeowners="true"
                    echo -e "\n ${GREEN}FOUND via segs! (Ends in /) (${codeowners_filepath} accounts for ${changed_file_path})${COLOR_DONE}"
                    # Break out of inner-inner loop early because we got a match
                    break
                # If codeowners_filepath contains a *...
                elif [[ "${codeowners_filepath}" =~ \* ]]
                then
                    # If it is folderName/* AND if we are at the last element of segs
                    # This accounts for codeowners_filepath ending in /* (direct ownership of folder, NOT subdirectories)
                    # TODO: NOT RIGHT --> FOUND via segs! (Ends in /*) (/sandbox/other/sub_a/* mistakenly accounts for sandbox/other/sub_a/sub_b/wordTypes-marioOnly.csv)
                    # 
                    if [[ "${changed_file_path_str}*" == "$codeowners_filepath" && $i == $segs_last_ele_index ]]
                    then
                        in_codeowners="true"
                        echo -e "\n${GREEN}FOUND via segs! (Ends in /*) (${codeowners_filepath} accounts for ${changed_file_path}) ${COLOR_DONE}"
                        break
                    # If it is folderName/*.ext
                    elif [[ "${changed_file_path_str}*${changed_file_extension}" == "${codeowners_filepath}" ]]
                    then
                        in_codeowners="true"
                        echo -e "\n${GREEN}FOUND via segs! (Ends in /*.ext (${changed_file_extension})) (${codeowners_filepath} accounts for ${changed_file_path})${COLOR_DONE}"
                        break
                    else
                        num_of_stars=$(echo "${codeowners_filepath}" | grep -o "*" | wc -l)
                        echo "num_of_stars = $num_of_stars"
                        if [ $num_of_stars -eq 1]
                        then
                            # Find where the * is (ex. /shell-scripts/*.sh, f1/f2/*/runs/something.txt, f1/f2/*-suffix.ext, f1/prefix-*)
                            pre_star_text=$(echo "$codeowners_filepath" | cut -d'*' -f1)
                            post_star_text=$(echo "$codeowners_filepath" | cut -d'*' -f2)
                            # If post_star_text * has no slashes in it AND isn't "" must be last part of codeowners_filepath
                            if [[ ! "$post_star_text" == */* && ! -z "$post_star_text" ]]
                                # Already checked for /* and *.ext above so don't check for those again
                                # If post_star_text has a period in it, must be a filename sort of pattern
                                if [[ "$post_star_text" == *"."* ]]
                                then
                                
                                fi
                            fi
                        # TODO: Incorporate this with star_count logic
                        # Account for **/...
                        elif [[ "$codeowners_filepath" =~ ^\*\* ]]
                        then
                            # All kinds of **/ scenarios. TODO: Could this be a giant OR statment (see below)? How to resolve echo's though...
                            #TODO: grep or regex might help simplify this...

                            # If it is **/filename (account for extensionless files)
                            if [[ "**/${changed_file_extensionless}" == "${codeowners_filepath}" ]]
                            then
                                in_codeowners="true"
                                echo -e "${GREEN}FOUND! (**/extensionlessFilename match!) ${COLOR_DONE}" 
                                break
                            # If it is **/*.ext (any file with certain extension)
                            elif [[ "**/${changed_file_extension}" == "${codeowners_filepath}" ]]
                            then
                                in_codeowners="true"
                                echo -e "${GREEN}FOUND! (**/*.ext match!) ${COLOR_DONE}" 
                                break
                            # If it is **/folderName/ 
                            elif [[ "**/${changed_file_path_str}" == "${codeowners_filepath}" ]]
                            then 
                                in_codeowners="true"
                                echo -e "${GREEN}FOUND! (**/folderName/ match!) ${COLOR_DONE}"
                                break
                            # If it is **/folderName/*
                            elif [[ "**/${changed_file_path_str}*" == "${codeowners_filepath}" ]]
                            then 
                                in_codeowners="true"
                                echo -e "${GREEN}FOUND! (**/folderName/* match!) ${COLOR_DONE}"
                                break
                            # If it is **/folderName/extensionlessFilename
                            elif [[ "**/${changed_file_path_str}${changed_file_extensionless}" == "${codeowners_filepath}" ]]
                            then
                                in_codeowners="true"
                                echo -e "${GREEN}FOUND! (**/folderName/extensionlessFilename match!) ${COLOR_DONE}" 
                                break
                            #  If it is **/folderName/*.ext, **/folderName/sub1/*.ext, etc
                            elif [[ "**/${changed_file_path_str}*${changed_file_extension}" == "${codeowners_filepath}" ]]
                            then
                                in_codeowners="true"
                                echo -e "${GREEN}FOUND! (**/folderName/*.ext match!) ${COLOR_DONE}" 
                                break
                            # If it is **/folderName/filename.ext, **/folderName/sub1/filename.ext, 
                            elif [[ "**/${changed_file_path_str}${segs_last_ele}" == "${codeowners_filepath}" ]]
                            then
                                in_codeowners="true"
                                echo -e "${GREEN}FOUND! (**/folderName/...filename.ext match!) ${COLOR_DONE}" 
                                break
                            fi
                        fi
                    fi
                fi
            done # End seg-matching AKA inner-inner loop

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
        echo -e "\n\e[31mFILE NOT FOUND\e[0m"
        echo -e "$changed_file_path and associated paths not found in CODEOWNERS. Adding to files_not_in_codeowners"
        files_not_in_codeowners+="${changed_file_path},"
    fi
done #End for changed_file_path in changed_file_list

# echo "$total_output"
# Remove the last comma TODO: % syntax elaborate
files_not_in_codeowners="${files_not_in_codeowners%,}"
IFS=',' files_not_in_codeowners_arr=($files_not_in_codeowners)
echo -e "\n Files not in CODEOWNERS:\n"
for file in "${files_not_in_codeowners_arr[@]}"; do echo -e "- ${file}"; done
