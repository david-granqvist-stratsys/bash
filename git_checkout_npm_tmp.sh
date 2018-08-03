#!/bin/bash
#
# Perform git checkout and commonly used commands 

##################################################
# Perform git checkout, git pull and npm install
# Globals: 
#   None
# Arguments: 
#   alias for branch
# Returns:
#   None
##################################################
function gcwithnpminstall(){

	if [ ${#1} -lt 4 ]; then
		git checkout "$1/master"
	else
		git checkout $1
	fi

  git pull --ff-only
	npm install
}

##################################################
# Parse input and interpret branch name from input
# Globals: 
#   None
# Arguments: 
#   alias for branch
# Returns:
#   None
##################################################
function getBranch(){

}

gcwithnpminstall $1
