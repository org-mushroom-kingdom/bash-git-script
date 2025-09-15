# bash-git-script

A repo for testing various Bash and Github related things, often tied together. This repo also tests Github Actions.

# Background Info: Organization and Teams

This repo is for testing CODEOWNERS and other logic related to Github teams. A sample organization and sample teams had to be made due to this. This repo is owned by the organization **org-mushroom-kingdom**, which is split into four sample teams:

- team-mario
- team-luigi
- team-peach
- team-toad

A sample CODEOWNERS file has been made, with teams being assigned to various items within. Some items will purposefully NOT be in CODEOWNERS for testing purposes. 

This repo is currently a solo project, and I didn't have any colleagues personal Github account info, so only my user is a member of most teams. There is an exception with team-peach, which has an additional member that I had to manually create and manage. If you are forking this repo, hopefully you can goad some likeminded friends into joining your spoof organization and teams!

<!-- TODO: Repo specific info in regards to sandbox/dummy directories and files, which are more there for being able to test different paths than actually containing any specific business logic -->

# Github Actions

This repo also holds several Github Actions, which help automate various processes in the CI/CD workflow. 

In this repo, we will define actions into either *Business* or *Informative* categories. This designation will in the top comment of each workflow (see .github/workflows).  

Business actions can be defined as actions that perform some sort of logic aside from print/echo/write statements. Informative actions mainly informative just echo/print things. Note that regardless of the category, the actions in this repo usually have a moderate to heavy amount of comments that elaborate how action logic and other logic works (this repo is a huge learning experience for me, so why not share the information?). It's important to look at the comments of each action as they explain why I set something up the way I did and to elaborate on different ways to do things (ex. using cURL vs. Github CLI)

TODO: Finish this table  

## Business Actions
<br>
| Name | Purpose |
| -------- | -------- |
| test-pr-action-1.yml| Prints PR-related variables <br> Unconditionally adds a comment to all PRs <br> Conditionally adds a multiline comment to PRs (if feature branch contains the word 'readme') <br> Add the pull request creator as an assignee (in progress) <br> Add a label to a PR based on assignee's team (in progress) | 
| closing-pr-comment-timestamp.yml | Adds a comment when the PR is closed with the timestamp of when it was closed |
| codeowners-interactions.yaml | TODO: EXPLAIN WHAT THIS DOES WHEN FLESHED OUT |

## Informative Actions
<br>
| Name | Purpose |
| -------- | -------- |
 test-action.yml | Showcases several different action aspects (printing, using shell scripts/results from script, various step keywords, using GITHUB_OUTPUT)
 print-env-vars.yml | Prints various environmental variables (e.g $GITHUB)


# Shell Scripts

As of 8-28-2025, the main shell script of note is main-script.sh. It shows how Bash works, how various Github commands work, and how Bash and Git can work together. It's the reason this repo is **called bash-git-script** in the first place, even though this repo has taken on new functionality since then. 

The main script is used for various things.

TODO: Currently, it doesn't do a ton, just lists choices for things with the ability to go back to certain menus. In a while it should be able to fun things like reading through CODEOWNERS, perhaps. Or at least call a script that does that. 
TODO: User branch deletion stuff? Branch search stuff? Stale?  
TODO 8-28-2025: Really, I should fork this repo, keep just the Bash and Bash-relevant stuff for portfolio and knowledge transer purposes, but I'm not doing that for a minute haha.
TODO: Finish this table

| Name | Purpose |
| -------- | -------- |
| divide.sh | Examples of division and modulo in Bash |
| main-script.sh | TODO: DESCRIPTION, but maybe its own section too |
| pr-labels.sh | In progress. TODO: Adds labels to PR based on: <br> 1. The teams the PR creator is a part of <br> 2. The target branch of the PR |


# To-Do List

Space for things I want to do in general, not just the TODO's in the README (though those should be done too!)

TODO: Come up with a way to make a very basic PR with a simple change to a non-important file/script so I don't have to manually make a branch and PR all the time to test Test PR Action (ironically, making a feature/PR is probaly best handled by another action) <--Is this done? 
TODO: Capture the HTTP status of the Github API comment and mark action as failed if HTTP status != 200 <--Is this done?
TODO:  Explain in this README the env/dev and env/qa1 branches