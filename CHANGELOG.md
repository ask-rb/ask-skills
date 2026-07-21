## [0.4.0] - 2026-07-21

### Added

- **Enhanced frontmatter** — skill metadata now supports `tags`, `version`, `author`, and any custom fields alongside `name` and `description`. Frontmatter parser handles multi-line values and preserves all metadata in `skill.metadata`.

  ```markdown
  ---
  name: rails_debug
  description: Debug Rails database issues
  tags: rails, database, debugging
  version: 2
  ---
  ```

- **Sibling files in skills** — skills now discover sibling files and directories in the skill directory alongside `SKILL.md`. Recognized categories are discovered automatically: `references/`, `scripts/`, `assets/`. Unrecognized directories and flat files are also collected.

  ```
  rails_debug/
  ├── SKILL.md           → instructions
  ├── references/
  │   ├── migration_guide.md
  │   └── apis.md
  └── scripts/
      └── db_check.sh
  ```

  Accessible at runtime via `skill.references`, `skill.scripts`, `skill.assets`, and `skill.siblings`.

- **XML formatter** now includes `<tags>` and `<siblings>` sections when present. Markdown prompt entries show tags inline (`[rails, database]`).

- **`askr skills` CLI commands** — new `askr` subcommands for managing skills:

  ```bash
  askr skills list              # All skills with descriptions and tags
  askr skills show rails_debug  # Full details + instructions + siblings
  askr skills search deploy     # Filter by name, description, or tags
  ```

### Changed

- `Skill` data object now includes `metadata` (Hash) and `siblings` (Hash) fields with default empty values. Backward compatible — existing `Skill.new(...)` calls without these fields get empty defaults.
- `Source::Filesystem#parse_frontmatter` rewritten to support multi-line values and arbitrary metadata keys (not just `name`/`description`).
- `Ask::Skills.parse_frontmatter` updated to match, with new `process_metadata_value` helper.

### Tested

- 18 new tests for: tags parsing, metadata preservation, sibling discovery (references, scripts, assets, flat files), hidden file filtering, empty sibling handling, formatter output with tags/siblings, and CLI commands.
- Full suite: 97 tests, 265 assertions — 0 failures.

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
