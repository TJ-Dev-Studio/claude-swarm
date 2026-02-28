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

    # Create CLAUDE.md — the self-contained agent instructions
    cat > "$swarm_path/CLAUDE.md" << CLAUDEEOF
# Swarm Agent Instructions

You are a parallel build agent. This project uses **claude-swarm** to split large
builds across multiple Claude Code instances. Each agent claims a task, works in
an isolated git worktree, and only modifies files it owns.

## Swarm CLI

The swarm CLI is located at:
\`\`\`
$SWARM_DIR/swarm
\`\`\`

## Quick Start

1. **Read the shared spec** — understand the project conventions:
   \`\`\`
   .swarm/SPEC.md
   \`\`\`

2. **See what tasks are available**:
   \`\`\`bash
   $SWARM_DIR/swarm status
   \`\`\`

3. **Claim a task** (grabs next available, creates your worktree):
   \`\`\`bash
   $SWARM_DIR/swarm claim
   \`\`\`
   Or claim a specific task:
   \`\`\`bash
   $SWARM_DIR/swarm claim <N>
   \`\`\`

4. **Read your task definition** for full details:
   \`\`\`
   .swarm/tasks/<N>.md
   \`\`\`

5. **Work in your worktree** — all edits go here:
   \`\`\`
   .swarm/worktrees/task-<N>/
   \`\`\`

6. **When finished**, commit your work, then:
   \`\`\`bash
   $SWARM_DIR/swarm complete <N>
   \`\`\`

## Rules

1. **File Ownership** — You may ONLY create/modify files listed in your task's
   "File Ownership" section. Read anything, but write only what you own.
2. **Shared Spec** — Follow all conventions in \`.swarm/SPEC.md\` (materials,
   coordinates, naming, collision format). Never modify SPEC.md.
3. **Worktree Isolation** — All your file edits MUST be within your worktree
   directory (\`.swarm/worktrees/task-<N>/\`), not the main repo.
4. **Commit Often** — Make frequent commits with descriptive messages.
5. **Collision Data** — If your task produces collidable geometry, export it
   using the format specified in SPEC.md.

## How It Works

- Each task has a \`.md\` file in \`.swarm/tasks/\` with: objective, file ownership,
  acceptance criteria, and branch name.
- \`swarm claim\` creates a lock file (\`.swarm/claimed/N.lock\`) so no other agent
  can grab the same task, and creates an isolated git worktree on a dedicated branch.
- When all tasks are done, the orchestrator merges branches sequentially.

## Available Commands

| Command | Description |
|---------|-------------|
| \`swarm status\` | Show all tasks and their state |
| \`swarm claim [N]\` | Claim next (or specific) task |
| \`swarm complete N\` | Mark task as done |
| \`swarm validate N\` | Check file ownership compliance |
| \`swarm task list\` | List tasks |
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
