#!/usr/bin/env bash
# swarm merge N — merge completed task worktree to main branch

swarm_merge() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local tasks_dir="$project_root/.swarm/tasks"

    local task_num="${1:?Usage: swarm merge <N>}"
    local task_file="$tasks_dir/$task_num.md"

    if [[ ! -f "$task_file" ]]; then
        echo "Error: Task $task_num does not exist."
        return 1
    fi

    local status
    status="$(grep -m1 '^Status:' "$task_file" | sed 's/^Status: //')"
    if [[ "$status" != "complete" ]]; then
        echo "Error: Task $task_num is not marked complete (status: $status)."
        echo "Run 'swarm complete $task_num' first."
        return 1
    fi

    local branch
    branch="$(grep -m1 '^Branch:' "$task_file" | sed 's/^Branch: //')"

    local current_branch
    current_branch="$(cd "$project_root" && git branch --show-current)"

    echo "Merging task $task_num ($branch) into $current_branch..."

    # Ensure worktree changes are committed
    local worktree_path="$project_root/.swarm/worktrees/task-$task_num"
    if [[ -d "$worktree_path" ]]; then
        local uncommitted
        uncommitted="$(cd "$worktree_path" && git status --porcelain 2>/dev/null || echo "")"
        if [[ -n "$uncommitted" ]]; then
            echo "Error: Worktree has uncommitted changes. Commit them first."
            echo "$uncommitted"
            return 1
        fi
    fi

    # Merge the branch
    (cd "$project_root" && git merge "$branch" --no-ff -m "swarm: merge task $task_num — $(head -1 "$task_file" | sed 's/^# Task [0-9]*: //')") || {
        echo "Merge conflict detected. Resolve manually, then run:"
        echo "  cd $project_root && git merge --continue"
        return 1
    }

    # Clean up worktree
    if [[ -d "$worktree_path" ]]; then
        echo "Removing worktree..."
        (cd "$project_root" && git worktree remove "$worktree_path" 2>/dev/null) || true
    fi

    # Remove claim lock
    rm -f "$project_root/.swarm/claimed/$task_num.lock"

    echo "Task $task_num merged successfully."
}
