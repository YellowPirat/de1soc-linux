#!/bin/bash
set -euo pipefail

# Store current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD || git rev-parse --short HEAD)

# Check if packages directory exists and has the correct structure
if [ ! -d "../packages/dists" ] || [ ! -d "../packages/pool" ]; then
    echo "ERROR: Invalid package repository structure. Missing dists or pool directory."
    exit 1
fi

# Switch to or create gh-pages branch
if git show-ref --verify --quiet refs/heads/gh-pages; then
    git checkout gh-pages --force
else
    git checkout --orphan gh-pages
fi

# Add and commit from root directory
cd ..
git add -f packages/*
git commit -m "Update package repository $(date +%Y-%m-%d)"

# Push changes
git push origin gh-pages

# Return to original branch and directory
git checkout "$CURRENT_BRANCH" --force
cd scripts

echo "GitHub Pages updated successfully!"
REPO_URL=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
echo "Repository should be available at: https://$(echo $REPO_URL | cut -d/ -f1).github.io/$(echo $REPO_URL | cut -d/ -f2)"