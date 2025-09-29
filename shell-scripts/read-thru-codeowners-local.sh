#!/bin/bash

# This is almost identical to read-thru-codeowners but makes it work locally via Git Bash (easier to test like this. 
# There's probs some workarounds one could do but Github Actions outputs isn't great when it comes to running a script and doing echo's)
# You won't see TODO


# This is the local version, so there's no reliance on variables defined by Github Actions.

# Listing readonly variables first. All other variables listed in order of appearance
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly COLOR_DONE="\e[0m"

declare -a changed_file_list # A preset String arr with selected repo file names to test with CODEOWNERS. This var is specific to read-thru-codeowners-local.sh
declare -a codeowners_raw_lines # String arr with ALL lines from CODEOWNERS
declare -a codeowners_lines # String arr mapped from above, only lines that aren't comments (or empty)
files_not_in_codeowners="" # Comma-delimited String of all files that were not matched in CODEOWNERS
c_f_p_iterator=0 #Used to iterate in the outermost loop. TODO: Might delete this, it's not doing much at the moment (9-27-25)
total_output="" #Experimental. Build on this so the Action can spit out everything?
num_of_slashes=0
num_of_stars=0
codeowners_filepath="" # Only the filepath from a line in CODEOWNERS (whose syntax is <filepath> <owner>)
# Everything in here is accounted for in CODEOWNERS except sandbox/not-in-codeowners/README.md
# Feel free to comment in/out various lines for testing purposes
# TODO: Ideally you'd give these as options in a list or something and take user input or at least have that as an option
changed_file_list=(
# "test-json-output.txt" 
# "sandbox/other/sub_a/sub_b/Jenkinsfile" 
# "sandbox/other/sub_a/sub_b/wordTypes-marioOnly.csv" 
# "sandbox/other/sub1/dummy-script1.sh" 
# "sandbox/other/sub_a/enemyTypes1.csv" 
# "sandbox/games/saves/savegame-1-01012021"
"README.md"
# "sandbox/not-in-codeowners/README.md"
"sandbox/not-in-codeowners/DONTREADME.md"
)
# TODO: Scenario where file is ignored!! i.e. owner = null or "" but a line exists

accounts_for="" # String that appears in echo when file is accounted for in CODEOWNERS. Says that CODEOWNERS filepath covers the changed file path

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


# Comment in these lines to see length of arr and specific values of the array created by mapfile 
# echo "codeowners_raw_lines length = ${#codeowners_raw_lines[@]}"
# echo "codeowners_raw_lines[0] = ${codeowners_lines[0]}"
# echo "codeowners_raw_lines[1] = ${codeowners_lines[1]}"

# Filter out the comments in the array or are empty (essentially this is array mapping) (use ${#line} to assess string length)

echo -e "\nFiltering out comments and empty lines in CODEOWNERS..."
for line in "${codeowners_raw_lines[@]}"
do
    if [[ ! -z "$line" && ! "${line}" == "#"* ]]
    then
        # echo "LINE! ${line}"
        # echo "line length = ${#line}"
        codeowners_lines+=("${line}")
    fi
done

# echo "codeowners_lines length = ${#codeowners_lines}"
# echo "codeowners_lines[0]  = ${codeowners_lines[0]}"


#DELETE THIS WHEN TESTING COMPLETE
# echo "!!!!Early exit!!!"
# exit
 
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
    #TODO: Why is this syntax needed $(())
    c_f_p_iterator=$((c_f_p_iterator+1))
    changed_filename=$(basename "$changed_file_path")
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
        # echo "codeowners line = ${line}"
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
            echo -e "${GREEN}FOUND! (Exact file match with root /) ${COLOR_DONE}"
            # Break out of inner loop/stop looking thru CODEOWNERS lines because we found a match
            break
        elif [[ "${changed_file_path}" == "$codeowners_filepath" ]]
        then 
            # Less common scenario, so check for it second. (ex. if changed file is test-json-output.txt CODEOWNERS line 'test-json-output.txt' accounts for it (acts like **/test-json-output.txt))
            in_codeowners="true"
            echo -e "${GREEN}FOUND! (Exact file match) ${COLOR_DONE}"
            # Break out of inner loop/stop looking thru CODEOWNERS lines because we found a match
            break
        elif [[ "**/${changed_filename}" == "$codeowners_filepath" ]]
        then
            # Less common scenario, so check for it second. (ex. if changed file is test-json-output.txt CODEOWNERS line 'test-json-output.txt' accounts for it (acts like **/test-json-output.txt))
            in_codeowners="true"
            echo -e "${GREEN}FOUND! (**/filename match) ${COLOR_DONE}"
            # Break out of inner loop/stop looking thru CODEOWNERS lines because we found a match
            break
        fi
    done

    if [[ "$in_codeowners" == "false" ]]
    then
        echo "More advanced search logic..."
        for line in "${codeowners_lines[@]}"
        do
            codeowners_filepath=$(echo "$line" | cut -d' ' -f1)
            owner=$(echo "$line" | cut -d' ' -f2)
            echo "codeowners_filepath = $codeowners_filepath"
            IFS='/' changed_file_path_segs=($changed_file_path) 
            # TODO: This should work but DOESN'T account for 'test-json-output.txt' as a line, which would account for 'text-json-output.txt' at any level
            # TODO: (See above) Maybe handle this in first if
            # Assess path is top-level by looking at slashes. Can count arr length (top-level = 1) or count the slashes in string like below (for Bash learning purposes)
            
            # The echo | grep | wc example here works and is used for Bash educational purposes. You could alternatively count the length of IFS and subtract 1 to this too
            # grep -o means "only matching" which prints only matching instances of the term, on separate output lines (so only print /) 
            # wc is word count which is used to count bytes/words/lines. The -l option prints only the newline counts (each output line = newline)
            # Putting it all together each / is on a new line so by counting new lines we effectively count /'s
            # ex test-json-output has no / in it, so results in 0. shell-scripts/whatever.sh would be 1
            num_of_slashes=$(echo "${changed_file_path}" | grep -o "/" | wc -l)
            if [ $num_of_slashes == 0 ]
            then
                in_codeowners="false"
                # A changed file path without /'s means the file is top level
                # TODO: It may be top-level but CODEOWNERS paths like 'filename.ext' or '*fileSuffix.ext' could exist (which essentially acts as **/filename.ext, **/*fileSuffix.ext, respectively)
                # But already accounted for top-level no slash

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
            # folder/filename.ext [/folder/,filename.ext] --> length of 2
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
            segs_last_ele="${changed_file_path_segs[$segs_last_ele_index]}" #(ex. say-hello.sh, Jenkinsfile)
            # echo "segs_last_ele_index=${segs_last_ele_index}"
            # echo "segs_length = ${segs_length}"
            
            # If last element has an extension (indicated by presence of .), capture the filename and extension separately
            if [[ "$segs_last_ele" == *"."* ]]
            then
                changed_filename_no_ext=$( echo "${segs_last_ele}" | cut -d '.' -f1)
                # TODO: Explain how this works, more about the sed stuff than anything else
                changed_file_extension=$( echo "${changed_file_path_segs[$segs_last_ele_index]}" | cut -d '.' -f2 | sed 's/^/./')
            # If the last element doesn't have an extension, it's an extensionless file so just use segs_last_ele
            else
                changed_filename_no_ext="$segs_last_ele"
            fi
            # echo "changed_file_extension = $changed_file_extension"
            # Loop backwards thru the segs to make strings out of them. Working from innermost dir to outermost.
            for (( i=$segs_last_ele_index;i>0;i-- ))
            do
                accounts_for="(CODEOWNERS filepath '${codeowners_filepath}' accounts for '${changed_file_path}')"
                #TODO: Eventually refactor this with regex or grep or both
                # unset is used to unset variables and array elements (essentially deletes array element, like JS pop()). First unset removes file ext 
                # TODO: With arrays, if you added another index after you deleted one, the index will not be continuous. SHOW THIS IN MAIN-SCRIPT
                unset 'changed_file_path_segs_clone[${#changed_file_path_segs_clone[@]}-1]'
                # Use IFS to join the arr to a string, with '' as the delimiter to preserve /'s
                # array[*] means 'treat all elements of this array as a single word, using IFS as a delimiter'
                # Here IFS is '' so this means join all the elements so they are right next to eachother (ex. ["folder/" "subdir/"] --> "folder/subdir/")
                changed_file_path_str=$(IFS='' ; echo ${changed_file_path_segs_clone[*]})
                # echo "changed_file_path_str = ${changed_file_path_str}"
                # echo "changed_file_path_str w *.ext = ${changed_file_path_str}*${changed_file_extension}"
                
                # This accounts for anything ending in SOLELY / (ex. sandbox/other/sub1/sub2/, sandbox/other/sub1/, sandbox/other/, sandbox/ )
                if [[ "${changed_file_path_str}" == "$codeowners_filepath" ]]
                then
                    in_codeowners="true"
                    echo -e "\n ${GREEN}FOUND via segs! (Ends in /) (${codeowners_filepath} accounts for ${changed_file_path})${COLOR_DONE}"
                    # Break out of inner-inner loop early because we got a match
                    break
                # If codeowners_filepath contains a * (\ used to escape *)...
                elif [[ "${codeowners_filepath}" =~ \* ]]
                then
                    num_of_stars=$(echo "${codeowners_filepath}" | grep -o "*" | wc -l)
                    # echo "num_of_stars = $num_of_stars"
                    if [ $num_of_stars -eq 1 ]
                    then
                        # If it is folderName/* AND if we are at the last element of segs
                        # This accounts for codeowners_filepath ending in /* (direct ownership of folder, NOT subdirectories)
                        if [[ "${changed_file_path_str}*" == "$codeowners_filepath" && $i == $segs_last_ele_index ]]
                        then
                            in_codeowners="true"
                            echo -e "\n${GREEN}FOUND via segs! (Ends in /*) ${accounts_for} ${COLOR_DONE}"
                            break
                        # If it is folderName/*.ext
                        elif [[ "${changed_file_path_str}*${changed_file_extension}" == "${codeowners_filepath}" ]]
                        then
                            in_codeowners="true"
                            echo -e "\n${GREEN}FOUND via segs! (Ends in /*.ext (${changed_file_extension})) (${codeowners_filepath} accounts for ${changed_file_path})${COLOR_DONE}"
                            break
                        else
                            # Find where the * is (ex. /shell-scripts/*.sh, f1/f2/*/runs/something.txt, f1/f2/*-suffix.ext, f1/prefix-*, f1/prefix*suffix.ext)
                            # More examples (f1/f2/*/Dockerfile, f1/f2/f3/)
                            pre_star_text=$(echo "$codeowners_filepath" | cut -d'*' -f1) # ex. f1/f2/prefix*suffix --> f1/f2/prefix
                            # The ## syntax will remove the longest matching incidence of the subsequent pattern (*/, which is any char(*) followed by a /) 
                            # Basically this removes everything before the last /
                            between_slash_star_text="${pre_star_text##*/}" # ex. f1/f2/prefix --> prefix
                            post_star_text=$(echo "$codeowners_filepath" | cut -d'*' -f2) 
                            
                            # If post_star_text * has no slashes in it AND isn't "" must be last (or only) part of codeowners_filepath LAST OR ONLY
                            if [[ ! "$post_star_text" == */* && ! -z "$post_star_text" ]]
                            then
                                # Already checked for /* and *.ext above so don't check for those again
                                # If post_star_text has a period in it, must be a filename with extension sort of pattern (we got extension earlier)
                                if [[ "$post_star_text" == *"."* ]]
                                then
                                    between_star_dot_text=$(echo "$post_star_text" | cut -d'.' -f1) #ex -suffix.ext
                                    [[ ! -z "$between_star_dot_text" ]] && echo -e "${YELLOW}between_star_dot_text = ${between_star_dot_text}${COLOR_DONE}"
                                    echo -e "constructed path: ${YELLOW}${changed_file_path_str}*${between_star_dot_text}${changed_file_extension}${COLOR_DONE}"
                                    #If nothing before dot, then must be *.ext which was already checked for
                                    if [[ ! -z "$between_star_dot_text" ]]
                                    then
                                        #Check if it's just a suffix sort of thing like *marioOnly.csv
                                        if [[ "${changed_file_path_str}*${between_star_dot_text}${changed_file_extension}"  == "${codeowners_filepath}" ]] # ex. ...sub_b/List1-marioOnly.csv caught by ...sub_b/*marioOnly.csv
                                        then
                                            in_codeowners="true"
                                            echo -e "\n${GREEN}FOUND! (Ends in *suffix.ext) ${accounts_for}${COLOR_DONE}"
                                            break
                                            # TODO: Another elif here the accounts for pre_star_text
                                        fi
                                    fi
                                else
                                    # echo "post_star_text does NOT contain a ."
                                    #TODO: Don't bother with this is changed_file_path doesn't have a . too
                                    
                                    # TODO: Again, regex/grep could help here: get rid of if-contains-. logic and do regex like 
                                    # TODO (cont):                                     
                                    #post_star_text does NOT contain . or / AND has 1 star AND isn't blank (and is still last/only part of codeowners_filepath)
                                    # So codeowners_filepath must have been like /*extensionlessSuffix or /something*whatever
                                    # or more rarely top-level like 'Jenkins*' 
                                    # Have to remember that a path like '*whatever' (no terminating /) can match extensionless files AND acts like *whatever/ (WHICH IS DUMB)
                                    # Account for extensionless file
                                    # ch_fp_str examples sandbox/other/sub1/sub2/sub3/prefix*suffix-->sandbox/other/sub1/sub2/sub3, sandbox/other/sub1/sub2/, sandbox/other/sub1/, sandbox/other/, sandbox/ )
                                    # ex. sandbox/other/sub1/sub2/sub3/prefix*suffix --> ".../prefix"+"*"+"suffix""
                                    # Alt: sandbox/sub_a/savegame*DDMMYYYYtimestamp
                                    # ex. sandbox/sub_a/savegame + * + DDMMYYYYtimestamp
                                    # if [[ ! "$post_star_text" == *"."* ]]
                                    # then
                                    if [[ $i == $segs_last_ele_index ]]
                                    then
                                        echo -e "${YELLOW}filepath+pre_star*+post_star = ${changed_file_path_str}${between_slash_star_text}*${post_star_text}${YELLOW}"
                                        if [[ "${changed_file_path_str}${between_slash_star_text}*${post_star_text}" == "${codeowners_filepath}" ]]
                                        then
                                            in_codeowners="true"
                                            echo -e "\n${GREEN}FOUND! (Ends in prefix*suffix) ${accounts_for}${COLOR_DONE}"
                                            break
                                        fi
                                        echo "UGH"
                                    fi
                                fi
                            else
                                #post_star_text does NOT contain a / 
                                if [[ "$post_star_text" == */* ]]
                                then
                                    echo "post_star_text has slashes"
                                    # If there's slashes after * then codeowners_filepath could be like ...*/Jenkinsfile, .../*/somename, ...*folderSuffixName/
                                fi
                            fi
                        fi
                    # TODO: Incorporate this with star_count logic
                    # Account for **/...
                    elif [[ "$codeowners_filepath" =~ ^\*\* ]]
                    then
                        # All kinds of **/ scenarios. TODO: Could this be a giant OR statment (or other solution, see below)? How to resolve echo's though...
                        #TODO: CASE statement, grep or regex might help simplify this...

                        # If it is **/filename (account for extensionless files)
                        if [[ "**/${changed_filename_no_ext}" == "${codeowners_filepath}" ]]
                        then
                            in_codeowners="true"
                            echo -e "${GREEN}FOUND! (**/extensionlessFilename match!) ${COLOR_DONE}" 
                            break
                        # If it is **/*.ext (any file with certain extension)
                        elif [[ "**/*${changed_file_extension}" == "${codeowners_filepath}" ]]
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
                        elif [[ "**/${changed_file_path_str}${changed_filename_no_ext}" == "${codeowners_filepath}" ]]
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
                # At this point: 1. it's not an exact match; 2. No segs are exact matches; 3. No * are present in codeowners_filepath 
            done # End seg-matching AKA inner-inner loop

            if [[ "$in_codeowners" == "true" ]]
            then
                # if in_codeowners is true (due to seg-matching loop above), exit inner loop early b/c we found a match
                break
            fi
        done # End for line in CODEOWNERS loop (AKA inner loop)
    fi 
    # If not in CODEOWNERS, add to files_not_in_codeowners via string concatentation
    # We use a string here rather than an arg because it's easier to pass that back to the workflow file
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
# echo "$files_not_in_codeowners"

# COMMENT THIS OUT OR DELETE THIS FOR ACTION WORKFLOW!!! 
IFS=',' files_not_in_codeowners_arr=($files_not_in_codeowners)
echo -e "\n Files not in CODEOWNERS:\n"
for file in "${files_not_in_codeowners_arr[@]}"; do echo -e "- ${file}"; done
