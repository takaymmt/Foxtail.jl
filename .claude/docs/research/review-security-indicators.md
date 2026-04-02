# Security Review: 17 Technical Indicators Addition

**Reviewer:** Security Reviewer (Opus subagent)
**Date:** 2026-04-01
**Commit:** dd32c67
**Scope:** 22 source files in `src/indicators/`, `src/tools/`, and `src/Foxtail.jl`

---

## Executive Summary

The codebase is a Julia numerical computing library for financial technical indicators. The threat model is narrow: no network I/O, no file system writes, no secrets handling. The primary risks are **numeric robustness** issues that could produce incorrect financial signals (NaN/Inf propagation, division by zero) rather than traditional security vulnerabilities.

**No critical or high severity findings.** All findings are Medium or Low severity related to numeric edge cases.

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High     | 0 |
| Medium   | 5 |
| Low      | 7 |

---

## Findings

### MEDIUM Severity

#### M-1: Division by zero when previous close is zero in NVI, PVI, VPT, ROC

**Files and lines:**
- `src/indicators/NVI.jl:57` -- `(closes[i] - closes[i-1]) / closes[i-1]`
- `src/indicators/PVI.jl:56` -- `(closes[i] - closes[i-1]) / closes[i-1]`
- `src/indicators/VPT.jl:51` -- `volumes[i] * (closes[i] - closes[i-1]) / closes[i-1]`
- `src/indicators/ROC.jl:13` -- `(prices[i] - prices[i-period]) / prices[i-period] * 100.0`

**Description:** If any previous close price is exactly `0.0`, these divisions produce `Inf` or `NaN`. While `close = 0.0` is uncommon in real market data, it can occur in synthetic data, test data, or with instruments that have gone to zero. The resulting `Inf`/`NaN` will silently propagate through all downstream calculations.

**Impact:** Silent production of invalid indicator values that could drive incorrect trading decisions.

**Recommended fix:** Add a guard: when the denominator is zero, return `0.0` (consistent with how CMF, CCI, DMI handle similar cases).

---

#### M-2: Division by zero in PPO when slow EMA is zero

**File:** `src/indicators/PPO.jl:58`
```julia
ppo_line = @. (fast_ema - slow_ema) / slow_ema * 100
```

**Description:** If `slow_ema` is `0.0` at any point (possible when all prices are zero), this produces `Inf`/`NaN`. Unlike other indicators in this codebase, PPO does not guard against zero denominators.

**Impact:** Same as M-1 -- silent NaN/Inf propagation.

**Recommended fix:** Guard the division with a zero check.

---

#### M-3: Aroon division by zero when n=1

**File:** `src/indicators/Aroon.jl:69-70`
```julia
aroon_up   = 100.0 * (n - (i - max_idx)) / n
aroon_down = 100.0 * (n - (i - min_idx)) / n
```

**Description:** The parameter validation allows `n >= 1`. When `n = 1`, the division by `n` itself is not zero (it's 1), but the formula is mathematically degenerate: the "lookback window" is just the current bar, so Aroon is always 100. While not strictly a division-by-zero, `n = 1` is likely a user error. If the validation were weakened to `n >= 0`, this would be a true division-by-zero. Currently safe but fragile.

**Impact:** Low -- produces mathematically meaningless but valid numbers.

**Recommended fix:** Consider documenting that `n >= 2` is the practical minimum, or adding a warning.

---

#### M-4: MinMaxQueue get_max/get_min on empty queue

**File:** `src/tools/MinMaxQueue.jl:111,122`
```julia
function get_max(q::MinMaxQueue)
    return first(q.max_data)[1]
end
```

**Description:** Calling `get_max` or `get_min` (or `get_max_idx`/`get_min_idx`) on an empty `MinMaxQueue` will throw a `BoundsError` from the `CircDeque.first()` call. While this is an internal data structure not directly exposed to users, any indicator using it with incorrect window management could trigger this.

**Impact:** Unhandled exception / crash instead of a meaningful error message.

**Recommended fix:** Either add an `isempty` check that throws a descriptive `ArgumentError`, or document that callers must ensure non-empty state.

---

#### M-5: Ichimoku TSFrame wrapper edge case with single-row input

**File:** `src/indicators/Ichimoku.jl:152`
```julia
unit_step = oneunit(idx[end] - idx[end])
```

**Description:** When `length(idx) == 1`, this computes `idx[end] - idx[end]` which is `zero(eltype(idx))`, then `oneunit(zero(...))`. For `Date` types, this produces `Day(1)` which is reasonable. However, for custom index types, this may not behave as expected. Additionally, a single-row price matrix can still produce a valid Ichimoku result, but the future index generation is fragile.

**Impact:** Potential error with non-standard index types.

**Recommended fix:** Consider requiring `length(idx) >= 2` or documenting the single-row limitation.

---

### LOW Severity

#### L-1: DonchianChannel requires `len >= period` while other indicators do not

**File:** `src/indicators/DonchianChannel.jl:12-13`
```julia
if len < period
    throw(ArgumentError("price series length must be greater than or equal to period"))
end
```

**Description:** DonchianChannel throws when the input is shorter than the period, while most other indicators (CCI, CMF, MFI, etc.) gracefully handle short inputs by using partial windows. This inconsistency could confuse users.

**Impact:** Inconsistent API behavior.

**Recommended fix:** Either align with the partial-window approach used by other indicators, or document this requirement clearly.

---

#### L-2: EMV hardcoded volume scaling constant

**File:** `src/indicators/EMV.jl:56`
```julia
box_ratio = (vol[i] / 100_000_000.0) / hl_diff
```

**Description:** The `100_000_000.0` constant is hardcoded. While this is standard for EMV, it means the indicator may produce unexpected scale for instruments with very different volume magnitudes (e.g., crypto with billions in volume, or penny stocks with hundreds). This is a financial correctness issue, not a traditional security issue.

**Impact:** Potentially misleading indicator values for non-standard volume ranges.

**Recommended fix:** Consider making the volume divisor a parameter with a documented default.

---

#### L-3: No input validation on DPO, KST, EMV, KeltnerChannel for empty/short inputs

**Files:**
- `src/indicators/DPO.jl` -- no length check
- `src/indicators/KST.jl` -- no length check
- `src/indicators/EMV.jl` -- no column count check, no length check
- `src/indicators/KeltnerChannel.jl` -- no length check

**Description:** These indicators do not validate input length or (for EMV) column count. They will either produce empty results or throw cryptic errors from downstream function calls rather than giving clear error messages.

**Impact:** Poor user experience on invalid input.

**Recommended fix:** Add input validation at the start of each function, consistent with the pattern used in CCI, CMF, DMI, etc.

---

#### L-4: SqueezeMomentum requires `n >= 2` while most indicators accept `n >= 1`

**File:** `src/indicators/SqueezeMomentum.jl:56-57`
```julia
if n < 2
    throw(ArgumentError("period n must be >= 2"))
end
```

**Description:** This is actually correct for SqueezeMomentum (linear regression needs at least 2 points), but the inconsistency with other indicators could confuse users.

**Impact:** Minor API inconsistency. The validation is correct.

**Recommended fix:** None needed -- the validation is appropriate. Consider documenting why n >= 2.

---

#### L-5: Cumulative floating-point drift in VWAP

**File:** `src/indicators/VWAP.jl:48-55`
```julia
cum_tpv = 0.0
cum_v   = 0.0
@inbounds for i in 1:n
    tp = (highs[i] + lows[i] + closes[i]) / 3.0
    cum_tpv += tp * volumes[i]
    cum_v   += volumes[i]
    ...
end
```

**Description:** For very long time series (e.g., tick-level intraday data with millions of rows), the cumulative sums `cum_tpv` and `cum_v` may suffer from floating-point precision loss. This is a known limitation of naive cumulative summation.

**Impact:** Gradual loss of precision over very long series.

**Recommended fix:** For production use with very long series, consider Kahan compensated summation. For typical use cases (daily data), this is acceptable.

---

#### L-6: No NaN handling in any indicator

**Files:** All indicator files.

**Description:** None of the indicators check for `NaN` in input data. If any input value is `NaN`, it will silently propagate through all calculations. This is standard Julia behavior (and consistent with how Julia's standard library handles NaN), but it means users must pre-clean their data.

**Impact:** Silent propagation of NaN values.

**Recommended fix:** This is an API design choice. Consider documenting that inputs must not contain NaN, or adding an optional `skipnan` parameter.

---

#### L-7: No negative volume validation

**Files:** `src/indicators/CMF.jl`, `src/indicators/MFI.jl`, `src/indicators/VWAP.jl`, `src/indicators/VPT.jl`, `src/indicators/ForceIndex.jl`, `src/indicators/EMV.jl`, `src/indicators/NVI.jl`, `src/indicators/PVI.jl`

**Description:** None of the volume-based indicators validate that volume values are non-negative. Negative volume is physically meaningless and could produce incorrect indicator values. CMF explicitly handles `volumes[i] == 0.0` but not negative values.

**Impact:** Silently incorrect results with invalid input data.

**Recommended fix:** Consider adding a validation that volume values are non-negative, or document this assumption.

---

## Non-Findings (Verified Safe)

The following areas were reviewed and found to be properly handled:

1. **No hardcoded secrets or credentials** -- The codebase is a pure numerical library with no I/O, authentication, or secret management.

2. **No file system access** -- No files are read or written by any indicator function.

3. **No network access** -- No HTTP calls, sockets, or external service dependencies.

4. **No code injection via macros** -- The `@prep_siso`, `@prep_miso`, `@prep_simo`, `@prep_mimo` macros generate well-structured wrapper functions. Input to these macros is compile-time only (symbol names and defaults), not user-supplied at runtime.

5. **No denial of service via memory allocation** -- All allocations are proportional to input size. The `MinMaxQueue` and `CircBuff` are bounded by their capacity parameter. No unbounded growth paths exist.

6. **Array bounds checking** -- All `@inbounds` blocks are preceded by appropriate bounds validation (input length checks, period validation). The `@boundscheck` annotations in `CircBuff` and `CircDeque` provide safety when not in `@inbounds` context.

7. **Division by zero in CCI, CMF, DMI, MFI, VWAP** -- These indicators properly guard against zero denominators with explicit checks.

8. **Dynamic file inclusion in Foxtail.jl** -- Line 16-17 uses `readdir` + `filter` + `include` to auto-load indicator files. This only reads `.jl` files from the `indicators/` subdirectory within the package source. Since this is a package (not a user-writable directory), and Julia's `include` operates at compile time within the module scope, this is safe. An attacker would need write access to the package source directory to inject code.

---

## Recommendations (Priority Order)

1. **Address M-1/M-2:** Add zero-denominator guards to NVI, PVI, VPT, ROC, and PPO for robustness against edge-case inputs.
2. **Address M-4:** Add descriptive error messages to MinMaxQueue empty-state access.
3. **Address L-3:** Add consistent input validation (column count and length) to DPO, KST, EMV, KeltnerChannel.
4. **Address L-6:** Add a note to the package documentation about NaN handling expectations.
5. **Address L-7:** Consider adding optional volume validation.

---

## Conclusion

The codebase has no critical security vulnerabilities. The threat model is inherently limited since this is a pure numerical library with no I/O, no secrets, and no network access. The findings are all related to numeric robustness -- specifically, unguarded division by zero in edge cases that could produce silent `Inf`/`NaN` propagation. These are important for financial correctness but do not represent exploitable security vulnerabilities in the traditional sense.

The code quality is generally high: most indicators follow a consistent pattern of input validation, and the data structures (CircBuff, CircDeque, MinMaxQueue) are well-implemented with appropriate bounds checking.
