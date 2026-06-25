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
