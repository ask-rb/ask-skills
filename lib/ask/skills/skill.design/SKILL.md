---
name: skill.design
description: How to design and write effective skills for the ask-rb ecosystem
---

A skill is a markdown file that teaches step-by-step methodology for a domain task.
It differs from a tool (which provides a capability) in that it guides *how* to
approach the work — the reasoning process, the order of operations, the pitfalls to avoid.

## When to Create a Skill

Create a skill when you have domain knowledge that:
1. Follows a repeatable process (always debug DB this way)
2. Requires tool composition (use these 3 tools in sequence)
3. Is too long for the system prompt but too valuable to leave out

Do NOT create a skill for:
- Simple tool knowledge (just update the system prompt or tool description)
- API reference documentation (that's what context.rb is for in service gems)
- One-time tasks that won't repeat

## Skill File Format

Each skill is a directory with a `SKILL.md` file:

```
lib/ask/skills/<name>/
└── SKILL.md
```

The `SKILL.md` has YAML frontmatter followed by markdown body:

```markdown
---
name: domain.skill_name       # Unique identifier (lowercase, dots allowed)
description: One-line summary  # Shown in system prompt skill list
version: 1                     # Optional
---

Instructions body...
```

## Writing Good Skill Content

1. **Start with context** — When would someone use this skill? What problem does it solve?
2. **Use numbered steps** — Clear progression, one concept per step
3. **Reference tools by name** — "Use `ReadModel.new.call(name: "User")`" not "check the model"
4. **Show examples** — Concrete tool invocations the agent can copy
5. **Explain reasoning** — Not just what to do, but why this order matters
6. **Handle failure** — "If this step fails, try..." for common pitfalls
7. **Keep focused** — One skill, one domain procedure. If it's too long, split into multiple skills.

## Skill Naming Convention

```
<domain>.<name>
```

Examples:
- `rails.db_debug` — Rails-specific database debugging
- `github.pr_review` — GitHub PR review workflow
- `shell.patterns` — Shell tool composition patterns

## Testing Your Skill

After creating a skill file, verify:
1. Frontmatter has both `name` and `description`
2. Name is lowercase with only letters, numbers, dots, hyphens
3. Description is a complete sentence
4. Instructions have numbered steps
5. Tools are referenced by their full Ruby class names
6. The skill directory contains `SKILL.md` (not `skill.md` or `README.md`)
