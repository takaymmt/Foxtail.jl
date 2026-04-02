# Security Review: Batch 6 Indicators

**Date:** 2026-04-02
**Reviewer:** Security Reviewer (Claude Agent)
**Scope:** MassIndex, UltimateOsc, Vortex, ConnorsRSI, PivotPoints

---

## Executive Summary

Overall, the batch 6 indicators follow solid defensive programming patterns. All five indicators validate parameter bounds, guard against division by zero, and use Julia's type system to constrain inputs. No critical or high-severity vulnerabilities were found. Several medium and low-severity findings are documented below, mostly related to edge-case handling for degenerate inputs and floating-point drift.

**Findings by severity:**
- Critical: 0
- High: 0
- Medium: 4
- Low: 6

---

## Findings

### MEDIUM-01: Floating-point accumulation drift in Vortex rolling sums
- **Severity:** Medium
- **File:** `src/indicators/Vortex.jl`, lines 78-98
- **Description:** Vortex maintains incremental running sums (`sum_vm_plus`, `sum_vm_minus`, `sum_tr`) by adding new values and subtracting old values from the CircBuff. Over long time series (thousands of bars), this add/subtract pattern accumulates floating-point rounding errors. Unlike MassIndex and UltimateOsc which recompute sums from scratch each iteration, Vortex uses the incremental approach.
- **Impact:** For very long series (10,000+ bars), accumulated drift could produce subtly incorrect VI+/VI- values. The magnitude is typically negligible for practical use (< 1e-10 per step), but could compound.
- **Recommended fix:** Either (a) periodically recompute the sum from scratch (e.g., every N iterations), or (b) switch to the full-recompute pattern used by MassIndex and UltimateOsc. Given the small window sizes (typically n=14), the current approach is acceptable for most practical use, but documenting the tradeoff would be prudent.

### MEDIUM-02: ConnorsRSI propagates exceptions from RSI/ROC on short input
- **Severity:** Medium
- **File:** `src/indicators/ConnorsRSI.jl`, lines 48-65
- **Description:** ConnorsRSI validates `len > 1` at line 48, but the internal calls to `RSI(prices; n=n_rsi)` (line 54) and `ROC(prices; n=1)` (line 61) have their own minimum length requirements. Specifically:
  - `RSI` requires `length > n + 1` (so `length > n_rsi + 1`)
  - `ROC(n=1)` requires `length > 2`
  
  For example, `ConnorsRSI(rand(2); n_rsi=3)` passes the `len > 1` check but will throw an `ArgumentError` from inside `RSI`. The error message will reference RSI's internal constraint rather than ConnorsRSI's interface, making debugging confusing.
- **Impact:** Confusing error messages for callers; not a safety issue per se, but violates the principle of clear input validation at the boundary.
- **Recommended fix:** Strengthen ConnorsRSI's upfront validation:
  ```julia
  min_len = max(n_rsi + 2, n_streak + 2, 3)  # RSI needs len > n+1; ROC(1) needs len > 2
  len >= min_len || throw(ArgumentError("price series too short: need at least $min_len elements"))
  ```

### MEDIUM-03: No minimum length validation for matrix indicators (empty/single-row edge case)
- **Severity:** Medium
- **Files:**
  - `src/indicators/MassIndex.jl` (line 43)
  - `src/indicators/UltimateOsc.jl` (line 47)
  - `src/indicators/Vortex.jl` (line 43)
- **Description:** These indicators accept a matrix with 0 rows. For 0-row input:
  - MassIndex: `EMA(zeros(0))` is called, which accesses `data[1]` on an empty vector (BoundsError).
  - UltimateOsc: `TR(prices)` accesses `prices[1, 1] - prices[1, 2]` on empty matrix (BoundsError).
  - Vortex: Same as UltimateOsc via `TR(prices)`.
  
  For 1-row input: These work correctly (bar 1 initialization handles it). The 0-row case is the problem.
- **Impact:** Unguarded BoundsError on empty input instead of a clear ArgumentError. While passing empty data is unusual, it should be handled gracefully.
- **Recommended fix:** Add early validation:
  ```julia
  nrows >= 1 || throw(ArgumentError("prices matrix must have at least 1 row"))
  ```

### MEDIUM-04: NaN input propagation is silent across all indicators
- **Severity:** Medium
- **Files:** All five indicator files
- **Description:** None of the indicators check for NaN or Inf values in the input data. If the input contains NaN (e.g., from a data feed gap), the NaN propagates silently through all arithmetic operations and contaminates the entire output via EMA/rolling-sum operations. For example:
  - A single NaN in `prices` for MassIndex poisons `range_vec`, then `single_ema`, then `double_ema`, then `ratio`, then the rolling sum -- potentially corrupting all subsequent output values.
  - For ConnorsRSI, NaN in the streak calculation would propagate through RSI.
- **Impact:** Silent data corruption. Users may not realize their results are invalid.
- **Recommended fix:** This is a library-wide design decision. Options:
  1. **Document the contract** clearly: "Input must not contain NaN/Inf" (low effort).
  2. **Add upfront validation**: `any(isnan, prices) && throw(ArgumentError("input contains NaN"))` (medium effort, safe).
  3. **NaN-aware arithmetic**: Skip or interpolate NaN values (high effort, complex).
  
  Option 2 is recommended as the best balance. However, this should be applied consistently across all indicators, not just batch 6.

---

### LOW-01: Division by zero guard produces 0.0 instead of NaN in MassIndex
- **Severity:** Low
- **File:** `src/indicators/MassIndex.jl`, lines 77-80
- **Description:** When `double_ema[i] == 0.0`, the ratio is set to `0.0`. This is mathematically questionable -- a ratio of two EMAs where the denominator is zero indicates degenerate data (all highs equal all lows). Returning `0.0` understates the Mass Index; returning `NaN` would signal the anomaly.
- **Impact:** Subtle undercount in MI for bars with zero-range data. In practice, this only occurs with constant price data (H==L), which is rare in real markets.
- **Recommended fix:** Acceptable as-is for practical use. Consider documenting the behavior.

### LOW-02: Division by zero guard in UltimateOsc returns 0.0 for all-constant prices
- **Severity:** Low
- **File:** `src/indicators/UltimateOsc.jl`, lines 131-134
- **Description:** When TR sums are zero (all prices identical), the averages are set to 0.0, yielding UO=0.0. This is the same pattern as LOW-01.
- **Impact:** Correct behavior for the degenerate case (no buying pressure, no true range). Tests explicitly validate this case (line 826-827 in test file). Acceptable.
- **Recommended fix:** None needed. Well-tested and documented via tests.

### LOW-03: Vortex division guard uses `> 0.0` instead of `!= 0.0`
- **Severity:** Low
- **File:** `src/indicators/Vortex.jl`, line 100
- **Description:** The guard `if sum_tr > 0.0` means negative `sum_tr` would also result in VI+=0, VI-=0 (defaults from `zeros`). While True Range is always non-negative by definition, floating-point drift from MEDIUM-01 could theoretically produce a tiny negative sum_tr after many subtractions.
- **Impact:** Extremely unlikely in practice. If it occurred, VI+/VI- would be incorrectly zeroed for that bar.
- **Recommended fix:** Change to `if sum_tr != 0.0` for consistency with other indicators, or add `sum_tr = max(sum_tr, 0.0)` as a clamp.

### LOW-04: PivotPoints accepts extreme/inverted HLCO data without validation
- **Severity:** Low
- **File:** `src/indicators/PivotPoints.jl`, line 45
- **Description:** PivotPoints does not validate that High >= Low, or that High >= Close >= Low (normal candle constraints). If given inverted data (e.g., High < Low), the calculations still proceed but produce levels in unexpected order (R1 < S1, etc.).
- **Impact:** Garbage-in/garbage-out behavior. This is consistent with other indicators in the codebase (ATR, Vortex, etc. also don't validate HLCO relationships).
- **Recommended fix:** Acceptable as a library-wide convention. Document that callers are responsible for HLCO sanity.

### LOW-05: `_percentile_rank` uses `sum()` with closure, not optimal for performance
- **Severity:** Low
- **File:** `src/indicators/ConnorsRSI.jl`, line 117
- **Description:** `sum(x -> x < data[i], window_before)` creates a closure on each iteration. With large lookback windows (n_pctrank=100, default), this iterates 100 elements per bar. For a 10,000-bar series, that's 1M comparisons -- acceptable but not optimal.
- **Impact:** Performance only, no correctness issue. The current implementation is O(n*k) where k is the lookback. A sorted structure could reduce to O(n*log(k)).
- **Recommended fix:** Acceptable for current use. Flag for optimization if profiling shows it's a bottleneck.

### LOW-06: Integer overflow theoretically possible for extreme period parameters
- **Severity:** Low
- **Files:** All five indicator files
- **Description:** Period parameters are `Int` (64-bit on most platforms). While validated as `>= 1`, there's no upper bound check. Passing `n = typemax(Int)` would cause `CircBuff` to attempt allocating a vector of size `2^63-1`, resulting in an OutOfMemoryError.
- **Impact:** Denial of service via memory exhaustion. However, this requires deliberate adversarial input and is impractical in normal use.
- **Recommended fix:** Consider adding reasonable upper bounds (e.g., `n <= length(prices)`) or document that extreme values may cause memory issues. This is a library-wide concern, not specific to batch 6.

---

## Test Coverage Assessment

| Indicator | Happy Path | Edge Cases | Error Validation | Division Guard | Numerical Precision |
|-----------|:---:|:---:|:---:|:---:|:---:|
| MassIndex | Yes | Constant range | 3 tests | Implicit (constant data) | Convergence test |
| UltimateOsc | Yes | Constant price (H==L==C) | 3 tests | Explicit (all zeros) | Hand-calculated bars 1-3 |
| Vortex | Yes | Uptrend/downtrend behavioral | 3 tests | Implicit (bar 1) | Hand-calculated bar 4 |
| ConnorsRSI | Yes | Equal prices (streak), percentile rank edge cases | 4 tests | N/A (uses RSI/ROC) | Helper functions tested |
| PivotPoints | Yes | All 5 methods, DeMark NaN columns | 3 tests | N/A (no division) | Hand-calculated all methods |

**Missing test cases (recommendations):**
1. Empty matrix input (0 rows) for MassIndex, UltimateOsc, Vortex -- would expose MEDIUM-03
2. ConnorsRSI with length=2 and large n_rsi -- would expose MEDIUM-02
3. NaN/Inf input for all indicators -- would document MEDIUM-04 behavior
4. Very long series (1000+ bars) for Vortex to verify MEDIUM-01 drift is negligible

---

## Summary Table

| ID | Severity | Indicator | Issue | Actionable? |
|----|----------|-----------|-------|-------------|
| MEDIUM-01 | Medium | Vortex | FP drift in incremental sums | Document or refactor |
| MEDIUM-02 | Medium | ConnorsRSI | Weak input length validation | Fix validation |
| MEDIUM-03 | Medium | MassIndex/UltimateOsc/Vortex | No empty-input guard | Add validation |
| MEDIUM-04 | Medium | All | Silent NaN propagation | Library-wide decision |
| LOW-01 | Low | MassIndex | 0.0 for zero-denominator ratio | Document |
| LOW-02 | Low | UltimateOsc | 0.0 for zero TR sums | Acceptable |
| LOW-03 | Low | Vortex | `> 0.0` vs `!= 0.0` guard | Minor fix |
| LOW-04 | Low | PivotPoints | No HLCO sanity check | Document |
| LOW-05 | Low | ConnorsRSI | O(n*k) percentile rank | Performance only |
| LOW-06 | Low | All | No upper bound on period params | Library-wide |

---

## Conclusion

The batch 6 implementations are **well-structured and production-ready** for normal market data use. The code demonstrates consistent defensive patterns:
- All parameter bounds are validated
- All division operations are guarded
- Array accesses use `@inbounds` within properly bounded loops
- Type safety is enforced via Julia's dispatch system

The primary recommendation is to address MEDIUM-02 (ConnorsRSI length validation) and MEDIUM-03 (empty input guards) as quick fixes, and to make a library-wide decision on NaN handling policy (MEDIUM-04).
