# Project Design Document

> This document tracks design decisions made during conversations.
> Updated automatically by the `design-tracker` skill.

## Overview

Claude Code Orchestra is a multi-agent collaboration framework. Claude Code is the orchestrator, with Codex CLI for planning/design/complex code, Opus subagents (1M context) for research/analysis/implementation, and Gemini CLI for multimodal file processing (PDF/video/audio/image).

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Claude Code Lead (Opus 4.6 — 200K context)                      │
│  Role: Orchestration, user interaction, task management           │
│                                                                   │
│  ┌──────────────────────┐  ┌──────────────────────┐             │
│  │ Agent Teams (Opus)    │  │ Subagents (Opus)      │             │
│  │ (parallel + comms)    │  │ (isolated + results)  │             │
│  │                       │  │                       │             │
│  │ Researcher ←→ Archit. │  │ Code implementation   │             │
│  │ Implementer A/B/C     │  │ Codex consultation    │             │
│  │ Security/Quality Rev. │  │ Gemini consultation   │             │
│  └──────────────────────┘  └──────────────────────┘             │
│                                                                   │
│  External CLIs:                                                   │
│  ├── Codex CLI (gpt-5.4) — planning, design, complex code        │
│  └── Gemini CLI — multimodal file processing (PDF/video/audio/    │
│       image) only                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Roles

| Agent | Role | Responsibilities |
|-------|------|------------------|
| Claude Code (Main) | Overall orchestration | User interaction, task management, simple code edits |
| general-purpose (Opus) | Research, analysis & implementation | Research, codebase analysis, code implementation, Codex delegation |
| gemini-explore (Opus) | Multimodal file processing | PDF, video, audio, image content extraction |
| Codex CLI | Planning & complex implementation | Architecture design, implementation planning, complex code, debugging |
| Gemini CLI | Multimodal processing | PDF/video/audio/image content extraction (called via gemini-explore) |

## Implementation Plan

### Patterns & Approaches

| Pattern | Purpose | Notes |
|---------|---------|-------|
| Agent Teams | Parallel work with inter-agent communication | /startproject, /team-implement, /team-review |
| Subagents | Isolated tasks returning results | External research, Codex consultation, implementation |
| Skill Pipeline | `/startproject` → `/team-implement` → `/team-review` | Separation of concerns across skills |

### Libraries & Roles

| Library | Role | Version | Notes |
|---------|------|---------|-------|
| Codex CLI | Planning, design, complex code | gpt-5.4 | Architecture, planning, debug, complex implementation |
| Gemini CLI | Multimodal file reading | gemini-3-pro | PDF/video/audio/image extraction ONLY |

### Key Decisions

| Decision | Rationale | Alternatives Considered | Date |
|----------|-----------|------------------------|------|
| AnchoredVWAP will use a raw function `AnchoredVWAP(data::Matrix{Float64}; anchor_idx::Int=1)` plus a hand-written `TSFrame` wrapper accepting `anchor::Union{Date,Int}` | Matches existing `VWAP` raw API shape, keeps date-to-row resolution in the wrapper where `@prep_miso` cannot help, and follows the custom-wrapper precedent already established by `Ichimoku` | Extending `@prep_miso` for wrapper-consumed params; slicing data externally before calling `VWAP`; using `anchor::Union{Date,Int}` in the raw function | 2026-04-02 |
| Foxtail.jl prioritization: documentation-first with 80/20 docs-to-indicators split | Current indicator set covers all top-20 professional indicators and 7/10 major workflows fully; outdated/incomplete docs are the primary adoption bottleneck and have higher ROI than specialist indicators | Indicator-first expansion, equal split, hybrid with docs leading | 2026-04-02 |
| Gemini role expanded to codebase analysis + research + multimodal | Gemini CLI has native 1M context; Claude Code is 200K; delegate large-context tasks to Gemini | Keep Claude for codebase analysis (requires 1M Beta) | 2026-02-19 |
| All subagents default to Opus | 200K context makes quality of reasoning more important than context size; Opus provides better output | Sonnet (cheaper but 200K same as Opus, weaker reasoning) | 2026-02-19 |
| Agent Teams default model changed to Opus | Consistent with subagent model selection; better reasoning for parallel tasks | Sonnet (cheaper) | 2026-02-19 |
| Claude Code context corrected to 200K | 1M is Beta/pay-as-you-go only; most users have 200K; design must work for common case | Assume 1M (only works for Tier 4+ users) | 2026-02-19 |
| Subagent delegation threshold lowered to ~20 lines | 200K context requires more aggressive context management | 50 lines (was based on 1M assumption) | 2026-02-19 |
| Codex role unchanged (planning + complex code) | Codex excels at deep reasoning for both design and implementation | Keep Codex advisory-only | 2026-02-17 |
| Gemini narrowed to multimodal only; research moved to Opus subagents | Opus/Sonnet now support 1M context; Gemini's context advantage is obsolete for text tasks | Keep Gemini for research (redundant with Opus 1M) | 2026-03-14 |
| /startproject split into 3 skills | Separation of Plan/Implement/Review gives user control gates | Single monolithic skill | 2026-02-08 |
| Agent Teams for Research ↔ Design | Bidirectional communication enables iterative refinement | Sequential subagents (old approach) | 2026-02-08 |
| Agent Teams for parallel implementation | Module-based ownership avoids file conflicts | Single-agent sequential implementation | 2026-02-08 |
| TSFrames: switch to fork via `Pkg.add(url=...)` | Deterministic builds (Manifest pins commit SHA), CI-friendly, explicit update control | `Pkg.develop(url=...)` (better for co-development but non-deterministic) | 2026-04-01 |

## TODO

- [ ] Foxtail.jl docs priority batch: fix README indicator status/count mismatches and remove stale "ToDo" claims
- [ ] Publish missing indicator docs for ConnorsRSI, MassIndex, UltimateOscillator, Vortex, PivotPoints
- [ ] Add workflow guides, TA-Lib validation examples, and migration guidance before expanding specialist indicators
- [ ] Test Agent Teams workflow end-to-end with a real project
- [ ] Update hooks for Agent Teams quality gates
- [ ] Evaluate optimal team size for /team-implement

## Open Questions

- [ ] Optimal team size for /team-implement (2-3 vs 4-5 teammates)?
- [ ] Should /team-review be mandatory or optional?
- [ ] How to handle Compaction in long Agent Teams sessions?

## Changelog

| Date | Changes |
|------|---------|
| 2026-04-02 | Added AnchoredVWAP implementation sequencing note: use TDD with test stubs first, then raw function, then manual `TSFrame` wrapper, then regression/integration coverage, with each step independently verifiable |
| 2026-04-02 | Recorded AnchoredVWAP architecture: raw function with `anchor_idx::Int=1`, manual `TSFrame` wrapper for `anchor::Union{Date,Int}`, pre-anchor `NaN`, and parity requirement with `VWAP(data)` when `anchor==1` |
| 2026-04-02 | Recorded Foxtail.jl prioritization decision: documentation-first, target 80/20 docs-to-indicators split based on spike findings |
| 2026-04-01 | TSFrames.jl: switch from public registry to takaymmt/TSFrames.jl fork via `Pkg.add(url=..., rev="main")` |
| 2026-03-14 | Gemini narrowed to multimodal-only; research/analysis delegated to Opus subagents (1M context) |
| 2026-02-19 | Context-aware redesign: Claude=200K, Gemini=1M (codebase+research+multimodal), all subagents/teams→Opus |
| 2026-02-17 | Role clarification: Gemini → multimodal only, Codex → planning + complex code, Subagents → external research |
| 2026-02-08 | Major redesign for Opus 4.6: 1M context, Agent Teams, skill pipeline |
| | Initial |
