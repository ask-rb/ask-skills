# ask-skills

[![Gem Version](https://badge.fury.io/rb/ask-skills.svg)](https://badge.fury.io/rb/ask-skills)

Discover, validate, and load agent skills for the ask-rb ecosystem. A skill
is a markdown file with step-by-step methodology for a domain task. Skills are
listed in the agent's system prompt (name + description) and loaded on demand
when the agent decides it needs domain guidance. Ships built-in skills
(`skill.design`, `skill.compose`).

## Installation

```ruby
gem "ask-skills"
```

## Quick Start

```ruby
require "ask/skills"

# Discover skills from project, user config, gems, and built-ins
registry = Ask::Skills.discover
registry.names   # => ["skill.compose", "skill.design", ...]

# Get a skill by name
skill = registry["skill.design"]
skill.name         # => "skill.design"
skill.description  # => "How to design and write effective skills..."
skill.instructions # => markdown body with step-by-step methodology

# Include per-agent skills too
registry = Ask::Skills.discover(agent_dir: "agents/health_check")
```

## Where Skills Live

Project skills live in `agents/shared/skills/` (or `app/agents/shared/skills/`
in Rails), per-agent skills in `agents/<name>/skills/`, user skills in
`~/.config/ask/skills/`, and gems ship skills under `ask/skills/*/SKILL.md`.

```
agents/shared/skills/
└── db_debug/
    └── SKILL.md          # project-shared skill

agents/health_check/skills/
└── nginx_debug/
    ┗── SKILL.md          # per-agent skill

~/.config/ask/skills/
└── my_workflow/
    └── SKILL.md          # user-global skill
```

When the same skill name exists in multiple places, the first source wins:
per-agent > shared project (Rails included) > user > gems > built-in. Place a
skill with the same name in a higher-priority location to override it.

## Skill Format

```markdown
---
name: db_debug
description: Step-by-step methodology for debugging database issues
tags: database, debugging
version: 1
author: your-team
always: true
---

When investigating database performance issues, follow these steps...
```

`always: true` auto-injects the full instructions into the system prompt
instead of listing the skill for on-demand loading.

## Essential API

| Entry point | Purpose |
|---|---|
| `Ask::Skills.discover(agent_dir: nil, sources: nil)` | Build a `Registry` from all sources in priority order |
| `registry["name"]` | Look up a skill by name |
| `registry.names` | List all skill names |
| `registry.skills` | Hash of name to `Skill` |
| `Ask::Skills::Skill` | Data object: `name`, `description`, `instructions`, `source`, `metadata`, `siblings` (references, scripts, assets) |
| `askr skills <list\|show\|search>` | CLI (from ask-agent) for inspecting available skills |

## Full documentation

The full ask-rb documentation lives at https://ask-rb.github.io/ask-docs.
https://ask-rb.github.io/ask-docs/core/skills covers ask-skills in depth,
including custom sources, the validator, and formatting for system prompts.
API reference: https://ask-rb.github.io/ask-docs/reference/api.

## Development

bundle install
bundle exec rake test

## License

MIT
