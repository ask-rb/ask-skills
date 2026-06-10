# ask-skills — Skill Discovery and Management for ask-rb

## Purpose

A skill discovery and management system for the ask-rb ecosystem. Skills are
markdown files containing step-by-step methodology that agents load on-demand.
They keep the system prompt lean while giving agents access to deep domain
knowledge when needed.

Unlike tools (which provide capabilities), skills provide **methodology**.
A tool lets the agent read a file. A skill teaches the agent *how* to explore
a codebase — what to read first, what patterns to look for, how to trace
through the architecture.

## Dependencies

- **Runtime:** Zero. Pure Ruby (stdlib only). No external gems.
- **Build/test:** minitest, mocha, rake
- **No ask-rb dependencies.** This gem can be used standalone by any Ruby app
  that wants a skill discovery system.

## How This Improves on Flue and Pi

| Feature | Flue | Pi | ask-skills |
|---|---|---|---|
| Gem discovery | ❌ | ❌ | ✅ `Gem.find_files("ask/skills/*/SKILL.md")` |
| Priority resolution | Last wins | Last wins (with collision warnings) | First wins (project > gems > user > built-in) |
| Validation | None | Name + description | Name + description + duplicate detection |
| Built-in skills | None | None | skill.design, skill.compose |
| System prompt composition | ✅ simple | ✅ XML format | Both: markdown list + XML |
| Sources | `.agents/skills/` | Agent dir + project dir | Built-in + gems + project + user |
| Skill-by-path | ✅ | ❌ | Planned for v0.2 |

## Implementation Steps

### 1. Core Data Types (`lib/ask/skills/skill.rb`)

`Ask::Skills::Skill` — a Data.define with:
- `name` — unique skill identifier (e.g. "rails.db_debug")
- `description` — one-line summary for system prompt listing
- `instructions` — full markdown body (step-by-step methodology)
- `source` — file path where the skill was loaded from
- Method `to_prompt_entry` — formats as "- **name**: description"
- Method `to_s` — "name: description"

### 2. Sources

**`Source::Gems`** (`lib/ask/skills/sources/gems.rb`)
- Uses `Gem.find_files("ask/skills/*/SKILL.md")` to discover skills from all installed gems
- Gems ship skills at `lib/ask/skills/<skill_name>/SKILL.md`
- This is the KEY differentiator — no other skill system discovers from gems

**`Source::Filesystem`** (`lib/ask/skills/sources/filesystem.rb`)
- Scans a directory for skill subdirectories containing `SKILL.md`
- Supports two conventions:
  - Project-local: `.agents/skills/<name>/SKILL.md`
  - User-global: `~/.config/ask/skills/<name>/SKILL.md`
- Each skill is a directory (allows for future assets like examples, templates)

**Both sources parse SKILL.md files with YAML frontmatter:**
```markdown
---
name: skill.name
description: One-line description for system prompt
version: optional
---

Instructions body in markdown...
```

Frontmatter parsing is basic (regex-based, no YAML gem needed):
- Lines between `---\n` and `\n---\n`
- Simple `key: value` parsing
- Body is everything after the closing `---`

### 3. Registry (`lib/ask/skills/registry.rb`)

`Ask::Skills::Registry` — holds all discovered skills with:
- `skills` — Hash of name → Skill
- `[]` — lookup by name
- `names` — all skill names (for system prompt listing)
- `format_for_prompt` — generates markdown section for system prompt
- Priority resolution: first source wins
  - Built-in < gems < user-global < project-local
  - This way projects override gems, users override built-ins

### 4. Formatter (`lib/ask/skills/formatter.rb`)

Two output formats:
- **Markdown**: `"## Available Skills\n\n- **name**: desc\n..."` — for direct system prompt
- **XML**: `"<available_skills><skill><name>...</skill>..."` — for Pi-style machine-parseable format

### 5. Validator (`lib/ask/skills/validator.rb`)

`Ask::Skills::Validator` — validates skills:
- Name is required and must match `[a-z0-9_.-]+`
- Description is required and non-empty
- Instructions are required and non-empty
- Duplicate name detection (same name from multiple sources)

Returns array of `ValidationError` data objects.

### 6. Built-in Skills

Two skills shipped in `lib/ask/skills/<name>/SKILL.md`:

**`skill.design`** — Step-by-step codebase exploration methodology:
1. Read README
2. Check config files (Gemfile, package.json, etc.)
3. Find entry point
4. Understand data model (schema, migrations, types)
5. Read routes/API
6. Run tests
7. Trace one feature through the layers

**`skill.compose`** — Systematic debugging approach:
1. Reproduce consistently (exact steps, environment, error)
2. Gather information (logs, code, git history)
3. Form one hypothesis at a time
4. Test with minimal experiment
5. Isolate ONE variable at a time
6. Know when to ask for help

### 7. Dispatcher (`Ask::Skills.discover`)

```ruby
Ask::Skills.discover
# => Registry with skills from all sources in priority order:
#    1. Built-in (ask-skills gem)
#    2. Installed gems (Gem.find_files)
#    3. ~/.config/ask/skills/ (user-global)
#    4. .agents/skills/ (project-local)

Ask::Skills.discover(sources: [custom_source])
# => Registry with custom sources only
```

### 8. Skills to Write for Each Gem

After `ask-skills` is built, add skills to each gem that has domain methodology:

| Gem | Skill | Content | File |
|---|---|---|---|
| **ask-rails** | `rails.db_debug` | DB performance debugging: schema → indexes → EXPLAIN → N+1 patterns | `lib/ask/skills/rails.db_debug/SKILL.md` |
| | `rails.route_trouble` | Route debugging: check routes file → trace match → check constraints | `lib/ask/skills/rails.route_trouble/SKILL.md` |
| | `rails.deploy_pipeline` | Pre-deploy checklist: migrations → assets → creds → jobs → logs | `lib/ask/skills/rails.deploy_pipeline/SKILL.md` |
| **ask-github** | `github.pr_review` | PR review: understand change → check tests → verify edge cases → suggest | `lib/ask/skills/github.pr_review/SKILL.md` |
| | `github.issue_triage` | Issue triage: reproduce → classify → check dups → label → prioritize | `lib/ask/skills/github.issue_triage/SKILL.md` |
| **ask-slack** | `slack.compose` | Message formatting: blocks → attachments → markdown → threading | `lib/ask/skills/slack.compose/SKILL.md` |
| **ask-tools-shell** | `shell.patterns` | Tool composition: bash+read for search, glob+grep for code analysis | `lib/ask/skills/shell.patterns/SKILL.md` |
| **ask-llm-providers** | `providers.model_select` | Model selection: cost vs capability, latency, context window size | `lib/ask/skills/providers.model_select/SKILL.md` |

Each skill follows the same frontmatter format:
```markdown
---
name: gem.skill_name
description: One-line description for the system prompt listing
---

Step-by-step methodology content...
```

### 9. Integration with ask-agent

After `ask-skills` is released and skills are added to gems:

1. **Auto-discovery on agent init** — When `Ask::Agent.new` is called,
   auto-discover skills via `Ask::Skills.discover`

2. **System prompt injection** — Format discovered skills as a section in the
   system prompt (markdown list with names + descriptions only)

3. **`session.skill(name)` method** — Load a skill by name and inject its
   full instructions as a prompt
   ```ruby
   session.skill("rails.db_debug")  # loads full instructions
   ```

4. **`session.skill(path)` fallback** — Load any .md file as an ad-hoc skill
   ```ruby
   session.skill("docs/runbook.md")  # load from file path
   ```

### 10. Tests

- **Skill data class**: construction, to_prompt_entry, to_s
- **Sources**: 
  - Filesystem: load skills from valid dir, skip invalid dirs, parse frontmatter
  - Gems: discover from installed gems (mock Gem.find_files)
  - Priority: first source wins (built-in < gems < user < project)
- **Registry**: lookup by name, names list, format_for_prompt
- **Formatter**: markdown output, XML output, empty case
- **Validator**: valid skills pass, invalid names fail, missing description fails, duplicate detection
- **Built-in skills**: exist and parse correctly
- **Integration**: full discovery pipeline works end-to-end

### 11. Production Hardening

- **Error handling:** Missing directories silently return empty (not crash)
- **Malformed skills:** Skills with invalid frontmatter are skipped with a warning (not crash)
- **Edge cases:** Empty skill directory, no skills found, duplicate names from different sources
- **Thread safety:** Registry access is read-only after construction (safe for concurrent agent sessions)

## Skill Content Guidelines

Each skill's instructions should:

1. **Be step-by-step** — Numbered steps or clear progression
2. **Reference tools by name** — "Use `ReadModel` to inspect..." not just "inspect the model"
3. **Provide concrete examples** — Show the tool invocations
4. **Explain WHY** — Not just what to do, but why this order
5. **Handle failure modes** — "If this step fails, try this alternative"

Example structure:
```markdown
### Step 1: Understand the Schema
Use `Ask::Rails::Tools::ReadModel.new.call(name: "User")` to inspect the model.
This tells you the table columns, associations, and validations.

### Step 2: Check for Missing Indexes
Run `Ask::Rails::Tools::QueryDatabase.new.call(sql: "SELECT...")`...
If you see sequential scans, you likely need an index.

### Step 3: EXPLAIN Slow Queries
...
```

## What Done Means for v0.1.0

- Core data types + sources + registry + formatter + validator all implemented
- Built-in skills (skill.design, skill.compose) ship and load correctly
- Gem discovery works (skills from ask-rails, ask-github etc. auto-found)
- Filesystem discovery works (.agents/skills/, ~/.config/ask/skills/)
- Full test suite passes
- README documents the full API
- CHANGELOG with v0.1.0 entry
- Gem released on RubyGems

## v0.2.0 (after v0.1.0)

- Add skills to ALL methodology gems (ask-rails, ask-github, ask-slack, ask-tools-shell, ask-llm-providers)
- Integrate into ask-agent (auto-discover, system prompt injection, session.skill method)
- Skill-by-path loading (load any .md as ad-hoc skill)
- File watching for development (auto-reload skills on change)
- Version-release each gem with its skills

## Development Workflow

### Git conventions
- Default branch is **master**.
- Use conventional commits.
- Reference local repos at /Users/kaka/Code/ask-rb/ for patterns.

### Testing
- Minitest (not RSpec).
- Unit tests for every public method.
- Run full suite before commit: `bundle exec rake test`.
