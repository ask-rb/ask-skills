---
name: skill.compose
description: How skills interact, combine, and resolve in the ask-rb ecosystem
---

## Skill Resolution Priority

Skills are discovered from multiple sources. When the same skill name exists in
multiple places, the first source wins:

1. **Built-in** (shipped with ask-skills gem) — lowest priority
2. **Installed gems** (ask-rails, ask-github, etc.)
3. **User-global** (`~/.config/ask/skills/`)
4. **Project-local** (`.agents/skills/` in the project) — highest priority

This means you can override any skill by placing a file with the same name in
your project's `.agents/skills/` directory. Or provide personal defaults in
`~/.config/ask/skills/`.

## How Skills Appear in the System Prompt

The agent's system prompt includes a section listing all available skills:

```
## Available Skills

- **skill.design**: How to design and write effective skills
- **rails.db_debug**: Step-by-step database debugging in Rails
- **github.pr_review**: PR review workflow methodology
```

Only the **name and description** appear. The full instructions are NOT in the
system prompt — they're loaded on-demand when the agent calls the skill.

## When to Load a Skill

Skills should be loaded when the task matches the skill's description. For example,
if an investigation involves a slow database query, load `rails.db_debug`.

If no skill's description matches the current task, proceed without loading any.
Skills are optional — they provide methodology, not required capabilities.

## Skills Can Reference Other Skills

A skill's instructions can mention other skills:

```markdown
Step 3: If you find the query is slow, load `rails.db_debug` for
detailed database investigation methodology.
```

This creates a hierarchy of methodology — a deploy skill might reference both
a database migration skill and a monitoring skill.

## Common Patterns

**Sequential composition**: Load one skill, follow its steps, then load another
when you reach a step that references it.

**Alternative composition**: If a skill's first step fails, load the troubleshooting
variant of that skill instead.

**Reporting back**: After completing a skill's methodology, summarize what you found
and what you did. The skill guided your process, but the results go back to the user.
