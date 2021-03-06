#!/bin/bash
git pull

if [[ $(git status -s) ]]
then
    echo "The working directory is dirty. Now commit pending changes."
    git add . && git commit -m "Publishing to master" && git push origin master -f
fi

echo "Deleting old publication"
rm -rf public
mkdir public
rm -rf .git/worktrees/public/

echo "Checking out gh-pages branch into public"
git worktree add -B gh-pages public origin/gh-pages

echo "Removing existing files"
rm -rf public/*

echo "Generating site"
hugo

echo "Updating gh-pages branch"
cd public && git add --all && git commit -m "Publishing to gh-pages (publish.sh)"

echo "Push to origin"
git push origin gh-pages -f
