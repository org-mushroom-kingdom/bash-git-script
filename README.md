# bash-git-script

A repo for testing various Bash and Github related things, often tied together. This repo also tests Github Actions.

# Background Info

This repo is for testing CODEOWNERS, among other things. A sample organization had to be made due to this. Thus, this repo is owned by the organization **org-mushroom-kingdom**, which is split into four sample teams:

- team-mario
- team-luigi
- team-peach
- team-toad

A sample CODEOWNERS file has been made, with teams being assigned to various items within. Some items will purposefully NOT be in CODEOWNERS for testing purposes. 

# Github Actions

This repo also holds several Github Actions, which help automate various processes in the CI/CD workflow. 

In this repo, we will define actions into either *Business* or *Informative* categories. This designation will in the top comment of each workflow (see .github/workflows).  

TODO: Do something with this line --> Some of these actions are mainly informative and don't do much besides echo/print things. 
TODO: Put a table or something here in the readme that denotes which actions are business and which are informative. 

## Business Actions
<br>
| Name | Purpose |
| -------- | -------- |
| test-pr-action-1.yml| Prints PR-related variables <br> Unconditionally adds a comment to all PRs <br> Conditionally adds a multiline comment to PRs (if feature branch contains the word 'readme')  | 
| closing-pr-comment-timestamp.yml | Adds a comment when the PR is closed with the timestamp of when it was closed |

## Informative Actions
<br>
| Name | Purpose |
| -------- | -------- |
 test-action.yml | Showcases several different action aspects (printing, using shell scripts/results from script, using GITHUB_OUTPUT)
 print-env-vars.yml | Prints various environmental variables (e.g $GITHUB)


# Shell Scripts

As of 8-28-2025, the main shell script of note is main-script.sh. It shows how Bash works, how various Github commands work, and how Bash and Git can work together. It's the reason this repo is **called bash-git-script** in the first place. 

The main script is used for various things.

TODO: Currently, it doesn't do a ton, just lists choices for things with the ability to go back to certain menus. In a while it should be able to fun things like reading through CODEOWNERS, perhaps.  
TODO 8-28-2025: Really, I should fork this repo, keep just the Bash and Bash-relevant stuff for portfolio and knowledge transer purposes, but I'm not doing that for a minute haha.

# To-Do List

Space for things I want to do in general, not just the TODO's in the README (though those should be done too!)

TODO: Come up with a way to make a very basic PR with a simple change to a non-important file/script so I don't have to manually make a branch and PR all the time to test Test PR Action (ironically, making a feature/PR is probaly best handled by another action)  
TODO: Capture the HTTP status of the Github API comment and mark action as failed if HTTP status != 200 