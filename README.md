# ask-skills

[![Gem Version](https://badge.fury.io/rb/ask-skills.svg)](https://badge.fury.io/rb/ask-skills)

Discover, validate, and load agent skills from project directories, user config,
and installed gems. Ships built-in skills for codebase exploration and debugging
methodology.

A **skill** is a markdown file containing step-by-step methodology for a specific
domain task. It's listed in the agent's system prompt (just name + description)
and loaded on-demand when the agent decides it needs domain guidance.

## Installation

```ruby
gem "ask-skills"
```

Then:

```ruby
require "ask/skills"
```

## Quick Start

```ruby
# Discover all available skills
registry = Ask::Skills.discover
# => Finds skills from:
#    - Built-in skills (skill.design, skill.compose)
#    - Installed gems (ask-rails, ask-github, etc.)
#    - .agents/skills/*/ in the project
#    - ~/.config/ask/skills/*/ in home dir

# List available skills
registry.names
# => ["skill.compose", "skill.design"]

# Get a skill by name
skill = registry["skill.design"]
skill.name         # => "skill.design"
skill.description  # => "How to design and write effective skills for the ask-rb ecosystem"
skill.instructions # => markdown body with step-by-step methodology

# Format for system prompt
registry.format_for_prompt
# => "## Available Skills\n\n- **skill.design**: How to design..."

# XML format for machine parsing
formatter = Ask::Skills::Formatter.new(registry)
formatter.to_xml
# => "<available_skills><skill><name>skill.design</name>..."

# Validate skills
errors = Ask::Skills::Validator.new(registry.skills.values).validate_all
```

## Priority Resolution

When the same skill name exists in multiple places, priority determines which
one is used. **First source wins:**

| Priority | Source | Location |
|----------|--------|----------|
| 1 (highest) | Project-local | `.agents/skills/<name>/SKILL.md` |
| 2 | User-global | `~/.config/ask/skills/<name>/SKILL.md` |
| 3 | Installed gems | `Gem.find_files("ask/skills/*/SKILL.md")` |
| 4 (lowest) | Built-in | Shipped with ask-skills gem |

This means you can override any skill by placing a file with the same name in
your project's `.agents/skills/` directory.

## Skill Directory Convention

```
.agents/skills/
├── db_debug/
│   └── SKILL.md          ← project-local skill
├── deploy/
│   └── SKILL.md
└── custom_check/
    └── SKILL.md

~/.config/ask/skills/
├── my_workflow/
│   └── SKILL.md          ← user-global skill
└── team_patterns/
    └── SKILL.md

# From installed gems:
ask-rails-0.2.0/lib/ask/skills/
├── rails.db_debug/SKILL.md
└── rails.deploy_pipeline/SKILL.md

ask-github-0.1.0/lib/ask/skills/
├── github.pr_review/SKILL.md
└── github.issue_triage/SKILL.md
```

## Skill Format

```markdown
---
name: rails.db_debug
description: Step-by-step methodology for debugging database issues in Rails
---

When investigating database performance issues, follow these steps:

1. **Understand the Schema** — Use ReadModel to inspect...
2. **Check Indexes** — Query pg_indexes for missing indexes...
3. **Explain Slow Queries** — Use EXPLAIN ANALYZE on...
```

## Built-in Skills

| Skill | Description |
|-------|-------------|
| `skill.design` | How to design and write effective skills for the ask-rb ecosystem |
| `skill.compose` | How skills interact, combine, and resolve in the ask-rb ecosystem |

## API Reference

### `Ask::Skills.discover(sources: nil)`

Returns a `Registry` with skills from all sources, in priority order.
Pass `sources:` to override with custom sources.

### `Ask::Skills::Registry`

| Method | Description |
|--------|-------------|
| `[]` | Lookup skill by name |
| `names` | List all skill names |
| `skills` | Hash of name → Skill |
| `format_for_prompt` | Generate markdown section |

### `Ask::Skills::Skill` (Data.define)

| Attribute | Description |
|-----------|-------------|
| `name` | Unique identifier (e.g. `rails.db_debug`) |
| `description` | One-line summary for system prompt |
| `instructions` | Full markdown methodology body |
| `source` | File path the skill was loaded from |

### `Ask::Skills::Formatter`

| Method | Description |
|--------|-------------|
| `to_prompt_section` | Markdown format for system prompt |
| `to_xml` | XML format for machine parsing |

### `Ask::Skills::Validator`

| Method | Description |
|--------|-------------|
| `validate_all` | Validate all skills, return errors |
| `validate` | Validate a single skill |

## Custom Sources

```ruby
require "ask/skills"

# Custom filesystem source
custom = Ask::Skills::Source::Filesystem.new(dir: "/path/to/skills")
registry = Ask::Skills.discover(sources: [custom])
```

## Gems That Ship Skills

| Gem | Planned Skills |
|---|---|
| `ask-skills` (built-in) | skill.design, skill.compose |
| `ask-rails` | rails.db_debug, rails.route_trouble, rails.deploy_pipeline |
| `ask-github` | github.pr_review, github.issue_triage |
| `ask-slack` | slack.compose |
| `ask-tools-shell` | shell.patterns |
| `ask-llm-providers` | providers.model_select |

## Development

```bash
bundle install
bundle exec rake test
```

## License

MIT
