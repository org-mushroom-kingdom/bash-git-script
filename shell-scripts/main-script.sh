#!/bin/bash
# ^Shebang line. It TODO EXPLAIN

# Users: Use Git Bash to run this (have not tested with other terminals.) 
# Install Git Bash and Github Desktop if not already done!
# To run this script:
# 1. Copy this repo locally.
# 2. Open Github Desktop (if not already done)
# 3. Use Github Desktop to open Git Bash (Ctrl+`) or Repository-->Open in Git Bash (Your working directory should be something like C/git/bash-git-script)
# 4. Run this command:
# ./shell-scripts/main-script.sh

# Globals, defined outside the scope of a function
# Turn this on if you want a lot of echo's TODO: Better explanaiton
VERBOSE=false

# Still globals, but less important
readonly DASH="-------"
readonly MAIN_OPT="[main] Main menu"
readonly QUIT_OPT="[q] Quit"
readonly EXIT_MSG="\nQuitting. Bye!"
readonly RED="\e[31m"
readonly GREEN="\e[32m"
readonly YELLOW="\e[33m"
readonly BLUE="\e[34m"
readonly MAGENTA="\e[35m"
readonly CYAN="\e[36m"
readonly LIGHT_GREY="\e[37m"
readonly GREY="\e[90m"
readonly BOLD_GREY="\e[90m"
readonly LIGHT_RED="\e[91m"
readonly LIGHT_GREEN="\e[92m"
readonly LIGHT_YELLOW="\e[93m"
readonly LIGHT_BLUE="\e[94m"
readonly LIGHT_MAGENTA="\e[95m"
readonly LIGHT_CYAN="\e[96m"
readonly WHITE="\e[97m"
readonly GREY_BG="\e[47m"
readonly VERBOSE_FORMAT="\e[1;100m"
readonly DONE="\e[0m"

run()
{
    echo -e "\nWelcome!\n"
    verbose_echo "VERBOSE is on\n"
    list_choices_and_execute_for "main"
}


test_cyanize()
{
    test_cyan_string="" #User input. A string to make cyan
    echo -e "Enter a string. It will become a ${CYAN}cyan-colored string${DONE}\n"
    read test_cyan_string
    echo -e "\nCyanized string = "$(cyanize "${test_cyan_string}")
}

cyanize()
{
    STRING_TO_CYANIZE=$1
    echo "${CYAN}${STRING_TO_CYANIZE}${DONE}"
}

set_verbose()
{
    #TODO: Explain method
    #TODO: V is false 
    #TODO: Better echo's, cyanify/highlight crap
    echo -e "\n VERBOSE is currently set to ${VERBOSE}"
    echo -e "If VERBOSE is set to on, you will see extra messages ${VERBOSE_FORMAT}formatted like this${DONE} to assist in debugging."
    #TODO: Explain shorthand
    [[ $VERBOSE = true ]] && verb="Keep" || verb="Turn"
    echo "${verb} VERBOSE on? Type y for yes" 
    read CHOICE
    if [ $CHOICE = "y" ]
    then
        VERBOSE=true
    fi
    echo "VERBOSE is now set to ${VERBOSE}"
    continue_or_quit "main"
}

verbose_echo()
{
    #If VERBOSE global is on (true), then echo
    V_STRING=$1 #String
    if $VERBOSE; then
        if [[ $V_STRING == *"\n"* ]]
        then
            [[ $V_STRING == "\n"* ]] && echo -e "\n" || :
            echo -e "${VERBOSE_FORMAT}${V_STRING}${DONE}" | xargs
            [[ $V_STRING == *"\n" ]] && echo -e "\n" || :
        fi
    fi
}

list_choices_and_execute_for()
{
    set=$1
    user_choice="" #user input
    list_choices $set
    read user_choice
    execute_based_on_choice $user_choice $set
}

# lc
list_choices()
{
    #This only lists strings
    set=$1
    case $set in
        main)
            echo -e "${DASH}Main Menu${DASH}\n"
            echo -e "Please make a selection \n"
            echo "[1] CODEOWNERS Testing Suite"
            echo "[2] Github Testing Suite"
            echo "[3] Debug Menu"
            echo -e "[q] Quit \n"
            ;;
        CODEOWNERS)
            echo -e "\n${DASH}CODEOWNERS Testing Suite${DASH}\n"
            echo "[1] Read through CODEOWNERS (no comments)"
            echo "[2] TBD"
            echo "[3] TBD"
            echo -e "${MAIN_OPT} \n"
            ;;
        github)
            echo -e "\n${DASH}Github Testing Suite${DASH}\n"
            echo "[1] Github TBD"
            echo "[2] Github TBD"
            echo "[3] Github TBD"
            echo -e "${MAIN_OPT} \n"
            ;;
        debug)
            echo -e "\n${DASH}Debug Menu (Debug Mode)${DASH}\n"
            echo -e "[1] Test" $(cyanize "cyanize()")
            echo -e "[2] Verbose ON/OFF" #Probs becomes a debug menu option
            echo -e "${MAIN_OPT} \n"
            # echo -e "Other debug menu options TBD \n"
            ;;
        help)
            echo -e "\n${DASH}Help Menu (Debug Mode)${DASH}\n"
            echo -e "[1] How to use this app"
            echo -e "[2] Color meanings"
            ;;
        *)
            echo "Invalid selection"
            ;;
    esac
}

execute_based_on_choice()
{
    CHOICE=$1
    TYPE=$2
    case $TYPE in
        main)
            case $CHOICE in
                1)
                    list_choices_and_execute_for "CODEOWNERS"
                    ;;
                2)
                    list_choices_and_execute_for "github"
                    ;;
                3)
                    list_choices_and_execute_for "debug"
                    ;;
                von)
                    echo -e "Setting VERBOSE to on!\n"
                    VERBOSE=true
                    run
                    ;;
                q)
                    echo -e $EXIT_MSG
                    exit
                    ;;
                *)
                    echo "OK"
                    ;;
            esac
            ;;
        CODEOWNERS)
            verbose_echo "execute_based_on_choice(): CODEOWNERS hit! CHOICE = ${CHOICE}"
            case $CHOICE in
                1)
                    verbose_echo "User selected "$(cyanize "Read thru Codeowners")
                    call_read_thru_codeowners
                    ;;
                main)
                    run
                    ;;
                *)
                    echo "YAY"
                    ;;
            esac
            ;;    
        github)
            verbose_echo "execute_based_on_choice(): github hit! CHOICE = ${CHOICE}"
            case $CHOICE in
                1)
                    echo "github choice 1"
                    ;;
                *)
                    echo "github choice 2"
                    ;;
            esac
            ;;
        debug)
            verbose_echo -e "\nexecute_based_on_choice(): debug hit! CHOICE = ${CHOICE}"
            case $CHOICE in
                1)
                    test_cyanize
                    ;;
                2)
                    set_verbose
                    ;;
                q)
                    echo "Qutting. Hope you liked Debug Mode!"
                    exit
                ;;
            main)
                run
                ;;
            *)
                echo "Invalid debug menu option. Quitting for now"
                exit
                ;;
        esac
        continue_or_quit "debug"
        ;;
        help)
            verbose_echo -e "\nexecute_based_on_choice(): help hit! CHOICE = ${CHOICE}"
            case $CHOICE in
                    1)
                        echo "How to use --TBD"
                        ;;
                    2)
                        echo $(cyanize "cyan") "| keys (or words) that a user can type as input into this app"
                        echo "Rest of colors to be discussed. TBD"
                        ;;
            esac
            #TODO: Stay on help menu option, edit continue_or_quit?
            continue_or_quit "main"
            ;;
        *)
            verbose_echo "execute_based_on_choice: Invalid TYPE"
            echo "Invalid TYPE"
    esac
}

call_read_thru_codeowners()
{
    # Iterate thru the CODEOWNERS file
    # echo the filepath and owner in the form of filepath | owner (ex. /shell-scripts/*.sh | @org-mushroom-kingdom/team-mario)
    echo "call_read_thru_codeowners option was hit."
    echo "Attempting to call read-thru-codeowners.sh..."
    #Example of how to escape $ using \
    # echo "\$PWD = ${PWD}"
    
    # The reason this needs ./shell-scripts is because Git Bash (the main terminal I am using for this), at the time of running
    # is pointed at my local's top-level (the top level of bash-git-script). So we need to direct
    ./shell-scripts/read-thru-codeowners.sh
    continue_or_quit "main"
}

continue_or_quit()
{
    menu_type=$1
    debug_return_msg=""
    #TODO EXPLAIN shorthand and :
    [[ $menu_type = "debug" ]] && debug_return_msg=" To return to the debug menu, type 1." || :
    echo -e "\nTo return to the main menu, type "$(cyanize "main")".${debug_return_msg} To quit, press "$(cyanize "q")" or any other key \n"
    read decision
    if [ $decision = "main" ]
    then
        run
    elif [ $menu_type = "debug" ]
    then
        list_choices_and_execute_for "debug"
    
    elif [ $menu_type = "help" ]
    then
        list_choices_and_execute_for "help"
    
    else
        echo -e $EXIT_MSG
        exit
    fi
}


# Script is actually run here

run