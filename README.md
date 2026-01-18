# Tisktask

**Write code, not executable configuration files.**

Tisktask is a CI/CD task orchestration platform that runs containerized jobs triggered by GitHub and Forgejo webhooks. Unlike traditional task runners that lock you into proprietary YAML formats, Tisktask uses conventions over configuration—place executable files in conventional locations and let the engine handle the rest.

## Why Tisktask?

Traditional CI/CD systems promise simplicity but trap you in:
- Proprietary configuration formats
- Scripts embedded in YAML that are impossible to test
- Shared actions with cryptic syntax errors
- Walled gardens that sell you compute time

Tisktask takes a different approach: your build process should be as testable and maintainable as your application code. Use your favorite package manager to share code, write library folders, and structure tasks the way you would structure production software.

## How It Works

Place executable files in `.tisktask/{event_type}/` directories:

```
.tisktask/
├── push/
│   ├── test           # Runs on push events
│   └── build
├── pull_request/
│   └── lint           # Runs on PR events
└── Dockerfile         # Container build file
```

Tisktask discovers jobs automatically and runs each in an isolated Podman container.

## Getting Started

### Requirements

- Elixir 1.14+
- PostgreSQL
- Podman

### Setup

```bash
# Install dependencies and setup database
mix setup

# Start the server
mix phx.server
```

Visit [localhost:4000](http://localhost:4000) to configure your repositories and webhooks.

## Development

```bash
# Run tests
mix test

# Run specific test file
mix test path/to/test.exs

# Code quality checks
mix credo      # Static analysis
mix sobelow    # Security analysis

# Run all precommit checks
mix precommit
```

## Documentation

Visit [tisktask.dev](https://tisktask.dev) for full documentation.

## License

See [LICENSE](LICENSE) for details.
