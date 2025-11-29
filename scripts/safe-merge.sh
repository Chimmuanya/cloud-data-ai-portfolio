#!/usr/bin/env bash
#
# Safe Git Merge Script
# This script automates merging feature branches into 'develop' while ensuring
# the main branch is up-to-date and handling merge conflicts gracefully.

# --- Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Use pipefail to catch errors in pipelines (e.g., git status | grep).
set -o pipefail

# Define feature branches in the desired merge order
BRANCHES=(
    "feature/project1-validator-prototype"
    "feature/project1-handler"
    "feature/project1-local-invoke"
    "feature/project1-sam-iam"
    "feature/project1-diagram"
)

# --- Functions ---

# Function to check for uncommitted changes
check_clean_working_tree() {
    echo "=== 1. Checking working tree status ==="
    # Check for uncommitted/unstaged changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "ERROR: Please commit or stash local changes before merging."
        exit 1
    fi
    echo "Working tree is clean."
}

# Function to update main and set up develop
setup_develop_branch() {
    echo "=== 2. Setting up 'develop' branch ==="

    # Update main branch
    git checkout main

    # Suppress output of pull error to prevent terminal clutter if remote is missing
    if ! git pull --rebase origin main 2>/dev/null; then
        echo "Note: Could not pull from 'origin/main' (remote might not exist). Proceeding with local main."
    fi

    # Create or reset develop from main
    if git show-ref --verify --quiet refs/heads/develop; then
        echo "Branch 'develop' found locally. Checking it out and resetting to main."
        git checkout develop
        git reset --hard main
    else
        echo "Creating new branch 'develop' from main."
        git checkout -b develop
    fi
    echo "Current branch: develop"
}

# Function to merge all configured feature branches
merge_feature_branches() {
    echo "=== 3. Merging feature branches into develop ==="
    for b in "${BRANCHES[@]}"; do
        echo "--------------------------------------------------------"
        if git show-ref --verify --quiet refs/heads/"$b"; then
            echo "Attempting to merge branch: $b"
            # Attempt a non-fast-forward merge
            # --no-edit ensures the merge commit message is automatically accepted
            if git merge --no-ff "$b" -m "chore: merge ${b#feature/} into develop" --no-edit; then
                echo "SUCCESS: Merged $b."
            else
                # Merge conflict detected
                echo "CRITICAL ERROR: Merge of '$b' failed due to conflicts."
                echo "Please resolve the conflicts manually, then run:"
                echo "  git add <resolved-files>"
                echo "  git commit"
                echo "Once resolved, you can manually merge remaining branches."
                exit 2
            fi
        else
            echo "SKIP: Branch '$b' not found locally."
        fi
    done
}

# Function to push results
push_develop() {
    echo "=== 4. Pushing 'develop' branch ==="
    if git remote | grep -q origin; then
        echo "Pushing develop to origin..."
        git push -u origin develop
    else
        echo "No 'origin' remote found. Skipping push."
    fi
    echo "--------------------------------------------------------"
}

# --- Main Execution ---

# 0. Ensure we're in repo root
cd "$(git rev-parse --show-toplevel)" || exit 1

check_clean_working_tree
setup_develop_branch
merge_feature_branches
push_develop

echo "=== SCRIPT COMPLETE ==="
git branch --show-current
git log --oneline --decorate -n 10
