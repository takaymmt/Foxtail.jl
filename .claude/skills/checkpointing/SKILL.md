---
name: checkpointing
description: |
  Save full session context: git history, CLI consultations, Agent Teams activity,
  and discover reusable skill patterns — all in one run. No flags needed.
  Run at session end, after major milestones, or when you want to capture learnings.
metadata:
  short-description: Full session checkpoint with skill pattern discovery
---

# Checkpointing — Full Session Recording and Pattern Discovery

**Record all session activity and discover reusable patterns. Run everything, every time.**

## What It Does (Every Time)

```
/checkpointing
    ↓
┌─────────────────────────────────────────────────────────────┐
│  1. Collect Everything                                       │
│     ├── git log (commits, file changes, line stats)          │
│     ├── CLI logs (Codex/Gemini consultations)                │
│     ├── Agent Teams activity (tasks, teammates, messages)    │
│     └── Design decisions (.claude/docs/DESIGN.md changes)    │
│                                                              │
│  2. Generate Checkpoint                                      │
│     → .claude/checkpoints/YYYY-MM-DD-HHMMSS.md              │
│                                                              │
│  3. Update Current State                                     │
│     → CLAUDE.md ## Current State（上書き、追記しない）         │
│                                                              │
│  4. Write Handoff Notes                                      │
│     → .claude/checkpoints/MEMORY.md（上書き）                │
│        未完了タスク・次セッション引き継ぎ事項                   │
│                                                              │
│  5. Discover Skill Patterns                                  │
│     → Subagent analyzes checkpoint                           │
│     → Suggests reusable skills                               │
│     → User reviews and approves                              │
└─────────────────────────────────────────────────────────────┘
```

## Usage

```bash
# Everything. No flags needed.
/checkpointing

# Optional: only look at recent work
/checkpointing --since "2026-02-08"
```

## What Gets Captured

### Git Activity

- Commits (hash, message, date)
- File changes (created, modified, deleted + line counts)
- Branch information

### CLI Consultations

- Codex consultations (prompt, success/failure)
- Gemini multimodal tasks (prompt, success/failure)

### Agent Teams Activity

- Team composition (Lead + Teammates, roles)
- Shared task list state (completed, in-progress, pending)
- File ownership per teammate
- Communication patterns (who messaged whom, about what)
- Team effectiveness signals (tasks completed vs stuck, file conflicts)

### Teammate Work Logs

- Each Teammate's work log from `.claude/logs/agent-teams/{team-name}/{teammate}.md`
- Contains: Summary, Tasks Completed, Files Modified, Key Decisions, Communication with Teammates, Issues Encountered
- Written by each Teammate upon completing all assigned tasks
- Only present when Agent Teams were used (`/startproject`, `/team-implement`, `/team-review`)

### Design Decisions

- Changes to `.claude/docs/DESIGN.md` since last checkpoint
- New entries in Key Decisions table

## Checkpoint Format

```markdown
# Checkpoint: 2026-02-08 15:30:00 UTC

## Summary
- **Commits**: 12
- **Files changed**: 15 (10 modified, 4 created, 1 deleted)
- **Codex consultations**: 3
- **Gemini multimodal**: 2
- **Agent Teams sessions**: 1 (3 teammates)
- **Tasks completed**: 8/10

## Git History

### Commits
- `abc1234` feat: redesign startproject for Opus 4.6
- `def5678` feat: add team-implement skill
...

### File Changes
**Created:**
- `.claude/skills/team-implement/SKILL.md` (+180)
...

**Modified:**
- `CLAUDE.md` (+40, -25)
...

## CLI Consultations

### Codex (3 consultations)
- ✓ Design: Architecture for Agent Teams integration
- ✓ Debug: Task dependency resolution
- ✗ Review: (timeout)

### Gemini (2 multimodal tasks)
- ✓ Extract: API spec from design document PDF
- ✓ Analyze: Architecture diagram from whiteboard photo

## Agent Teams Activity

### Team: project-planning
**Composition:**
- Lead: Claude (orchestration)
- Researcher: Opus-powered (external research)
- Architect: Codex-powered (design decisions)

**Task List:**
- [x] Research library options (Researcher)
- [x] Design module architecture (Architect)
- [x] Validate API constraints (Researcher)
- [x] Finalize implementation plan (Architect)

**Communication Patterns:**
- Researcher → Architect: 3 messages (library constraints)
- Architect → Researcher: 2 messages (additional research requests)

**Effectiveness:**
- All tasks completed
- No file conflicts
- 2 design iterations triggered by research findings

## Teammate Work Logs

### Team: project-planning

#### researcher
*Source: `.claude/logs/agent-teams/project-planning/researcher.md`*

# Work Log: Researcher
## Summary
Researched httpx library constraints and API patterns for the new API client module.
## Tasks Completed
- [x] Research libraries: httpx supports HTTP/2 via h2 dependency
- [x] Find documentation: httpx connection pool defaults to 100
## Communication with Teammates
- → Architect: httpx connection pool limit of 100, HTTP/2 requires h2
- ← Architect: Requested HTTP/2 multiplexing research

#### architect
*Source: `.claude/logs/agent-teams/project-planning/architect.md`*

# Work Log: Architect
## Summary
Designed API client module architecture with HTTP/2 support.
## Design Decisions
- Use httpx[http2] for multiplexed connections: reduces latency for parallel requests
## Codex Consultations
- Connection pool sizing strategy: Codex recommended dynamic pool based on load
## Communication with Teammates
- → Researcher: Request HTTP/2 multiplexing research
- ← Researcher: httpx supports HTTP/2 via h2

## Design Decisions (New)
- Agent Teams for Research ↔ Design (bidirectional)
- Gemini specialized for multimodal processing only

## Skill Pattern Suggestions

### Pattern 1: Research-Design Iteration (Confidence: 0.85)
**Evidence:** Researcher and Architect exchanged findings 5 times, each
exchange refined the design. This back-and-forth is a repeatable pattern.

**Suggested skill:** Already captured as /startproject Phase 2.

### Pattern 2: Parallel File-Isolated Implementation (Confidence: 0.75)
**Evidence:** 3 implementers worked on separate modules with zero conflicts.
Module boundaries were defined by directory ownership.

**Suggested skill:** Already captured as /team-implement.

---
*Generated by checkpointing skill*
```

## Current State Update

Each checkpoint **overwrites** the `## Current State` section in CLAUDE.md with minimal current-state info.
Full session details go only to `.claude/checkpoints/YYYY-MM-DD-HHMMSS.md`.

```markdown
## Current State（最終更新: YYYY-MM-DD）
- テスト数: {N}本（全通過）
- 実装済み指標: {N}指標（`docs/indicator-reference.md` 参照）
- 次の候補: {next items with priority stars}
```

This keeps CLAUDE.md lean — past sessions are retrievable from `.claude/checkpoints/` when needed.

## Handoff Notes (MEMORY.md)

Each checkpoint **overwrites** `.claude/checkpoints/MEMORY.md` with items the next session needs to hit the ground running.
This is distinct from the full checkpoint file (detailed log) and CLAUDE.md (minimal state).

```markdown
# Session Handoff Notes

## Last Updated: YYYY-MM-DD

## Pending Work
<!-- Tasks started but not finished this session -->
- [ ] {task}: {enough context to resume without re-reading the full session}

## Important Decisions Made
<!-- Decisions this session that affect future work -->
- {decision}: {rationale / why it matters going forward}

## Known Issues
<!-- Bugs, test failures, or rough edges left open -->
- {issue}: {description and last known status}

## Next Session Should Start With
<!-- Prioritized list of what to tackle first -->
1. {highest priority item}
2. {next item}
```

**What belongs here (write if present):**
- Unfinished tasks with enough context to resume
- Design decisions made under time pressure that need revisiting
- Non-obvious gotchas discovered this session
- Explicit "next up" priorities agreed with the user

**What does NOT belong here:**
- Completed work (covered by checkpoint file + git log)
- Project structure / conventions (covered by CLAUDE.md + `.claude/rules/`)
- Passing test results (those live in the checkpoint)

## Skill Pattern Discovery

The checkpoint is automatically analyzed to find reusable patterns:

**What it looks for:**
- Sequences of commits forming logical workflows
- File change patterns (e.g., test + implementation together)
- CLI consultation sequences (research → design → implement)
- Agent Teams coordination patterns (team composition, task sizing)
- Multi-step operations that could be templated

**Output:** Skill suggestions with confidence scores. High-confidence patterns (>= 0.8) that don't match existing skills are presented to the user for approval.

## Execution Flow

```
/checkpointing
    │
    ├─ 1. Run checkpoint.py (collects git + CLI + teams data)
    │     → Generates .claude/checkpoints/YYYY-MM-DD-HHMMSS.md
    │
    ├─ 2. Overwrite ## Current State in CLAUDE.md (minimal, no append)
    │
    ├─ 3. Overwrite .claude/checkpoints/MEMORY.md (handoff notes)
    │     → Pending work with resume context
    │     → Decisions made under time pressure
    │     → Non-obvious gotchas
    │     → Next session priorities
    │
    └─ 4. Spawn subagent for skill pattern analysis
          → Reads checkpoint file
          → Identifies reusable patterns
          → Reports suggestions to user
          → User approves → new skills created in .claude/skills/
```

## When to Run

| Timing | Why |
|--------|-----|
| Before session ends | Record all activity, hand off to next session |
| After `/team-implement` completes | Capture team activity patterns |
| After `/team-review` completes | Capture review patterns |
| After major design decisions | Persist the decision context |
| When you notice recurring patterns | Opportunity to discover new skills |

## Notes

- Checkpoints accumulate in `.claude/checkpoints/` (already in `.gitignore`)
- Log files themselves are not modified (read-only)
- Skill suggestions must always be reviewed by the user before adoption
- Agent Teams data is collected from `~/.claude/teams/` and `~/.claude/tasks/`
