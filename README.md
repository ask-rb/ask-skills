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

## Quick Start

```ruby
require "ask/skills"

# Discover all available skills
registry = Ask::Skills.discover
# => Finds skills from:
#    - Built-in skills (skill.design, skill.compose)
#    - Installed gems (ask-rails, ask-github, etc.)
#    - .agents/skills/*/ in the project
#    - ~/.config/ask/skills/*/ in home dir

# List available skills
registry.names
# => ["explore_codebase", "debug_methodology", "rails_db", "pr_review"]

# Get a skill by name
skill = registry["explore_codebase"]
skill.name         # => "explore_codebase"
skill.description  # => "Step-by-step methodology for understanding a new codebase"
skill.instructions # => markdown body

# Format for system prompt
registry.format_for_prompt
# => "## Available Skills\n\n- **explore_codebase**: Step-by-step..."
```

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
├── rails_db/SKILL.md
└── rails_deploy/SKILL.md

ask-github-0.1.0/lib/ask/skills/
├── pr_review/SKILL.md
└── issue_triage/SKILL.md
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

## Gems That Ship Skills

| Gem | Skills |
|---|---|
| `ask-skills` (built-in) | skill.design, skill.compose |
| `ask-rails` | rails_db, rails_debug, rails_deploy |
| `ask-github` | pr_review, issue_triage |
| `ask-slack` | slack_compose |
| `ask-tools-shell` | shell_patterns |
| `ask-llm-providers` | model_select |

## Integration with ask-agent

```ruby
require "ask/agent"
require "ask/skills"

# Skills are auto-discovered on agent init
agent = Ask::Agent.new(model: "claude-sonnet-4")

# System prompt includes skill list
# "Available skills: skill.design, skill.compose, rails_db..."
# (Full instructions are NOT in the prompt — just names + descriptions)

# Agent can load a skill on demand when it needs domain guidance
# The skill's full instructions are injected as a prompt
```

## License

MIT
