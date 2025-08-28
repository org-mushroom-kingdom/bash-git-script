#!/bin/bash

# This is its own separate script for a couple of reasons:
# 1. As an example of how a script can be called from another script (main-script.sh calls this one)
# 2. Possible use in Github Action test-pr-action-1.yml

echo "read_thru_codeowners.sh was hit!"

#Open/Get CODEOWNERS
# Get filepath (in PR), see if path is in 