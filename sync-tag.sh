#!/bin/bash
set -e

# Script to sync an upstream tag while preserving our build-images.yml workflow

if [ $# -eq 0 ]; then
    echo "Usage: $0 <tag-name>"
    echo "Example: $0 v2.3.0"
    exit 1
fi

TAG_NAME="$1"

echo "Syncing tag: $TAG_NAME"

# Fetch from upstream
echo "Fetching from upstream..."
git fetch upstream --tags

# Check if the tag exists upstream
if ! git rev-parse "refs/tags/$TAG_NAME" >/dev/null 2>&1; then
    echo "Error: Tag $TAG_NAME does not exist in upstream"
    exit 1
fi

# Get the commit hash for the upstream tag
UPSTREAM_COMMIT=$(git rev-parse "$TAG_NAME")
echo "Upstream tag $TAG_NAME points to: $UPSTREAM_COMMIT"

# Create a temporary branch
TEMP_BRANCH="temp-sync-$TAG_NAME"
echo "Creating temporary branch: $TEMP_BRANCH"
git checkout -b "$TEMP_BRANCH" "$UPSTREAM_COMMIT"

# Check if build-images.yml exists in master
if [ ! -f .github/workflows/build-images.yml ]; then
    # Get the build-images.yml from our master branch
    echo "Adding build-images.yml from master..."
    git checkout master -- .github/workflows/build-images.yml
    git add .github/workflows/build-images.yml
    git commit -m "feat: add GitHub Actions workflow for container image builds"
else
    echo "build-images.yml already exists in this tag"
fi

# Delete existing local tag if it exists
if git rev-parse "refs/tags/$TAG_NAME" >/dev/null 2>&1; then
    echo "Deleting existing local tag $TAG_NAME..."
    git tag -d "$TAG_NAME"
fi

# Create new tag
echo "Creating tag $TAG_NAME..."
git tag "$TAG_NAME"

# Switch back to master
git checkout master

# Delete temporary branch
echo "Cleaning up temporary branch..."
git branch -D "$TEMP_BRANCH"

echo ""
echo "Tag $TAG_NAME has been created successfully!"
echo "To push the tag to origin, run:"
echo "  git push origin $TAG_NAME"
echo ""
echo "To force-push if the tag already exists on remote:"
echo "  git push origin $TAG_NAME --force"
