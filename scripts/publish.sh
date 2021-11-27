#!/usr/bin/env bash
# This script is meant to build and compile every protocolbuffer for each
# service declared in this repository (as defined by sub-directories).

# Steps
# Ensure Dependencies
# Generate pb files
# for each language (go, cpp etc <- folders)
#   clone repo based on trple-proto-{language}
#   setup branch
#   copy files to branch
#   commit and push

set -e
PROJECT="trple-proto"
REPOPATH=${REPOPATH-/tmp/$PROJECT}
CURRENT_BRANCH=${CIRCLE_BRANCH-"branch-not-available"}

# Helper for adding a directory to the stack and echoing the result
function enterDir {
  echo "Entering $1"
  pushd $1 > /dev/null
}

# Helper for popping a directory off the stack and echoing the result
function leaveDir {
  echo "Leaving `pwd`"
  popd > /dev/null
}

# Iterates through all of the languages listed in the services .protolangs file
# and compiles them individually
function buildProtoForTypes {
  currentDir="$1"
  lang=$(basename ${currentDir})

  currentDir="$1"
  reponame="$PROJECT-$lang"
  repo="git@github.com:brettmostert/$reponame.git"
  # rm -rf $REPOPATH/$reponame

  echo "Cloning repo: $repo"

  # Clone the repository down and set the branch to the automated one
  git clone $repo $REPOPATH/$reponame
  setupBranch $REPOPATH/$reponame

  # Copy the generated files out of the pb-* path into the repository
  # that we care about
  cp -R out/$lang/* $REPOPATH/$reponame/

  commitAndPush $REPOPATH/$reponame
}

# Finds all directories in the repository and iterates through them calling the
# compile process for each one
function buildAll {
  echo "Buidling service's protocol buffers"
  rm -fr $REPOPATH
  mkdir -p $REPOPATH
  for d in out/*; do   
    buildProtoForTypes $d
  done
}

function setupBranch {
  enterDir $1

  echo "Creating branch"

  if ! git show-branch $CURRENT_BRANCH; then
    git branch $CURRENT_BRANCH
  fi

  git checkout $CURRENT_BRANCH

  if git ls-remote --heads --exit-code origin $CURRENT_BRANCH; then
    echo "Branch exists on remote, pulling latest changes"
    git pull origin $CURRENT_BRANCH
  fi

  leaveDir
}

function commitAndPush {
  enterDir $1

  git add -N .

  if ! git diff --exit-code > /dev/null; then
    git add .
    git commit -m "Auto Creation of Proto"
    git push origin HEAD
  else
    echo "No changes detected for $1"
  fi

  leaveDir
}

buildAll