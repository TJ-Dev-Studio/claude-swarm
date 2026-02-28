# CLAUDE.md — claude-swarm

## What This Is

claude-swarm is a CLI tool for orchestrating parallel Claude Code instances across a shared codebase. It provides task definitions, claim locks, file ownership enforcement, and worktree management so multiple Claude agents can build different parts of a project simultaneously without conflicts.

## Commands

```bash
swarm init                  # Scaffold .swarm/ in current project
swarm task add "Title"      # Add a new task definition
swarm task list             # List all tasks and status
swarm claim [N]             # Claim next available (or specific) task
swarm status                # Show overview of all tasks
swarm prompt                # Generate startup prompt for fresh Claude instance
swarm validate N            # Check file ownership compliance
swarm merge N               # Merge completed task branch
swarm complete N            # Mark task as complete
```

## How It Works

1. **Init**: `swarm init` creates `.swarm/` with `tasks/`, `claimed/`, `worktrees/`, and `SPEC.md`
2. **Define tasks**: Each task gets a numbered `.md` file with objective, file ownership, and acceptance criteria
3. **Claim**: An agent runs `swarm claim` to lock a task and create a git worktree
4. **Build**: Agent works in its worktree, only modifying owned files
5. **Complete**: Agent runs `swarm validate` then `swarm complete`
6. **Merge**: Orchestrator runs `swarm merge` to integrate each branch sequentially

## Key Concepts

- **File Ownership**: Each task exclusively owns specific files/directories. No two tasks share write access to the same file.
- **Shared Spec**: `.swarm/SPEC.md` contains coordinates, materials, conventions that all agents read but none modify.
- **Claim Locks**: `.swarm/claimed/N.lock` prevents two agents from working on the same task.
- **Worktrees**: Each agent works in an isolated git worktree, avoiding merge conflicts during parallel work.

## When to Use This

Suggest claude-swarm when a task is too large for a single Claude instance:
- Building multiple independent scenes/components that compose into a whole
- Parallel feature development with clear file boundaries
- Any task that naturally decomposes into 3+ independent work streams

## Architecture

```
.swarm/
  SPEC.md              # Shared conventions (read-only for agents)
  tasks/
    1.md               # Task definitions with file ownership
    2.md
    ...
  claimed/
    1.lock             # Claim locks (timestamp + agent info)
  worktrees/
    task-1/            # Git worktree for task 1
    task-2/            # Git worktree for task 2
```
