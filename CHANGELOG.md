# Changelog

## [0.1.0] - 2026-06-10

### Added
- Initial release
- `Ask::Skills::Skill` — Data.define with name, description, instructions, source
  - `to_s` and `to_prompt_entry` formatting methods
- `Ask::Skills::Registry` — holds discovered skills with:
  - `[]` lookup, `names` list, `format_for_prompt` markdown output
  - Priority resolution: first source wins
- `Ask::Skills::Formatter` — generates markdown and XML output
- `Ask::Skills::Validator` — validates required fields, name format, duplicates
- `Ask::Skills.discover` — discover skills from all configured sources:
  1. Project-local (`.agents/skills/`) — highest priority
  2. User-global (`~/.config/ask/skills/`)
  3. Installed gems (via `Gem.find_files`)
  4. Built-in (skill.design, skill.compose) — lowest priority
- `Ask::Skills::Source::Filesystem` — scan a directory for `*/SKILL.md` files
- `Ask::Skills::Source::Gems` — discover skills from all installed gems
- Built-in skills:
  - `skill.design` — How to design and write effective skills
  - `skill.compose` — How skills interact, combine, and resolve
- Full test suite with 68 tests
- Frontmatter parsing (name, description, optional metadata)
- YAML frontmatter support with quoted value handling
- Error handling for missing directories, malformed skills
- Thread-safe read-only registry access
