# Quality Review: AnchoredVWAP Implementation

**Reviewer**: Quality Reviewer (Opus subagent)
**Date**: 2026-04-02
**Commit**: feat: AnchoredVWAP を追加（51指標目）
**Verdict**: PASS with minor findings (no blockers)

---

## Files Reviewed

| File | Status | Lines |
|------|--------|-------|
| `src/indicators/AnchoredVWAP.jl` | NEW | 114 |
| `test/test_Indicators_MISO.jl` | MODIFIED | AnchoredVWAP testset (lines 225-279) |
| `test/test_Indicators_AAPL.jl` | MODIFIED | AAPL AnchoredVWAP testset (lines 354-385) |
| `docs/indicator-reference.md` | MODIFIED | AnchoredVWAP entry added |
| `README.md` | MODIFIED | Count updated to 51 |

---

## Findings

### Finding 1: Inconsistent empty-matrix validation vs VWAP

- **Severity**: Low
- **File**: `src/indicators/AnchoredVWAP.jl`, lines 38-40
- **Current code**:
  ```julia
  if size(data, 1) == 0
      throw(ArgumentError("data matrix must not be empty"))
  end
  ```
- **Issue**: VWAP (`src/indicators/VWAP.jl`) does NOT validate for empty matrices -- it simply returns an empty `zeros(0)` vector. AnchoredVWAP throws an error instead. This creates an inconsistency: `VWAP(Matrix{Float64}(undef, 0, 4))` returns `Float64[]`, but `AnchoredVWAP(Matrix{Float64}(undef, 0, 4); anchor=1)` throws.
- **Assessment**: AnchoredVWAP's behavior is arguably *better* since `anchor=1` on an empty matrix is logically invalid. The docstring says `anchor=1` is the default and the valid range is `1 <= anchor <= size(data, 1)`, so 0 rows means no valid anchor. This is defensible, but the inconsistency should be noted.
- **Suggested improvement**: No code change needed. If desired, add a comment noting that the empty check is intentional because no valid anchor exists for 0-row data (unlike VWAP which degenerates gracefully).

### Finding 2: `anchor` default value of `1` in the raw function may be misleading

- **Severity**: Low
- **File**: `src/indicators/AnchoredVWAP.jl`, line 37
- **Current code**:
  ```julia
  @inline Base.@propagate_inbounds function AnchoredVWAP(data::Matrix{Float64}; anchor::Int=1)
  ```
- **Issue**: When `anchor=1`, the function is semantically identical to `VWAP`. The TSFrame wrapper correctly does NOT provide a default (the `anchor` kwarg is required there, line 107: `anchor` without default), which is good. However, the raw Matrix function has `anchor::Int=1` as default, meaning `AnchoredVWAP(data)` silently becomes `VWAP(data)`. A user might call the raw function thinking they set an anchor but forgetting to pass it.
- **Assessment**: This is a design choice. Having a sensible default (`1` = start of series) is reasonable for the raw function, and the docstring clearly documents this. The TSFrame wrapper correctly requires it explicitly. No change needed, but worth noting.
- **Suggested improvement**: None required. Alternatively, the raw function could also require the `anchor` keyword (no default), but this would break the pattern of the docstring example `AnchoredVWAP(data; anchor=2)` which already demonstrates explicit passing.

### Finding 3: `_anchored_vwap_resolve` has redundant range check

- **Severity**: Low
- **File**: `src/indicators/AnchoredVWAP.jl`, lines 84-87
- **Current code**:
  ```julia
  n = nrow(ts)
  if anchor < 1 || anchor > n
      throw(ArgumentError("anchor must be between 1 and the number of rows (got $anchor for $n rows)"))
  end
  ```
- **Issue**: When the `Int` path goes through `_anchored_vwap_resolve`, it validates the anchor range. Then the resolved `anchor_idx` is passed to the raw `AnchoredVWAP(prices; anchor=anchor_idx)` which validates the range again (line 44). This means `ArgumentError` for out-of-range anchor is thrown twice in the call chain for the TSFrame pathway -- though in practice only the first check fires, so the second is unreachable. This is a minor redundancy, not a bug.
- **Assessment**: Defensive programming. Both the resolver and the raw function independently validate, which is correct for public APIs that can be called separately. No change needed.

### Finding 4: No `@inline` / `@propagate_inbounds` on helper or TSFrame wrapper

- **Severity**: Low (style consistency)
- **File**: `src/indicators/AnchoredVWAP.jl`, lines 76 and 107
- **Current code**:
  ```julia
  function _anchored_vwap_resolve(ts::TSFrame, anchor::Union{Int, Dates.TimeType})::Int
  ...
  function AnchoredVWAP(ts::TSFrame; anchor, fields::Vector{Symbol}=[:High, :Low, :Close, :Volume])
  ```
- **Issue**: The raw function has `@inline Base.@propagate_inbounds`, but the helper and TSFrame wrapper do not. This is consistent with the Ichimoku pattern (Ichimoku's TSFrame wrapper at line 134 also lacks `@inline`), but differs from the `@prep_miso` macro-generated wrappers which don't use these annotations either.
- **Assessment**: Correct behavior. The `@inline` and `@propagate_inbounds` are only meaningful for the hot computational loop. The TSFrame wrapper is a thin dispatch layer. No change needed.

### Finding 5: `using Dates` at file top

- **Severity**: Low (style)
- **File**: `src/indicators/AnchoredVWAP.jl`, line 1
- **Current code**:
  ```julia
  using Dates
  ```
- **Issue**: This is the only indicator file that has a `using` statement at the top. Let me verify...
- **Verification**: Checked `src/indicators/Ichimoku.jl` -- it does NOT have `using Dates` despite its TSFrame wrapper also using date math. This is because `Dates` is likely available from the module scope or from `TSFrames` re-exporting it. However, `AnchoredVWAP.jl` explicitly uses `Dates.TimeType` in the type annotation, so the `using Dates` is needed unless `Dates` is already imported at module level.
- **Assessment**: Checking `src/Foxtail.jl` -- it only imports `TSFrames` and `LinearAlgebra`. `Dates` may be available transitively, but the explicit `using Dates` is safe and correct. However, it is the only indicator file with this pattern. Minor style inconsistency.
- **Suggested improvement**: Either add `using Dates` to `src/Foxtail.jl` at the module level (since `Dates` is a stdlib), or verify that `Dates.TimeType` works without the import (if it does, remove line 1). Currently functional, so low priority.

### Finding 6: Docstring accuracy and completeness -- excellent

- **Severity**: N/A (Positive observation)
- **File**: `src/indicators/AnchoredVWAP.jl`, lines 3-36 and 69-75 and 92-106
- **Assessment**: All three docstrings (raw function, resolver, TSFrame wrapper) are comprehensive, well-structured, and follow the exact same format as VWAP.jl. Formula notation is clear. Parameters, returns, interpretation, example, and See Also sections are all present. The resolver's docstring clearly documents the date-lookup behavior. Excellent work.

### Finding 7: Test coverage -- comprehensive

- **Severity**: N/A (Positive observation)
- **Files**: `test/test_Indicators_MISO.jl` (lines 225-279), `test/test_Indicators_AAPL.jl` (lines 354-385)
- **Assessment**: The test suite covers:
  1. Type checks (Vector and TSFrame outputs)
  2. Column naming
  3. Anchor=1 parity with VWAP (critical correctness test)
  4. Pre-anchor NaN / post-anchor finite
  5. Hand-calculated numerical accuracy (5-row data with exact expected values)
  6. Slice parity (anchor=3 result matches VWAP on rows 3:5)
  7. Last-row anchor edge case
  8. TSFrame Int vs Date anchor equivalence
  9. 5 distinct error cases
  10. AAPL integration: length, index, VWAP parity, mid-range NaN/finite, date equivalence, range bounds

  This is thorough and well-structured. The hand-calculated test (finding 4 in tests) with exact expected values is particularly good.

---

## Checklist Results

| Criterion | Verdict | Notes |
|-----------|---------|-------|
| Single responsibility | PASS | Raw function computes, resolver resolves anchors, TSFrame wrapper dispatches |
| Function length | PASS | Longest function is 30 lines (raw AnchoredVWAP). Well within limits |
| Type annotations | PASS | All parameters typed. Return type on resolver (`::Int`). Raw function signature fully typed |
| Naming clarity | PASS | `AnchoredVWAP` is clear, `_anchored_vwap_resolve` is descriptive with underscore prefix for internal use |
| Magic numbers | PASS | Only `3.0` in TP calculation (standard formula, same as VWAP) and `0.0` initializers |
| Early return pattern | PASS | Validation uses early-throw, no deep nesting |
| Consistency with VWAP.jl | PASS | Same structure: column views, cumulative loop, zero-volume guard. Docstring follows same format |
| Consistency with Ichimoku.jl wrapper | PASS | Hand-written TSFrame wrapper follows the same dispatch pattern. No extended index needed (unlike Ichimoku) |
| Error messages | PASS | All ArgumentError messages include context (got X for Y rows) |
| Docstrings | PASS | Comprehensive, accurate, properly formatted |
| File size | PASS | 114 lines -- well within 200-400 target |
| Tests | PASS | 10+ distinct test cases covering happy path, edge cases, errors, and AAPL integration |

---

## Summary

The AnchoredVWAP implementation is high quality with no blocking issues. It correctly extends the VWAP pattern with an anchor parameter, provides a well-designed TSFrame wrapper with date-based anchor support (following the Ichimoku hand-written wrapper pattern since `@prep_miso` cannot handle the `anchor` keyword), and has comprehensive test coverage.

The 5 low-severity findings are all minor style/consistency observations, none requiring code changes. The implementation is clean, well-documented, and ready for production use.

**Recommendation**: No changes required. All findings are informational.
