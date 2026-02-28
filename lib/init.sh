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

    # Resolve absolute project path
    local abs_project_dir
    abs_project_dir="$(cd "$project_dir" && pwd)"

    # Create CLAUDE.md — the self-contained agent instructions
    cat > "$swarm_path/CLAUDE.md" << CLAUDEEOF
# Swarm Agent Instructions

You are a parallel build agent. Your job is to claim a task and build it. Do NOT
ask the user which task to work on — just claim the next available one automatically.

## Step 1: Claim a task immediately

Run these commands now. Do not ask the user, do not show a menu, just run them:
\`\`\`bash
cd $abs_project_dir && $SWARM_DIR/swarm claim
\`\`\`

If the output says "No available tasks to claim", tell the user
"All swarm tasks are claimed or complete. Nothing for me to do." and STOP.

## Step 2: Read your task and the shared spec

After claiming, read both of these files (use absolute paths):
- Your task: \`$abs_project_dir/.swarm/tasks/<N>.md\`
- Shared spec: \`$abs_project_dir/.swarm/SPEC.md\`

(N is the task number from the claim output)

## Step 3: Build in your worktree

The claim command created a worktree at \`.swarm/worktrees/task-<N>/\`.
All your file edits MUST go in that worktree directory, not the main repo.
The absolute path is: \`$abs_project_dir/.swarm/worktrees/task-<N>/\`

Build everything described in your task's Objective and Acceptance Criteria.

## Step 4: Complete

When done, commit your work in the worktree, then run:
\`\`\`bash
cd $abs_project_dir && $SWARM_DIR/swarm complete <N>
\`\`\`

## Rules

1. **Do not ask the user what to do** — claim automatically and start building.
2. **File Ownership** — ONLY create/modify files listed in your task's "File Ownership" section.
3. **Shared Spec** — Follow all conventions in \`.swarm/SPEC.md\`. Never modify it.
4. **Worktree Isolation** — All edits in the worktree, not the main repo.
5. **Commit Often** — Frequent commits with descriptive messages.
6. **Collision Data** — If your task has collidable geometry, export collision boxes per SPEC.md.
CLAUDEEOF

    # Create .gitignore for swarm artifacts
    cat > "$swarm_path/.gitignore" << 'GIEOF'
# Lock files are ephemeral
claimed/*.lock
# Worktrees are managed by git
worktrees/
GIEOF

    echo "Created .swarm/ with:"
    echo "  CLAUDE.md  — agent instructions (tell Claude to read this)"
    echo "  SPEC.md    — shared project specification"
    echo "  tasks/     — task definition files"
    echo "  claimed/   — claim lock files"
    echo "  worktrees/ — git worktree checkouts"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .swarm/SPEC.md with your project conventions"
    echo "  2. Add tasks with: swarm task add \"Task Title\""
    echo "  3. Tell each fresh Claude instance: \"read .swarm/CLAUDE.md\""
}
