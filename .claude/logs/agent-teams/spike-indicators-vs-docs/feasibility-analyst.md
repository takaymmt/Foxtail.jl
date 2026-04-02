# Work Log: Feasibility Analyst

## Summary

Conducted comprehensive feasibility analysis for the spike: "Foxtail.jl -- add more indicators vs. improve documentation". Analyzed 50 indicator source files, 1292-line indicator reference, README, contributor guide, test suite (4307 tests), and competitive landscape (OnlineTechnicalIndicators.jl, TA-Lib, pandas-ta).

**Verdict: Documentation improvement has 3-5x higher ROI than adding more indicators. Recommended approach: 20% indicators / 80% documentation. Confidence: HIGH.**

## Sub-question Assessments

| # | Sub-question | Finding |
|---|-------------|---------|
| 1 | Primary adoption barrier | Documentation gaps (outdated README, no validation, no workflows, no migration guide) |
| 2 | Workflow coverage of 50 indicators | 8.5/10 -- 7/10 workflows FULL, 2 GOOD, 1 PARTIAL (out of scope) |
| 3 | Must-have indicator gaps | No critical gaps. Only Anchored VWAP has genuine demand. |
| 4 | Documentation sufficiency | Insufficient for professional adoption. API ref is GOOD but trust, workflows, onboarding are MISSING. |
| 5 | ROI comparison | Docs win decisively. Indicators are in diminishing returns zone. Docs affect 100% of users. |

## Codex Consultations

Codex CLI was unavailable (permission denied). Analysis was conducted directly by Opus subagent using:
- Full codebase read: 50 indicator source files, docs (1292 + 661 lines), README (139 lines), test structure
- Competitive research via WebSearch/WebFetch: OnlineTechnicalIndicators.jl (57 indicators), pandas-ta (150+), TA-Lib
- Prior research: technical-indicators-survey.md (existing codebase research from 2026-04-01)
- Professional trading workflow mapping against current indicator set

## Architecture Compatibility

Not directly applicable (this is a strategic/prioritization spike, not an implementation task). However, noted:
- The macro-based architecture (`@prep_siso`/`@prep_miso`/`@prep_simo`/`@prep_mimo`) makes adding new indicators very low-friction
- The auto-discovery pattern (`readdir` + `include`) means zero registration overhead
- Documentation structure (indicator-reference.md) follows a consistent template that's easy to extend
- Test structure is well-organized (separate files per macro type)

## Risks Identified

1. **Outdated README is actively harmful**: Shows implemented indicators as "ToDo", making the library appear incomplete. This is the single most urgent fix.
2. **5 undocumented indicators (10% of library)**: ConnorsRSI, MassIndex, UltimateOscillator, Vortex, PivotPoints are implemented and tested but missing from indicator-reference.md.
3. **Trust gap for professional users**: No validation against TA-Lib reference values. Quant developers will not use a library they cannot independently verify.
4. **Indicator count comparison risk**: OnlineTechnicalIndicators.jl has 57 vs Foxtail's 50. A documentation-first approach means this gap may widen before it narrows. Mitigation: emphasize quality, testing depth, and unique features in README.

## Issues Encountered

- Codex CLI unavailable (permission denied for background bash execution). All three planned Codex consultations were conducted as direct Opus analysis instead.
- The indicator-reference.md header says "45 indicators" but the codebase has 50 indicator files (batch6 added 5). This inconsistency confirms the documentation-lag problem.
- README indicator count and ToDo list are significantly outdated vs actual implementation state.

## Files Produced

- `/Users/taka/proj/Foxtail.jl/.claude/docs/research/spike-indicators-vs-docs-feasibility.md` -- Full analysis report
- `/Users/taka/proj/Foxtail.jl/.claude/logs/agent-teams/spike-indicators-vs-docs/feasibility-analyst.md` -- This work log

## Time Spent

- Codebase analysis: Read 50 indicator files listing, full indicator-reference.md (1292 lines), adding-indicator.md (661 lines), README (139 lines), test structure
- Competitive research: 4 web searches, 3 web fetches (OnlineTechnicalIndicators.jl GitHub + docs, pandas-ta, quantified strategies)
- Prior research review: technical-indicators-survey.md
- Analysis synthesis and report writing
