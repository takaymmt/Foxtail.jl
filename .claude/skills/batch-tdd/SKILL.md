---
name: batch-tdd
description: Implement multiple related items using TDD, delegating dependency-aware batches to foreground subagents. Fills the gap between single-item /tdd and parallel /team-implement.
disable-model-invocation: true
---

# Batch TDD Implementation

Implement $ARGUMENTS using batched TDD delegation to subagents.

## When to Use This Skill

- Implementing **5+ related items** (e.g., a family of indicators, API endpoints, data models)
- Items share a **common pattern** (same file structure, same test conventions)
- Items have **inter-dependencies** that require sequential ordering
- Context window would overflow if done in a single agent

Do NOT use when:
- Implementing 1–3 items → use `/tdd` directly
- Items are fully independent and can be parallelized safely → use `/team-implement`

---

## Phase 1: Dependency Analysis

Before batching, build a dependency graph.

```
For each item:
  - What existing building blocks does it reuse?
  - Does it depend on another item in the list?
  - What complexity tier is it (trivial / easy / medium / complex)?
```

Group items into batches:
1. **No dependencies** — can start immediately
2. **Depends on batch 1** — start after batch 1 passes
3. **Complex / special cases** — handle last, one per subagent

Rule of thumb: 2–4 items per batch for medium-complexity items; 1 item per batch for complex ones.

---

## Phase 2: Subagent Prompt Template

For each batch, launch a **foreground** `general-purpose` subagent with this structure:

```
You are implementing [N] items for [project]. Use TDD (test first, then implement).

## Project Location
[path]

## Key Architecture (already understood)
[Paste only the conventions the subagent needs — file layout, macro system, test file location, run command]

## Read These Files First
[List 2–4 files that show the pattern to follow]

## Items to Implement

### Item 1: [Name]
- Spec: [algorithm, inputs, outputs, macro/decorator]
- Numerical reference values: [known expected outputs for test assertions]

### Item 2: [Name]
...

## TDD Process
For EACH item:
1. Write tests → run → confirm failure
2. Implement
3. Run → confirm all pass
4. Only proceed to next item when passing

## Final Check
Full test suite. All [N] existing tests must pass.
Report: files created, final test count, any failures.
```

Key principles for the prompt:
- Provide **numerical reference values** for test assertions — subagents cannot guess them
- State the **existing test count** so the subagent can verify no regressions
- List **reusable building blocks** explicitly (the subagent may not discover them otherwise)
- Keep architecture description **minimal** — only what's needed for this batch

---

## Phase 3: Execution Loop

```
batch_1 → subagent (foreground) → verify pass count → batch_2 → ...
```

Wait for each subagent to complete before launching the next. Use **background** only for truly independent batches with no shared test files.

After each batch:
- Confirm reported test count is expected (previous + new)
- If subagent reports failures: investigate before proceeding

---

## Phase 4: Wrap-Up

After all batches complete:

```bash
# Run full suite one final time
julia --project test/runtests.jl   # or equivalent
```

Report to user:
```markdown
## Batch TDD Complete: [Feature Family]

### Implemented
- [x] Item 1 — [file], [N] tests
- [x] Item 2 — [file], [N] tests
...

### Test Count
Before: [N] → After: [M] (+[diff])

### Infrastructure Changes
[Any shared utilities added]
```

---

## Discovered From

This pattern was extracted from a session that implemented 17 Julia technical indicators in 11 subagent batches, growing from 2932 → 3702 tests with zero regressions.

Key lessons:
- Providing numerical reference values in the prompt was critical — subagents cannot derive expected values without them
- Julia's precompilation cache required clearing after adding new files; note similar framework-specific gotchas in the prompt
- Complex items (state machines, special-case wrappers) always warranted their own dedicated subagent
- "Quick wins" (3–4 trivial/easy items sharing a pattern) batch well together
