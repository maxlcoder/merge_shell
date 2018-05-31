#!/usr/bin/env bash -e

function gecho() {
  printf "\e[0;32m $1 \e[0m\n"
}

function die() {
  printf "\e[0;31m $1 \e[0m\n" >&2
  exit
}

branch=$(git rev-parse --abbrev-ref HEAD)
message=$1
if [ -z "$message" ]; then
  die "Error: commit message is empty"
fi

if [ "$branch" = "master" ]; then
  die "Error: branch is unknown. Please checkout your branch."
fi

gecho "Branch: $branch"
gecho "Commit message: $message"
last_status=0

gecho "Checking out master"
git checkout master || last_status=$?
if [ $last_status -ne 0 ]; then
  die "Switching to master failed"
fi

gecho "Pulling master"
git pull

gecho "Merging master into branch $branch"
git checkout $branch
git merge master || last_status=$?
if [ $last_status -ne 0 ]; then
  git reset --hard
  die "Merge failed, please try again"
fi

gecho "Squash merging branch $branch into master"
git checkout master
git merge --squash $branch || last_status=$?
if [ $last_status -ne 0 ]; then
  git reset --hard
  git checkout $branch
  die "Squash merge failed, please try again"
fi
git commit -m "$message"

gecho "Pushing new master to origin"
git push || last_status=$?
if [ $last_status -ne 0 ]; then
  git reset --hard master~
  git checkout $branch
  die "Push failed, please try again"
fi

gecho "Success"
