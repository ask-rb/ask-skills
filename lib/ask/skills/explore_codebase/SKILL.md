---
name: explore_codebase
description: Step-by-step methodology for understanding a new codebase
---

When you need to understand an unfamiliar codebase, follow these steps:

1. **Read the README** — Start with `Read` tool on the root README.md to understand
   the project's purpose, setup, and conventions.

2. **Check configuration** — Look at the main config files (package.json, Gemfile,
   Cargo.toml, etc.) to understand dependencies and stack.

3. **Understand the entry point** — Find the main entry point by reading config files
   or checking common locations (src/main, lib/, app/).

4. **Explore the data model** — Read schema files, database migrations, or type
   definitions to understand the domain model.

5. **Read the routes/API** — Check routing files or API endpoint definitions to
   understand the interface surface.

6. **Run the tests** — Use the appropriate test runner to see what the project tests.

7. **Trace a feature** — Pick one feature, trace its path from entry point through
   the layers to understand the architecture pattern.

Reference the project's README and documentation throughout. If the project has
additional documentation in a docs/ directory, read that too.
