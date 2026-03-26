# Task Archive Design

**Date:** 2026-03-26

## Problem

When `planning-with-files` is invoked for a new task in a directory that already has completed planning files (`task_plan.md`, `findings.md`, `progress.md`), it resumes the old task instead of starting fresh. There is no mechanism to preserve completed task history while cleaning the root for the next task.

## Goals

1. Clean the project root after task completion so the next task starts fresh
2. Preserve full task history (session files + phase blueprints) for future reference
3. Require no manual cleanup from the user

## Design

### Directory Structure

**During a task:**
```
project-root/
├── task_plan.md
├── findings.md         ← may not always exist
├── progress.md
└── plans/
    ├── 2026-03-26-phase-one.md
    └── 2026-03-26-phase-two.md
```

**After archiving:**
```
project-root/
└── plans/
    └── archive/
        └── 2026-03-26-task-name/
            ├── task_plan.md
            ├── findings.md
            ├── progress.md
            ├── 2026-03-26-phase-one.md
            └── 2026-03-26-phase-two.md
```

### Archive Folder Naming

`plans/archive/YYYY-MM-DD-<task-name>/`

- **Date:** system clock date at archive time (YYYY-MM-DD)
- **Task name:** derived as follows:
  1. Read the text content of the `## Overview` section in `task_plan.md`. If no `## Overview` heading exists, use the first non-empty line of the file.
  2. Strip all punctuation. Split into words. Remove stop words: a, an, the, and, or, for, to, of. Numbers count as words.
  3. Take the first 1–4 remaining words, lowercase, join with hyphens.
  4. If zero words remain after filtering, use `task` as the name.
  - Example: "Create a git-managed dotfiles repo" → `git-managed-dotfiles-repo`
- **Collision:** if a folder with the same name already exists, append `-2`, `-3`, etc.

### Trigger

Archive is performed as the **final step** of a task by `planning-orchestration`, after the user explicitly confirms all phases are done.

**Completeness check:** A phase is identified by any section heading matching `## Phase` in `task_plan.md`. "All phases complete" means every such section has `**Status:** complete` on the line immediately following the heading. If any phase fails this check, the skill refuses to archive and lists the incomplete phases by name for the user to resolve.

If a task is abandoned mid-phase (never fully completed), no archive occurs. Files remain at root and the next session resumes them. If the user wants to discard an in-progress task and start fresh, they must manually delete or move the root planning files — this is the only case requiring manual action.

### New Task Detection

On the next invocation of `planning-with-files`, absence of `task_plan.md` at root signals a new task. The skill creates fresh files. No user intervention needed.

### Files Moved

| File | Action if missing |
|---|---|
| `task_plan.md` | Required — archive aborts if absent |
| `progress.md` | Required — archive aborts if absent |
| `findings.md` | Optional — skip silently if absent |
| `plans/*.md` | All `.md` files directly under `plans/` (not recursive), regardless of naming convention |

`plans/archive/` and any subdirectories under `plans/` are not moved.

### Directory Creation

If `plans/archive/` does not exist, it is created before moving files.

### Atomicity

The archive operation is not atomic. If interrupted, orphaned files may remain in `plans/`. On the next invocation, absence of `task_plan.md` at root causes a fresh start — orphaned phase files in `plans/` are then stale. Recovery from partial archive is out of scope.

### Name Collision with Session Files

Phase blueprint files must not be named `task_plan.md`, `findings.md`, or `progress.md`. The `writing-plans` skill uses date-prefixed names (`YYYY-MM-DD-*.md`) which prevents this in practice, but it is noted as a constraint.

## Ownership

`planning-orchestration` owns the archive step — added as **Step 4** after all phases complete:

1. Confirm all phases are marked `**Status:** complete` in `task_plan.md`
2. Derive task name from `task_plan.md` overview (kebab-case, 1–4 words, stop words removed)
3. Create `plans/archive/YYYY-MM-DD-<task-name>/` (creating `plans/archive/` if needed; append `-2` on collision)
4. Move `task_plan.md`, `progress.md`, and `findings.md` (if present) into it
5. Move all `plans/*.md` files into it
6. Inform the user the task is archived and root is clean

`planning-with-files` requires no changes — absence of `task_plan.md` already triggers a fresh start.

## Constraints

- Maximum archive depth: `plans/archive/<task>/` — never deeper
- Phase blueprints stay flat inside the archive folder (no subdirectory)
- Archive step is mandatory when all phases are complete, not optional
- Phase blueprint filenames must not collide with session file names
