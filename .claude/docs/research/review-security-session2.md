# Security Review: Session 2 Changes (Zero-Division Fixes + Test Restructure)

**Date**: 2026-04-01
**Commits reviewed**: `1898d06` (source fixes), `ea35fb7` (test restructure)
**Reviewer**: Security Reviewer (Opus subagent)

---

## Executive Summary

The session changes are **well-executed** with a clear security improvement focus. The zero-division guards close real numeric safety gaps. No hardcoded secrets, no injection risks, no path traversal vulnerabilities were found. A few minor observations and one medium-severity floating-point concern are documented below.

**Verdict**: PASS with minor advisory notes.

---

## Findings

### Finding 1: Floating-point accumulation drift in MFI sliding window

- **Severity**: Medium
- **File**: `src/indicators/MFI.jl`, lines 86-108
- **Description**: The MFI implementation uses a sliding window approach where `pos_flow` and `neg_flow` are accumulated via repeated addition and subtraction (`pos_flow += pos_mf[i]` / `pos_flow -= pos_mf[i - n]`). Over long time series (thousands of bars), floating-point accumulation errors can cause `pos_flow` or `neg_flow` to become slightly negative (e.g., `-1e-15`) when the true value is zero. Since the zero-check uses exact `== 0.0` comparison, a very small negative value would bypass the guard and flow into the `pos_flow / neg_flow` division. If `neg_flow` drifts to a tiny negative value while `pos_flow` is large and positive, the result could be outside the expected [0, 100] range.
- **Impact**: For typical financial data (hundreds to low thousands of bars), this is unlikely to manifest. For very long series or adversarial inputs, MFI values could exceed 100 or drop below 0 by a tiny amount.
- **Recommended fix**: Use `<= 0.0` instead of `== 0.0` for the guard checks, or clamp the final result to [0.0, 100.0]. The same pattern applies to CMF (lines 74-93) where `sum_vol` could theoretically drift negative.

### Finding 2: MFI edge case -- both flows zero returns 100.0 (design choice)

- **Severity**: Low
- **File**: `src/indicators/MFI.jl`, lines 100-101
- **Description**: When both `pos_flow` and `neg_flow` are zero (e.g., first bar, or a window where all typical prices are identical), MFI returns `100.0`. This is a valid design choice but differs from some reference implementations that return `50.0` for undefined money flow ratio. The docstring documents this (line 27: "when Positive MF sum is 0, MFI = 0"), but the code returns 100 when *both* are zero, not just when negative is zero.
- **Impact**: Cosmetic. The first bar will always show MFI=100 which could be misleading for downstream consumers expecting a neutral startup value.
- **Recommended fix**: Consider returning `50.0` when both flows are zero (truly neutral), or update the docstring to explicitly document this edge case.

### Finding 3: No negative volume validation

- **Severity**: Low
- **File**: `src/indicators/CMF.jl`, `src/indicators/MFI.jl`, `src/indicators/VPT.jl`, `src/indicators/NVI.jl`, `src/indicators/PVI.jl`, `src/indicators/EMV.jl`
- **Description**: None of the volume-consuming indicators validate that volume values are non-negative. Negative volumes are nonsensical in financial data but could be supplied by mistake (e.g., data pipeline errors). Negative volumes would silently produce incorrect results rather than failing explicitly.
- **Impact**: Low -- this is a data quality issue rather than a security vulnerability. No crash or undefined behavior would occur; just incorrect indicator values.
- **Recommended fix**: Consider adding an optional validation or at minimum documenting the assumption that volumes must be non-negative.

### Finding 4: CMF `hl_range <= 0.0` guard silently absorbs inverted High/Low

- **Severity**: Low
- **File**: `src/indicators/CMF.jl`, line 65
- **Description**: The guard `hl_range <= 0.0` treats `High < Low` (inverted data) the same as `High == Low`, silently producing `mfv[i] = 0.0`. This is defensively correct (avoids negative range division) but masks data quality issues. Inverted High/Low is always a data error in valid OHLCV data.
- **Impact**: Users with corrupted data get silently wrong results rather than an error signal. Not a security issue per se, but an observability gap.
- **Recommended fix**: No code change needed for safety. Consider adding a `@warn` or returning NaN for inverted ranges if stricter data validation is desired.

### Finding 5: ROC docstring missing (file only contains function body)

- **Severity**: Low (informational)
- **File**: `src/indicators/ROC.jl`
- **Description**: The ROC.jl file that was reviewed starts directly with the `@inline` function body without the docstring block that all other indicator files include. This is likely because the docstring is defined elsewhere or was already present before the diff boundary. Not a security issue.
- **Impact**: None.
- **Recommended fix**: None needed if docstring exists in the file above line 1 of the diff view.

---

## Items Verified (No Issues Found)

### Hardcoded Secrets / Credentials
- **Result**: CLEAN. Grep for `password`, `secret`, `api_key`, `token`, `credential`, `auth` across all changed source and test files returned zero matches.

### Path Traversal in Test File Loading
- **Result**: SAFE. All CSV file loading uses `joinpath(@__DIR__, "aapl.csv")` which constructs a path relative to the test file's own directory. `@__DIR__` is a compile-time macro resolved by Julia, not user-controlled at runtime. No string interpolation or user input is involved in path construction.

### Zero-Division Guards (Primary Review Focus)
All 6 zero-division fixes are correctly implemented:

| File | Guard Pattern | Correctness |
|------|-------------|-------------|
| `ROC.jl:13` | `iszero(prices[i-period]) ? 0.0 : ...` | Correct. Returns 0% change for zero-price base. |
| `NVI.jl:57` | `iszero(closes[i-1]) ? results[i-1] : ...` | Correct. Carries forward previous NVI value. |
| `PVI.jl:56` | `iszero(closes[i-1]) ? results[i-1] : ...` | Correct. Carries forward previous PVI value. |
| `VPT.jl:51` | `iszero(closes[i-1]) ? 0.0 : ...` | Correct. Adds zero delta for zero-price base. |
| `PPO.jl:58` | `ifelse(iszero(slow_ema), 0.0, ...)` | Correct. Vectorized guard using `@.` broadcast. |
| `CMF.jl:88` | `sum_vol == 0.0` check before division | Correct (pre-existing, not new). |
| `MFI.jl:100-106` | `neg_flow == 0.0` / `pos_flow == 0.0` checks | Correct (refactored, see Finding 1 for FP drift concern). |
| `EMV.jl:55,59` | `hl_diff == 0.0` and `box_ratio == 0.0` checks | Correct (pre-existing, EMV change was only extracting magic number to constant). |

### NaN/Inf Propagation in Tests
- **Result**: All test files include `!any(isnan, ...)` and `!any(isinf, ...)` assertions for every indicator output. The zero-denominator guard tests specifically verify:
  - `ROC` with zero-price input (test_Indicators_SISO.jl, lines 357-360)
  - `PPO` with zero-price input (test_Indicators_SIMO.jl, lines 167-170)
  - `VPT` with zero-price input (test_Indicators_MISO.jl, lines 536-540)
  - `NVI` with zero-price input (test_Indicators_MISO.jl, lines 593-597)
  - `PVI` with zero-price input (test_Indicators_MISO.jl, lines 650-654)
  - `CMF` with zero-volume input (test_Indicators_MISO.jl, lines 461-466)

### Test Restructure Safety
- **Result**: SAFE. The test restructure split `test_Indicators.jl` into 5 files by category (SISO, MISO, SIMO, MIMO, AAPL). Each file independently loads test data via `CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)`. `runtests.jl` uses `joinpath(dirname(@__FILE__), "test_$t.jl")` with a hardcoded list -- no user-controlled input in the file inclusion path.

### Unsafe External Data Usage
- **Result**: No external data fetching, network calls, or environment variable reads in any changed file. All test data is either:
  1. Hardcoded numeric arrays (deterministic, no `rand()`)
  2. Static CSV file bundled in the test directory

---

## Test Coverage Assessment for Zero-Division Fixes

| Indicator | Zero-Input Test | Boundary Test | Regression Test |
|-----------|----------------|---------------|-----------------|
| ROC | Yes (zero price) | Yes (period=0, length < period) | Yes (AAPL) |
| NVI | Yes (zero close) | Yes (wrong columns) | Yes (AAPL) |
| PVI | Yes (zero close) | Yes (wrong columns) | Yes (AAPL) |
| VPT | Yes (zero close) | Yes (wrong columns) | Yes (AAPL) |
| PPO | Yes (zero-start prices) | Yes (length < slow) | Yes (AAPL) |
| CMF | Yes (zero volume, H==L) | Yes (wrong columns, period=0) | Yes (AAPL) |
| MFI | Indirect (all-rising, all-falling) | Yes (wrong columns, period=0) | Yes (AAPL) |
| EMV | Indirect (constant H/L) | N/A (no param validation) | Yes (AAPL) |

---

## Summary of Recommendations

1. **[Medium]** Consider adding `clamp(results[i], 0.0, 100.0)` after the MFI calculation or using `<= 0.0` guards to protect against floating-point drift in very long series.
2. **[Low]** Decide on a consistent convention for "both flows zero" in MFI (100.0 vs 50.0) and document it.
3. **[Low]** Consider input validation for negative volumes across volume-consuming indicators.
4. **[Informational]** The test restructure eliminated all `rand()` usage in test data, replacing with deterministic hardcoded arrays -- this is a positive security and reproducibility improvement.
