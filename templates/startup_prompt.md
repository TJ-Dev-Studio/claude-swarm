# Swarm Agent Startup Prompt Template

This template is used by `swarm prompt` to generate the text pasted into each fresh Claude instance.

## Variables

- `{{PROJECT_ROOT}}` — absolute path to the project
- `{{AVAILABLE_TASKS}}` — formatted list of unclaimed tasks
- `{{SPEC_CONTENT}}` — contents of .swarm/SPEC.md

## Template

The prompt tells each agent to:
1. Claim a task via `swarm claim`
2. Read their task file + shared spec
3. Work exclusively in their worktree
4. Respect file ownership boundaries
5. Export collision/integration data in the standard format
6. Validate and mark complete when done
