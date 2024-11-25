#!/bin/bash
set -euo pipefail

# Store current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD || git rev-parse --short HEAD)

# Check if packages directory exists and has the correct structure
if [ ! -d "../packages/dists" ] || [ ! -d "../packages/pool" ]; then
    echo "ERROR: Invalid package repository structure. Missing dists or pool directory."
    exit 1
fi

# Create temporary directory and copy packages
TEMP_DIR=$(mktemp -d)
echo "Creating temporary copy of packages..."
cp -r ../packages/* "$TEMP_DIR/"

pushd ../ > /dev/null

# Switch to or create gh-pages branch
if git show-ref --verify --quiet refs/heads/gh-pages; then
    git checkout gh-pages --force
else
    git checkout --orphan gh-pages
    # Remove all files in the working directory
    git rm -rf . || true
fi

# Ensure .gitignore doesn't interfere
if [ -f ".gitignore" ]; then
    rm .gitignore
fi

# Create packages directory if it doesn't exist
mkdir -p packages

# Copy contents back from temporary directory
echo "Restoring packages..."
cp -r "$TEMP_DIR"/* packages/

# Clean up temporary directory
rm -rf "$TEMP_DIR"

# Add and commit changes
git add -f packages/
git commit -m "Update package repository $(date +%Y-%m-%d)"

# Push changes
git push origin gh-pages --force

# Return to original branch
git checkout "$CURRENT_BRANCH" --force

echo "GitHub Pages updated successfully!"

# Display repository URL
REPO_URL=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
echo "Repository should be available at: https://$(echo $REPO_URL | cut -d/ -f1).github.io/$(echo $REPO_URL | cut -d/ -f2)"

popd > /dev/null