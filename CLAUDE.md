# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Initial setup
mix setup                    # Install deps, create DB, setup assets

# Development
mix phx.server               # Start Phoenix server (localhost:4000)
iex -S mix phx.server        # Start with interactive shell

# Testing
mix test                     # Run all tests (drops/creates/migrates DB first)
mix test path/to/test.exs    # Run specific test file
mix test path/to/test.exs:42 # Run specific test at line

# Code quality
mix credo                    # Static analysis
mix sobelow                  # Security analysis

# Database
mix ecto.migrate             # Run migrations
mix ecto.reset               # Drop, create, migrate, seed
```

## Architecture Overview

Tisktask is a CI/CD task orchestration platform that runs containerized jobs triggered by GitHub/Forgejo webhooks. Uses a **pod-per-job execution model** with Podman.

### Execution Flow

```
GitHub Webhook → Triggers.Github created → Tasks.create_run()
  → TaskRunWorker: clone repo → build image → discover jobs
  → TaskJobWorker per job: create Podman pod → run → report status back to GitHub
```

### Key Directories

- `lib/tisktask/triggers/` - GitHub webhook processing, event types, status reporting
- `lib/tisktask/tasks/` - Run/Job schemas and orchestration context
- `lib/tisktask/containers/` - Podman/Buildah container operations
- `lib/tisktask/commands/` - Unix socket IPC for containers to spawn child jobs
- `lib/tisktask/source_control/` - Repository management and Git operations
- `lib/workers/` - Oban workers (TaskRunWorker, TaskJobWorker)

### Core Patterns

**Job Discovery**: Jobs are discovered from `.tisktask/{event_type}/` in the repository:
```
.tisktask/
├── push/job1           # Runs on push events
├── pull_request/lint   # Runs on PR events
└── Dockerfile          # Container build file
```

**PubSub Events**: Contexts use `use Tisktask.PubSub` macro for real-time LiveView updates. Topics follow `"table_name:event:id"` pattern.

**Container IPC**: Containers communicate via Unix socket using Redis protocol (SPAWNJOB, EXECJOB commands) through `Tisktask.Commands.SocketListener`.

**Log Streaming**: `Tisktask.TaskLogs` streams logs to disk and publishes to PubSub for real-time UI.

### Test Utilities

- ExMachina factories in `test/support/factory/`
- Mimic for mocking system commands (Git, Podman, Buildah)
- `DataCase` provides SQL sandbox isolation
