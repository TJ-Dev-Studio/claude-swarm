#!/usr/bin/env bash
# swarm status — show overview of all tasks

swarm_status() {
    local project_root
    project_root="$(find_project_root)" || { echo "Error: No .swarm/ found. Run 'swarm init' first."; exit 1; }
    local tasks_dir="$project_root/.swarm/tasks"
    local claimed_dir="$project_root/.swarm/claimed"

    local total=0 available=0 claimed=0 complete=0

    echo "=== Swarm Status ==="
    echo ""

    if [[ ! -d "$tasks_dir" ]] || [[ -z "$(ls -A "$tasks_dir" 2>/dev/null)" ]]; then
        echo "No tasks defined."
        return 0
    fi

    printf "%-6s %-12s %-30s %s\n" "TASK" "STATUS" "TITLE" "BRANCH"
    printf "%-6s %-12s %-30s %s\n" "----" "------" "-----" "------"

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

        local title status branch
        title="$(head -1 "$f" | sed 's/^# Task [0-9]*: //')"
        status="$(grep -m1 '^Status:' "$f" | sed 's/^Status: //')"
        branch="$(grep -m1 '^Branch:' "$f" | sed 's/^Branch: //')"

        # Reconcile with lock file
        if [[ -f "$claimed_dir/$num.lock" ]] && [[ "$status" != "complete" ]]; then
            status="claimed"
        fi

        total=$((total + 1))
        case "$status" in
            available) available=$((available + 1)) ;;
            claimed)   claimed=$((claimed + 1)) ;;
            complete)  complete=$((complete + 1)) ;;
        esac

        printf "%-6s %-12s %-30s %s\n" "$num" "$status" "${title:0:30}" "$branch"
    done

    echo ""
    echo "Total: $total | Available: $available | Claimed: $claimed | Complete: $complete"
}
