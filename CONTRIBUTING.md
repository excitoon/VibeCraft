# Contributing to VibeCraft

## Project Guidelines

### Repository

- The main branch is `master`.

### Intellectual Property

- VibeCraft uses its own original IP, including all graphics and animations. Do not use or reference assets from any third-party proprietary titles.
- Do not reference any protected trademarks of other companies in the codebase, documentation, or communications. In particular, never mention "WarCraft" — it is a protected trademark.

### Game Design

- The primary target is the **Chapter III: Age of Heroes** experience.
- **Chapter I: Origins** and **Chapter II: Tides of War** mechanics are supported as well.

### Technology

- The project is written in [Elixir](https://elixir-lang.org/).

### Architecture

- Clean Architecture is not used in this project and is not welcome. It is an over-engineered, impractical abstraction that creates unnecessary complexity without real-world benefit. Do not apply it.

### Code Quality

- We make no mistakes. All code must be reviewed and tested before merging.

## CI / CD

Every pull request must pass all CI checks before merging. The pipeline runs automatically on each push and on every pull request targeting `master`.

### Jobs

| Job | What it checks | Local command |
|-----|----------------|---------------|
| **Lint** | Code formatting, Credo static analysis, and retired/vulnerable Hex packages | `mix format --check-formatted && mix credo --strict && mix hex.audit` |
| **Test** | Compiles the project (including the NIF layer) and runs the test suite — executed against OTP 26/Elixir 1.16 and OTP 27/Elixir 1.17 | `mix compile --warnings-as-errors && mix test` |
| **Dialyzer** | Type correctness via Dialyxir | `mix dialyzer` |

### Running checks locally

Before opening a pull request, run the following commands from the project root:

```sh
mix format
mix credo --strict
mix hex.audit
mix compile --warnings-as-errors
mix test
mix dialyzer
```

### Pull request requirements

- All CI jobs must be green before a PR can be merged.
- The **Dialyzer** job may be slow on the first run because it builds a fresh PLT cache; subsequent runs use the cache and are much faster.
- Keep each PR focused on a single concern so that reviewers can easily assess the impact.

### License

- VibeCraft is distributed under the [MIT License](LICENSE.md).
