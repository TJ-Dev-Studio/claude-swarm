#!/usr/bin/env bash
# swarm init — scaffold .swarm/ in the current project

swarm_init() {
    local project_dir="${1:-.}"
    local swarm_path="$project_dir/.swarm"

    if [[ -d "$swarm_path" ]]; then
        echo "Error: .swarm/ already exists in $project_dir"
        echo "Remove it first if you want to reinitialize."
        exit 1
    fi

    echo "Initializing swarm in: $project_dir"

    mkdir -p "$swarm_path/tasks"
    mkdir -p "$swarm_path/claimed"
    mkdir -p "$swarm_path/worktrees"

    # Create empty SPEC.md
    cat > "$swarm_path/SPEC.md" << 'SPECEOF'
# Shared Specification

This file contains the shared conventions, coordinate systems, material palettes,
and constants that all agents must follow.

## Conventions

(Fill in project-specific conventions here)

## Material Palette

(Fill in shared materials here)

## Collision Export Convention

Each task should export collision data in a standard format that the composer task
can collect and integrate.
SPECEOF

    # Create .gitignore for swarm artifacts
    cat > "$swarm_path/.gitignore" << 'GIEOF'
# Lock files are ephemeral
claimed/*.lock
# Worktrees are managed by git
worktrees/
GIEOF

    echo "Created .swarm/ with:"
    echo "  tasks/     — task definition files"
    echo "  claimed/   — claim lock files"
    echo "  worktrees/ — git worktree checkouts"
    echo "  SPEC.md    — shared project specification"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .swarm/SPEC.md with your project conventions"
    echo "  2. Add tasks with: swarm task add \"Task Title\""
    echo "  3. Generate agent prompt with: swarm prompt"
}
