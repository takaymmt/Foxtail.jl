# Test Review Report: Batch 6 Indicators

**Date**: 2026-04-02
**Reviewer**: Opus subagent (test-reviewer)
**Status**: All 4,267 tests passing (including batch 6)

## Scope

5 new indicators added in batch 6:
- ConnorsRSI (SISO) -- `test_Indicators_SISO.jl`
- MassIndex (MISO) -- `test_Indicators_MISO.jl`
- UltimateOsc (MISO) -- `test_Indicators_MISO.jl`
- Vortex (MIMO) -- `test_Indicators_MIMO.jl`
- PivotPoints (MIMO) -- `test_Indicators_MIMO.jl`

---

## Per-Indicator Assessment

### 1. ConnorsRSI (lines 405-471 of test_Indicators_SISO.jl)

| Checklist Item | Status | Notes |
|---|---|---|
| Happy path | PASS | TSFrame and Vector tested with real AAPL data |
| Type checks | PASS | `isa(result, TSFrame)` and `isa(result_vec, Vector{Float64})` |
| Column names | PASS | `names(result) == ["ConnorsRSI"]` |
| Length | PASS | `nrow(result) == nrow(data_ts)` and `length(result_vec) == length(close_vec)` |
| No Inf | PASS | `!any(isinf, result_vec)` |
| Numerical correctness | PASS | _streak and _percentile_rank helpers tested with hand-calculated values |
| Range check [0,100] | PASS | `all(0.0 .<= valid_vals .<= 100.0)` for non-warmup values |
| Error cases | PASS | n_rsi=0, n_streak=0, n_pctrank=0, length=1 all throw ArgumentError |
| Streak equal-close reset | PASS | Tests 5-6: explicit `[1,2,3,2,2,1]` verifying index 5=0.0 |
| PercentRank strictly-less | PASS | Tests 7-9: equal values -> 0%, increasing -> 100% |
| Custom parameters | PASS | `ConnorsRSI(close_vec; n_rsi=2, n_streak=3, n_pctrank=50)` |
| AAPL regression | **MISSING** | Uses data_ts (101 rows) as smoke test, but no dedicated AAPL regression in test_Indicators_AAPL.jl |

**Gaps Found:**

- **[Medium] No NaN check**: Tests check `!any(isinf, ...)` but NOT `!any(isnan, ...)`. Other indicators (ADL, CCI, Stoch, etc.) consistently check both `isnan` AND `isinf`. Since ConnorsRSI composes RSI + ROC which can produce NaN in edge cases, this is a meaningful omission.
- **[Low] No AAPL regression test in test_Indicators_AAPL.jl**: The inline AAPL smoke test with `data_ts` is adequate for correctness, but the AAPL regression file has pinned reference values for other indicators. Adding ConnorsRSI regression values would guard against future refactoring regressions.
- **[Low] No numerical validation of composite output**: The sub-components (_streak, _percentile_rank) are well-tested in isolation, but there is no hand-calculated end-to-end ConnorsRSI value verified (e.g., "for these 10 prices, ConnorsRSI[8] should be X.XXX"). This makes it harder to catch integration bugs between components.

---

### 2. MassIndex (lines 723-775 of test_Indicators_MISO.jl)

| Checklist Item | Status | Notes |
|---|---|---|
| Happy path | PASS | Vector and TSFrame tested |
| Type checks | PASS | `isa(result, Vector{Float64})`, `isa(res, TSFrame)` |
| Column names | PASS | `"MassIndex_25"` and `"MassIndex_10"` verified |
| Length | PASS | `length(MassIndex(vec2_hl)) == 100` |
| No Inf | PASS | `!any(isinf, mi_result)` |
| Numerical correctness | PASS | Bar 1 ratio=1.0 verified; constant range converges to n=5.0 |
| Non-negative check | PASS | `all(v -> v >= 0.0, mi_result)` |
| Error cases | PASS | Wrong cols, n=0, ema_period=0 |
| Convergence behavior | PASS | Constant range data converges to n (5.0 +/- 0.1) |
| AAPL smoke test | PASS | TSFrame and Matrix both tested with AAPL |
| All finite | PASS | `all(isfinite, mi_result)` |

**Gaps Found:**

- **[Low] No NaN check**: `!any(isinf, ...)` is checked but not `!any(isnan, ...)`. However, `all(isfinite, mi_result)` IS checked on line 761, which catches both NaN and Inf. The `!any(isinf, ...)` on line 742 is slightly redundant but not harmful. No actual gap.
- **[Low] No AAPL regression test in test_Indicators_AAPL.jl**: Same pattern as ConnorsRSI. Inline AAPL smoke test exists but no pinned reference values.
- **[Low] No reversal bulge behavior test**: The "reversal bulge" (MI > 27 then drops below 26.5) is the signature MassIndex signal. A behavioral test with crafted data showing range widening/narrowing would add confidence, but is not strictly required for correctness.

---

### 3. UltimateOsc (lines 777-841 of test_Indicators_MISO.jl)

| Checklist Item | Status | Notes |
|---|---|---|
| Happy path | PASS | Vector and TSFrame tested |
| Type checks | PASS | `isa(result, Vector{Float64})`, `isa(res, TSFrame)` |
| Column names | PASS | `"UltimateOsc"` verified |
| Length | PASS | `length(UltimateOsc(vec3)) == 100` |
| No Inf | PASS | `!any(isinf, uo_result)` |
| Numerical correctness | PASS | Bars 1-3 hand-calculated with full working. Excellent detail. |
| Range check [0,100] | PASS | `all(v -> 0.0 <= v <= 100.0, uo_result)` |
| Error cases | PASS | Wrong cols, fast=0, medium=0, slow=0 |
| Constant price edge case | PASS | H==L==C -> UO=0 (zero-division guard) |
| All finite | PASS | `all(isfinite, uo_result)` |
| AAPL smoke test | PASS | TSFrame and Matrix tested |

**Gaps Found:**

- **[Low] No AAPL regression test in test_Indicators_AAPL.jl**: Same pattern.
- **[Low] No behavioral test for overbought/oversold**: A strongly rising series should push UO toward 100, and a strongly falling series toward 0. This would mirror the DMI/Aroon pattern of testing trend direction behavior.
- **[Low] No ordering constraint test (fast < medium < slow)**: The source allows any values (fast=20, medium=5, slow=1), but typically fast < medium < slow. An explicit test showing that inverted params still produce valid [0,100] output would increase robustness confidence.

---

### 4. Vortex (lines 749-825 of test_Indicators_MIMO.jl)

| Checklist Item | Status | Notes |
|---|---|---|
| Happy path | PASS | Matrix and TSFrame tested |
| Type checks | PASS | `isa(result, Matrix{Float64})`, `isa(res, TSFrame)` |
| Column names | PASS | `"Vortex_VIPlus"`, `"Vortex_VIMinus"` |
| Length | PASS | `size(vx, 1) == length(_high_col)` |
| No Inf | PASS | `!any(isinf, vx)` |
| Numerical correctness | PASS | Hand-calculated bar 4 with n=3: VI+=1.1, VI-=0.6 verified |
| Bar 1 initialization | PASS | `vx[1,1] == 0.0`, `vx[1,2] == 0.0` |
| Uptrend behavior | PASS | VI+ > VI- for strong uptrend at end |
| Downtrend behavior | PASS | VI- > VI+ for strong downtrend at end |
| Error cases | PASS | Wrong cols (2 and 4), n=0 |
| AAPL smoke test | PASS | TSFrame tested, length verified |

**Gaps Found:**

- **[Low] No NaN check**: Neither `!any(isnan, ...)` nor `all(isfinite, ...)` is tested. Only `!any(isinf, ...)`. For robustness, `all(isfinite, vx)` should be added.
- **[Low] No AAPL regression test in test_Indicators_AAPL.jl**: Same pattern.

---

### 5. PivotPoints (lines 843-972 of test_Indicators_MIMO.jl)

| Checklist Item | Status | Notes |
|---|---|---|
| Happy path | PASS | Matrix and TSFrame tested |
| Type checks | PASS | `isa(result, Matrix{Float64})`, `isa(res, TSFrame)` |
| Column names | PASS | All 7 columns verified |
| Output size | PASS | `size(pp, 2) == 7` |
| No Inf | PASS | `!any(isinf, pp)` |
| All 5 methods tested | PASS | Classic, Fibonacci, Woodie, Camarilla, DeMark all have hand-calculated tests |
| Classic hand-calc | PASS | P, R1-R3, S1-S3 all verified against formulas |
| Classic level ordering | PASS | S3 < S2 < S1 < P < R1 < R2 < R3 |
| Fibonacci hand-calc | PASS | With 0.382, 0.618, 1.000 ratios verified |
| Fibonacci level ordering | PASS | Full ordering verified |
| Woodie hand-calc | PASS | P uses Open, R1/R2/S1 verified. P != Classic P verified. |
| Camarilla hand-calc | PASS | C +/- 1.1*R/12, /6, /4 verified |
| Camarilla level ordering | PASS | Full ordering verified |
| DeMark C<O | PASS | X = H + 2L + C, Pivot/R1/S1 verified |
| DeMark C>O | PASS | X = 2H + L + C, Pivot/R1/S1 verified |
| DeMark C==O | PASS | X = H + L + 2C, Pivot/R1/S1 verified |
| DeMark NaN columns | PASS | R2/R3/S2/S3 are NaN, P/R1/S1 not NaN (multi-row verified) |
| All methods TSFrame | PASS | All 5 methods produce TSFrame |
| Error cases | PASS | Wrong cols (3, 2), invalid method |
| AAPL smoke test | PASS | TSFrame tested, length verified |

**Gaps Found:**

- **[Low] No NaN check for non-DeMark methods**: `!any(isinf, pp)` is checked but not `!any(isnan, pp)` for Classic method. Since Classic initializes with `zeros()` this is safe, but explicit `all(isfinite, ...)` would be more defensive.
- **[Low] No AAPL regression test in test_Indicators_AAPL.jl**: Same pattern.
- **[Low] Woodie: R3/S2/S3 not explicitly verified**: Only P, R1, R2, S1 are checked for Woodie. R3, S2, S3 are computed by the same formula as Classic (just different P), so this is very low risk.

---

## Summary of Gaps

### High Priority
None found. All indicators have solid test coverage.

### Medium Priority

| # | Indicator | Gap | Recommendation |
|---|-----------|-----|----------------|
| 1 | ConnorsRSI | No `isnan` check | Add `@test !any(isnan, result_vec)` |

### Low Priority

| # | Indicator | Gap | Recommendation |
|---|-----------|-----|----------------|
| 2 | ConnorsRSI | No AAPL regression in test_Indicators_AAPL.jl | Add pinned regression values |
| 3 | ConnorsRSI | No end-to-end numerical verification | Add hand-calculated composite value test |
| 4 | MassIndex | No AAPL regression in test_Indicators_AAPL.jl | Add pinned regression values |
| 5 | MassIndex | No reversal bulge behavior test | Nice-to-have |
| 6 | UltimateOsc | No AAPL regression in test_Indicators_AAPL.jl | Add pinned regression values |
| 7 | UltimateOsc | No behavioral trend test | Add rising/falling series test |
| 8 | Vortex | No `isnan`/`isfinite` check | Add `@test all(isfinite, vx)` |
| 9 | Vortex | No AAPL regression in test_Indicators_AAPL.jl | Add pinned regression values |
| 10 | PivotPoints | No `isnan` check for non-DeMark | Add `@test all(isfinite, ...)` for Classic |
| 11 | PivotPoints | No AAPL regression in test_Indicators_AAPL.jl | Add pinned regression values |
| 12 | PivotPoints | Woodie R3/S2/S3 not verified | Very low risk, formulas same as Classic |

---

## Overall Quality Assessment

**Score: 9/10**

The batch 6 tests are **excellent** overall:

- **Strong numerical validation**: UltimateOsc bar-by-bar hand calculations are particularly thorough. PivotPoints covers all 5 methods with formula verification. Vortex has a proper hand-calculated test.
- **Good edge case coverage**: ConnorsRSI tests streak resets on equal close, percentile rank with all-equal values. UltimateOsc tests constant price (zero-division guard). PivotPoints tests all three DeMark conditionals.
- **Consistent pattern adherence**: Tests follow the established project patterns from DMI/Aroon/CCI.
- **Behavioral tests**: Vortex has uptrend/downtrend behavioral validation.

The only medium-priority gap is the missing `isnan` check for ConnorsRSI. All other gaps are low priority and would not block a merge.

The most impactful improvement would be adding AAPL regression tests to `test_Indicators_AAPL.jl` for all 5 indicators, which would bring the batch to parity with earlier indicator batches.
