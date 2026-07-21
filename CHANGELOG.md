## [0.3.0] - 2026-07-21

### Added

- **New discovery paths** — skills are now discovered from `agents/shared/skills/` and `app/agents/shared/skills/` alongside the legacy `.agents/skills/`. These paths follow the existing `agents/` convention already established for agent definitions.

  ```
  agents/
  ├── health_check/
  ├── daily_report/
  └── shared/
      ├── tools/          ← shared tools
      └── skills/         ← new: shared skills
          └── rails_debug/SKILL.md
  ```

- **Per-agent skills** — `Ask::Skills.discover(agent_dir:)` discovers skills scoped to a specific agent directory. These have highest priority over shared, legacy, user, gem, and built-in skills.

  ```
  agents/health_check/
  ├── agent.rb
  ├── instructions.md
  └── skills/             ← new: only available to health_check agent
      └── nginx_debug/SKILL.md
  ```

- **ask-agent integration** — `Ask::Agent::Session` accepts `agent_dir:` parameter. When creating a session from an agent definition via `Ask::Agent.new("name")`, per-agent skills are auto-discovered and included. No configuration needed.

### Changed

- `Ask::Skills.discover` now accepts `agent_dir:` keyword. When provided, the source list starts with the per-agent skills directory (highest priority). Shared project skills from `agents/shared/skills/` and `app/agents/shared/skills/` are included in the default source list.
- Backward compatible — legacy `.agents/skills/` continues to work.

### Tested

- 10 new integration tests: discovery from `agents/shared/skills/`, `app/agents/shared/skills/`, per-agent skills, priority ordering, backward compatibility with `.agents/skills/`, and source list verification.
- Full suite: 79 tests, 217 assertions — 0 failures.

## [0.2.2] - 2026-06-25

### Changed
- Infrastructure: rubocop, overcommit, bin/setup, CI matrix, gemspec test, .minitest config.
# Changelog

## [0.2.0] - 2026-06-10

### Added
- Skills shipped with methodology gems (ask-rails, ask-github, ask-slack,
  ask-tools-shell, ask-llm-providers) — 8 skills total
- `Ask::Skills.load_file(path)` — load any markdown file as an ad-hoc skill
- ask-agent integration: auto-discovery and system prompt injection on
  `Ask::Agent::Session` initialization
- `session.skill(name)` — load a skill by name (or file path) and inject
  its full instructions into the conversation

### Changed
- `Ask::Skills.discover` now discovers skills from methodology gem gems too
  (via `Gem.find_files`)

## [0.1.0] - 2026-06-10

### Added
- Initial release
- `Ask::Skills::Skill` — Data.define with name, description, instructions, source
- `Ask::Skills::Registry` — holds discovered skills
- `Ask::Skills::Formatter` — generates markdown and XML output
- `Ask::Skills::Validator` — validates required fields, name format, duplicates
- `Ask::Skills.discover` — discover skills from all configured sources
- Built-in skills (skill.design, skill.compose)
- Full test suite with 68 tests

## [0.2.1] - 2026-06-10

### Changed
- Replaced workflow-specific service skills with navigation-focused
  `use_{service}` skills across all 7 service gems
- Updated README to document the new naming convention
