---
name: planning-orchestration
description: Use when starting a complex multi-step task requiring both phase-level tracking and per-phase implementation blueprints — before creating any plan files or writing code
user-invocable: true
---

# Planning Orchestration

## Overview
Two skills work together on complex tasks. `planning-with-files` is the outer layer (session memory). `writing-plans` is the inner layer (scoped implementation blueprints per phase). This skill defines when and how to combine them.

**You MUST invoke both skills explicitly — do not improvise a custom structure.**

## The Two-Layer Model

| Layer | Skill | Files | Role |
|---|---|---|---|
| Outer | `planning-with-files` | task_plan.md, findings.md, progress.md | Session memory, phase tracking, errors |
| Inner | `writing-plans` | plans/... | TDD blueprints per phase |

## Hierarchy: File vs Directory

**Simple phase** (single implementation unit) → one plan file:
```
task_plan.md Phase N → plans/YYYY-MM-DD-feature.md
```

**Complex phase** (2+ independent sub-tasks) → directory:
```
task_plan.md Phase N → plans/YYYY-MM-DD-feature/
                           ├── index.md            ← overview + sub-task list
                           ├── YYYY-MM-DD-sub-a.md
                           └── YYYY-MM-DD-sub-b.md
```

**Rule:** Use a directory when the phase decomposes into 2+ independently executable sub-tasks.
**Depth limit:** Never nest deeper than two levels (task_plan.md → plans/ → sub-plans/).

## Protocol

### REQUIRED: Starting a task
**REQUIRED SUB-SKILL:** Invoke `planning-with-files` skill first.
- Creates task_plan.md (phases), findings.md (research), progress.md (session log)
- Do NOT create any custom tracker, status doc, or migration doc instead
- Research goes into findings.md before committing to phases
- **After the high-level task plan is written: STOP. Do not pre-generate plans for any phase.**
- Wait for the user to ask to work on a specific phase.

### REQUIRED: Working on a phase (on user demand only)
Do not start a phase until the user explicitly asks. Work on one phase at a time, never in parallel.

**Step 1 — Study together (iterative loop):** Before writing any plan, align on direction then resolve open questions iteratively.

**1a — Propose approaches (first write to plan file):**
- Summarize what the phase involves
- Write 2-3 concrete implementation approaches into the plan file, each with trade-offs and a recommendation marked
- Ask the user only if there is a critical constraint that rules out your recommendation — otherwise let the file speak
- Wait for the user to pick an approach by editing the file

**1b — Iterative question loop (scoped to chosen approach):**
- Write current open questions into the plan file, each with your best default answer/assumption, scoped to the chosen approach
- Ask the user only the single most critical question that has no reasonable default — or nothing if all have defaults
- Wait for the user to review and edit the plan file (confirming, changing, or overriding defaults)
- Re-read the file, remove resolved questions, and surface any follow-up questions that only now become relevant (chained questions appear only after their parent is resolved)
- Repeat until no open questions remain

**1c — Finalize:**
- Remove all approach options and question scaffolding
- Replace with one comprehensive **Decisions** summary capturing the chosen approach and all resolved answers
- Do NOT invoke `writing-plans` until this is done

**Step 2 — Plan the phase:**
**REQUIRED SUB-SKILL:** Once the study is complete, invoke `superpowers:writing-plans` scoped to this phase only.
1. Read the current phase from task_plan.md
2. Decide: file or directory? (see rule above)
3. Save to `plans/YYYY-MM-DD-phase-name.md` (or directory)
4. Update task_plan.md to link the plan:
   ```markdown
   ## Phase N: Name
   **Status:** planned
   **Plan:** `plans/YYYY-MM-DD-phase.md`
   ```

**Step 3 — Execute the phase:**
1. Mark phase `in_progress` in task_plan.md
2. Follow the implementation plan step-by-step (checkboxes), one step at a time
3. Log all discoveries and errors in findings.md — not in the implementation plan
4. Mark phase `**Status:** complete` in task_plan.md when done
5. **Stop. Wait for the user to ask to begin the next phase.**

### REQUIRED: Archiving a completed task (all phases done)

When the user confirms all phases are complete, perform the archive step before stopping.

**Step 4 — Archive:**
1. Verify every `## Phase` section in task_plan.md has `**Status:** complete` on the line immediately after the heading. If any phase is incomplete, refuse and list the incomplete phases by name.
2. Derive task name: read the `## Overview` section (or first non-empty line if absent). Strip punctuation, remove stop words (a, an, the, and, or, for, to, of), take first 1–4 remaining words, lowercase, hyphenated. If zero words remain, use `task`.
3. Create `plans/archive/YYYY-MM-DD-<task-name>/` using today's date (create `plans/archive/` if it doesn't exist; append `-2`, `-3` on name collision).
4. Move `task_plan.md` and `progress.md` into the archive folder. Move `findings.md` if it exists (skip silently if absent).
5. Move all `plans/*.md` files (directly under `plans/`, not recursive) into the archive folder.
6. Inform the user: task archived to `plans/archive/<folder-name>/`, root is clean and ready for the next task.

## Red Flags — You Are Doing It Wrong

- Creating custom trackers (`MIGRATION-STATUS.md`, `STATUS.md`, etc.) instead of task_plan.md
- Using paths like `docs/migrations/` or `docs/planning/` instead of `plans/`
- Skipping `planning-with-files` and writing phases directly
- Skipping `writing-plans` and writing implementation steps inline in task_plan.md
- Nesting plans more than two levels deep
- Pre-generating plans for multiple phases after the high-level task plan — phases are planned one at a time, on demand
- Starting a phase without first studying it with the user
- Working on multiple phases or steps simultaneously
