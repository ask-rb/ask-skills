---
name: debug_methodology
description: Systematic approach to debugging any software problem
---

When debugging an issue, follow this systematic approach:

1. **Reproduce consistently** — Find a reliable reproduction path. Note:
   - Exact inputs and steps
   - Environment details (OS, versions, configuration)
   - Error messages and stack traces

2. **Gather information** — Use available tools to collect context:
   - Read log files (application, server, database)
   - Check the relevant code path
   - Query system state (database, processes, files)
   - Review recent changes (git log, deploy history)

3. **Form a hypothesis** — Based on evidence, form one hypothesis at a time.
   State it clearly: "I think X is happening because Y."

4. **Test the hypothesis** — Design the simplest experiment to prove/disprove:
   - Add logging or instrumentation
   - Write a minimal reproduction script
   - Check system state before and after

5. **Isolate variables** — Change ONE variable at a time.
   - Binary search on commits (git bisect)
   - Toggle configuration flags
   - Comment out code sections

6. **Know when to ask** — If you've spent 3+ steps without progress, describe
   what you've learned and what remains unclear. A fresh perspective helps.

Always document what you learn for future reference.
