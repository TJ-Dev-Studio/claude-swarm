# claude-swarm

Orchestrate parallel Claude Code instances across a shared codebase.

## Quick Start

```bash
# Clone
git clone https://github.com/TJ-Dev-Studio/claude-swarm.git
cd claude-swarm

# In your project directory
/path/to/claude-swarm/swarm init

# Define tasks
/path/to/claude-swarm/swarm task add "Build terrain"
/path/to/claude-swarm/swarm task add "Build trees"
# ... edit each .swarm/tasks/N.md with details

# Generate the prompt for each Claude instance
/path/to/claude-swarm/swarm prompt
# Copy the output, paste into each fresh Claude Code session
```

## What It Does

When a project is too large for one Claude Code session, claude-swarm lets you split it into parallel tasks:

1. **Define tasks** with clear file ownership boundaries
2. **Share conventions** via a spec file all agents reference
3. **Claim and lock** tasks so agents don't collide
4. **Work in isolation** using git worktrees
5. **Validate and merge** completed work sequentially

## Commands

| Command | Description |
|---------|-------------|
| `swarm init` | Create `.swarm/` directory structure |
| `swarm task add "Title"` | Add a new task |
| `swarm task list` | List all tasks |
| `swarm claim [N]` | Claim next available (or specific) task |
| `swarm status` | Overview of all tasks |
| `swarm prompt` | Generate startup prompt for a new Claude |
| `swarm validate N` | Check file ownership compliance |
| `swarm complete N` | Mark task as done |
| `swarm merge N` | Merge task branch into main |

## Task File Format

Each task in `.swarm/tasks/N.md`:

```markdown
# Task 1: Build Terrain
Status: available
Branch: swarm/task-1-build-terrain

## Objective
What to build.

## File Ownership (exclusive write access)
- scenes/terrain/

## Acceptance Criteria
- [ ] Ground plane created
- [ ] Paths rendered
```

## License

MIT
