#!/usr/bin/env bash
# swarm prompt — generate startup prompt for a fresh Claude Code instance

swarm_prompt() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local swarm_path="$project_root/.swarm"
    local tasks_dir="$swarm_path/tasks"

    # Count available tasks
    local available_tasks=""
    for f in "$tasks_dir"/*.md; do
        [[ -f "$f" ]] || continue
        local num status
        num="$(basename "$f" .md)"
        status="$(grep -m1 '^Status:' "$f" | sed 's/^Status: //')"
        if [[ "$status" == "available" ]] && [[ ! -f "$swarm_path/claimed/$num.lock" ]]; then
            local title
            title="$(head -1 "$f" | sed 's/^# Task [0-9]*: //')"
            available_tasks="$available_tasks  - Task $num: $title\n"
        fi
    done

    if [[ -z "$available_tasks" ]]; then
        echo "No available tasks. All tasks are claimed or complete."
        return 1
    fi

    # Read the spec file for embedding
    local spec_content=""
    if [[ -f "$swarm_path/SPEC.md" ]]; then
        spec_content="$(cat "$swarm_path/SPEC.md")"
    fi

    cat << PROMPTEOF
You are a parallel build agent in a swarm orchestration. Follow these steps exactly:

## Step 1: Claim a Task

Run this command to claim the next available task:
\`\`\`bash
$(cd "$project_root" && pwd)/swarm claim
\`\`\`

If you want a specific task, run:
\`\`\`bash
$(cd "$project_root" && pwd)/swarm claim <N>
\`\`\`

Available tasks:
$(echo -e "$available_tasks")

## Step 2: Read Your Task

After claiming, read your task definition file:
\`\`\`
.swarm/tasks/<N>.md
\`\`\`

Read the shared specification:
\`\`\`
.swarm/SPEC.md
\`\`\`

## Step 3: Work in Your Worktree

The claim command creates a git worktree at \`.swarm/worktrees/task-<N>/\`.
All your file edits MUST be within that worktree directory.

**CRITICAL: File Ownership**
- You may ONLY create/modify files listed in your task's "File Ownership" section
- You may READ files listed in "Shared Read" but NEVER modify them
- If you need a file not in your ownership list, coordinate through the spec

## Step 4: Build

Implement everything described in your task's Objective and Acceptance Criteria.
Follow all conventions from SPEC.md (materials, coordinates, collision format, etc).

## Step 5: Validate and Complete

When done, commit your work and run:
\`\`\`bash
cd $(cd "$project_root" && pwd)
./swarm validate <N>
./swarm complete <N>
\`\`\`

## Rules

1. NEVER modify files outside your ownership list
2. ALWAYS use the material palette from SPEC.md
3. ALWAYS export collision data in the standard format
4. Commit frequently with descriptive messages
5. If blocked, describe what you need in a comment in your task file
PROMPTEOF
}
