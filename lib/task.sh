#!/usr/bin/env bash
# swarm task add/list — manage task definitions

swarm_task_add() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local tasks_dir="$project_root/.swarm/tasks"

    # Find next task number
    local max_num=0
    for f in "$tasks_dir"/*.md; do
        [[ -f "$f" ]] || continue
        local num
        num="$(basename "$f" .md)"
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num > max_num )); then
            max_num=$num
        fi
    done
    local next_num=$(( max_num + 1 ))

    local title="${1:-Task $next_num}"
    local slug
    slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"

    local task_file="$tasks_dir/$next_num.md"

    cat > "$task_file" << TASKEOF
# Task $next_num: $title
Status: available
Agent:
Branch: swarm/task-$next_num-$slug

## Objective

(Describe what this agent builds)

## File Ownership (exclusive write access)

- (list files this agent owns)

## Shared Read (read-only reference)

- .swarm/SPEC.md

## Inputs

(What this agent needs from the shared spec or other tasks)

## Outputs

(What this agent produces — scenes, scripts, collision data)

## Acceptance Criteria

- [ ] (Criterion 1)
- [ ] (Criterion 2)
TASKEOF

    echo "Created task $next_num: $title"
    echo "  File: $task_file"
    echo "  Branch: swarm/task-$next_num-$slug"
    echo ""
    echo "Edit the task file to fill in details, then run 'swarm prompt' to generate agent instructions."
}

swarm_task_list() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local tasks_dir="$project_root/.swarm/tasks"
    local claimed_dir="$project_root/.swarm/claimed"

    if [[ ! -d "$tasks_dir" ]] || [[ -z "$(ls -A "$tasks_dir" 2>/dev/null)" ]]; then
        echo "No tasks defined yet. Use 'swarm task add \"Title\"' to create one."
        return 0
    fi

    printf "%-6s %-12s %s\n" "TASK" "STATUS" "TITLE"
    printf "%-6s %-12s %s\n" "----" "------" "-----"

    # Collect and sort task numbers numerically
    local sorted_nums=()
    for f in "$tasks_dir"/*.md; do
        [[ -f "$f" ]] || continue
        local n
        n="$(basename "$f" .md)"
        [[ "$n" =~ ^[0-9]+$ ]] || continue
        sorted_nums+=("$n")
    done
    IFS=$'\n' sorted_nums=($(printf '%s\n' "${sorted_nums[@]}" | sort -n)); unset IFS

    for num in "${sorted_nums[@]}"; do
        local f="$tasks_dir/$num.md"

        local title status
        title="$(head -1 "$f" | sed 's/^# Task [0-9]*: //')"
        status="$(grep -m1 '^Status:' "$f" | sed 's/^Status: //')"

        # Check for claim lock
        if [[ -f "$claimed_dir/$num.lock" ]]; then
            status="claimed"
        fi

        printf "%-6s %-12s %s\n" "$num" "$status" "$title"
    done
}
