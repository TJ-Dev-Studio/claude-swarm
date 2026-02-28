#!/usr/bin/env bash
# swarm validate N — check file ownership and no conflicts

swarm_validate() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local tasks_dir="$project_root/.swarm/tasks"

    local task_num="${1:?Usage: swarm validate <N>}"
    local task_file="$tasks_dir/$task_num.md"

    if [[ ! -f "$task_file" ]]; then
        echo "Error: Task $task_num does not exist."
        return 1
    fi

    local branch
    branch="$(grep -m1 '^Branch:' "$task_file" | sed 's/^Branch: //')"

    echo "Validating task $task_num..."

    # Get list of owned files from task definition
    local in_ownership=false
    local owned_files=()
    while IFS= read -r line; do
        if [[ "$line" == "## File Ownership"* ]]; then
            in_ownership=true
            continue
        elif [[ "$line" == "## "* ]] && $in_ownership; then
            break
        elif $in_ownership && [[ "$line" == "- "* ]]; then
            local file_path
            file_path="$(echo "$line" | sed 's/^- //' | sed 's/ (.*//')"
            owned_files+=("$file_path")
        fi
    done < "$task_file"

    # Get files changed in the branch
    local worktree_path="$project_root/.swarm/worktrees/task-$task_num"
    local errors=0

    if [[ -d "$worktree_path" ]]; then
        local changed_files
        changed_files="$(cd "$worktree_path" && git diff --name-only HEAD~1..HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null || echo "")"

        if [[ -n "$changed_files" ]]; then
            while IFS= read -r changed; do
                local is_owned=false
                for owned in "${owned_files[@]}"; do
                    # Check if changed file matches an owned path (supports directory patterns)
                    if [[ "$changed" == "$owned"* ]] || [[ "$changed" == *"$owned"* ]]; then
                        is_owned=true
                        break
                    fi
                done
                if ! $is_owned; then
                    echo "WARNING: $changed was modified but is not in file ownership list"
                    errors=$((errors + 1))
                fi
            done <<< "$changed_files"
        fi
    else
        echo "Warning: Worktree not found at $worktree_path"
        echo "Checking branch $branch instead..."
    fi

    # Check for conflicts with other branches
    local main_branch
    main_branch="$(cd "$project_root" && git symbolic-ref --short HEAD 2>/dev/null || echo "main")"

    if [[ $errors -eq 0 ]]; then
        echo "Validation passed. No file ownership violations detected."
        return 0
    else
        echo ""
        echo "Validation found $errors warning(s)."
        echo "Review the warnings above. Files outside your ownership may conflict with other agents."
        return 1
    fi
}
