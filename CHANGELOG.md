# Changelog

## [0.1.0] - Unreleased

### Added
- Initial release
- Skill discovery from project directories, user config, and installed gems
- `Ask::Skill` data class with name, description, instructions, source
- `Ask::Skills.discover` with priority-based resolution
- Built-in skills: explore_codebase, debug_methodology
- Prompt formatter (markdown + XML output)
- Validator with name/description/duplicate checking
- Filesystem source (`.agents/skills/*/`, `~/.config/ask/skills/*/`)
- Gem source (`Gem.find_files("ask/skills/*/SKILL.md")`)
