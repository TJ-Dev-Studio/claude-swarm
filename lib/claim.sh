#!/usr/bin/env bash
# swarm claim [N] — claim a task and set up worktree
# swarm complete N — mark a task as complete

swarm_claim() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local tasks_dir="$project_root/.swarm/tasks"
    local claimed_dir="$project_root/.swarm/claimed"

    local task_num="${1:-}"

    # If no task number given, find the first available
    if [[ -z "$task_num" ]]; then
        for f in "$tasks_dir"/*.md; do
            [[ -f "$f" ]] || continue
            local num
            num="$(basename "$f" .md)"
            local status
            status="$(grep -m1 '^Status:' "$f" | sed 's/^Status: //')"
            if [[ "$status" == "available" ]] && [[ ! -f "$claimed_dir/$num.lock" ]]; then
                task_num="$num"
                break
            fi
        done
        if [[ -z "$task_num" ]]; then
            echo "No available tasks to claim."
            return 1
        fi
    fi

    local task_file="$tasks_dir/$task_num.md"
    if [[ ! -f "$task_file" ]]; then
        echo "Error: Task $task_num does not exist."
        return 1
    fi

    # Check if already claimed
    if [[ -f "$claimed_dir/$task_num.lock" ]]; then
        echo "Error: Task $task_num is already claimed."
        cat "$claimed_dir/$task_num.lock"
        return 1
    fi

    # Get branch name from task file
    local branch
    branch="$(grep -m1 '^Branch:' "$task_file" | sed 's/^Branch: //')"
    if [[ -z "$branch" ]]; then
        branch="swarm/task-$task_num"
    fi

    # Create claim lock
    cat > "$claimed_dir/$task_num.lock" << LOCKEOF
Claimed: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Agent: $(whoami)@$(hostname)
PID: $$
Branch: $branch
LOCKEOF

    # Update status in task file
    sed -i '' "s/^Status: available/Status: claimed/" "$task_file" 2>/dev/null || \
    sed -i "s/^Status: available/Status: claimed/" "$task_file"

    # Create git worktree
    local worktree_path="$project_root/.swarm/worktrees/task-$task_num"
    if [[ ! -d "$worktree_path" ]]; then
        echo "Creating worktree at: $worktree_path"
        (cd "$project_root" && git worktree add "$worktree_path" -b "$branch" 2>/dev/null) || \
        (cd "$project_root" && git worktree add "$worktree_path" "$branch" 2>/dev/null) || \
        echo "Warning: Could not create worktree. You may need to create it manually."
    fi

    local title
    title="$(head -1 "$task_file" | sed 's/^# Task [0-9]*: //')"

    echo "Claimed task $task_num: $title"
    echo "  Branch: $branch"
    echo "  Worktree: $worktree_path"
    echo ""
    echo "Your working directory: $worktree_path"
    echo "Read the task file for details: $task_file"
    echo "Read the shared spec: $project_root/.swarm/SPEC.md"
}

swarm_complete() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local tasks_dir="$project_root/.swarm/tasks"
    local claimed_dir="$project_root/.swarm/claimed"

    local task_num="${1:?Usage: swarm complete <N>}"
    local task_file="$tasks_dir/$task_num.md"

    if [[ ! -f "$task_file" ]]; then
        echo "Error: Task $task_num does not exist."
        return 1
    fi

    # Update status
    sed -i '' "s/^Status: claimed/Status: complete/" "$task_file" 2>/dev/null || \
    sed -i "s/^Status: claimed/Status: complete/" "$task_file"

    echo "Task $task_num marked as complete."
    echo "Run 'swarm validate $task_num' then 'swarm merge $task_num' to integrate."
}
