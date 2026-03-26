# Task Archive Design

**Date:** 2026-03-26
**Status:** Approved

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
├── findings.md
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

- Date prefix: completion date
- Task name: short kebab-case summary derived from the task_plan.md overview (e.g. `dotfiles-setup`, `api-refactor`)

### Trigger

Archive is performed as the **final step** of a task, after all phases in `task_plan.md` are marked `complete`. It is not performed mid-task or between phases.

### New Task Detection

On the next invocation of `planning-with-files`, absence of `task_plan.md` at root signals a new task. The skill creates fresh files. No user intervention needed.

### Files Moved

All of the following are moved into the archive folder:
- `task_plan.md`
- `findings.md`
- `progress.md`
- All `plans/*.md` phase blueprint files (flat, not nested further)

`plans/archive/` itself is never archived.

## Impact on `planning-orchestration` Skill

A new **Step 4 — Archive** is added after all phases complete:

1. Derive task name from `task_plan.md` overview (kebab-case, max 4 words)
2. Create `plans/archive/YYYY-MM-DD-<task-name>/`
3. Move `task_plan.md`, `findings.md`, `progress.md` into it
4. Move all `plans/*.md` files into it
5. Root and `plans/` are now clean

## Constraints

- Maximum archive depth: `plans/archive/<task>/` — never deeper
- Phase blueprints stay flat inside the archive folder (no subdirectory)
- Archive step is mandatory, not optional
