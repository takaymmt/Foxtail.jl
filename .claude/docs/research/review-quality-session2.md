# Quality Review: Session 2 Changes (Zero-Division Fixes + Test Restructure)

**Reviewer**: Quality Reviewer (Opus subagent)
**Date**: 2026-04-01
**Commits**: `1898d06` (source fixes), `ea35fb7` (test restructure)
**Test Result**: All 4107 tests pass

---

## 1. Source Fixes Review

### 1.1 ROC Zero-Division Guard

**File**: `src/indicators/ROC.jl`, line 13
**Severity**: Low (no issue)

```julia
result[i] = iszero(prices[i-period]) ? 0.0 : (prices[i] - prices[i-period]) / prices[i-period] * 100.0
```

**Assessment**: Correct. When the denominator price is 0, returning 0.0 is a reasonable sentinel. The `iszero()` function is the idiomatic Julia way to check for zero. The edge case is documented implicitly through the test (`roc_zero[2] approx 0.0`).

**Minor suggestion**: The docstring for ROC (which appears to be missing from the file -- only the function body is present) should mention the zero-division behavior. Currently only the CMF and MFI docstrings document edge cases.

---

### 1.2 NVI/PVI Carry-Forward Semantics

**File**: `src/indicators/NVI.jl`, line 57; `src/indicators/PVI.jl`, line 56
**Severity**: Low (no issue, design choice is correct)

```julia
results[i] = iszero(closes[i-1]) ? results[i-1] : results[i-1] * (1.0 + (closes[i] - closes[i-1]) / closes[i-1])
```

**Assessment**: Returning `results[i-1]` (carry-forward) when `close[i-1] == 0` is the correct choice. NVI/PVI are cumulative indicators starting at 1000.0. When the previous close is zero, no meaningful rate of return can be computed, so preserving the current accumulated value is the most defensible behavior. It avoids introducing artificial jumps into the cumulative index.

**Alternative considered**: Returning 0.0 would reset the cumulative index, which would be destructive. Throwing an error would be too aggressive for a guard. Carry-forward is the right choice.

**Test coverage**: Both `NVI` and `PVI` tests include explicit zero-denominator guard tests:
- `nvi_zero_data = Float64[0.0 2000; 50.0 1500; 100.0 1800]` -- confirms carry-forward
- `pvi_zero_data = Float64[0.0 1000; 50.0 1500; 100.0 1200]` -- confirms carry-forward

---

### 1.3 PPO Broadcast Guard

**File**: `src/indicators/PPO.jl`, line 58
**Severity**: Low (no issue)

```julia
ppo_line = @. ifelse(iszero(slow_ema), 0.0, (fast_ema - slow_ema) / slow_ema * 100)
```

**Assessment**: This is correct Julia broadcast syntax. The `@.` macro applies broadcasting to all operations. `ifelse` (not `if`) is the correct choice here because it is a function (not a control flow statement) and works element-wise with broadcasting. `iszero` also broadcasts correctly.

**Important nuance**: `ifelse` evaluates both branches (unlike `if`), but since both branches are simple arithmetic expressions, there is no performance or correctness concern. The division `(fast_ema - slow_ema) / slow_ema * 100` will produce `Inf` or `NaN` when `slow_ema == 0`, but `ifelse` will discard that value and use `0.0` instead. This is safe because Julia's IEEE 754 arithmetic does not throw on division by zero.

**Test coverage**: Explicit zero-denominator test in SIMO tests, line 167-170:
```julia
ppo_zero = PPO([0.0, 0.0, 0.0, 0.0, 0.0, 1.0, ...]; fast=3, slow=5, signal=3)
@test !any(isnan, ppo_zero) && !any(isinf, ppo_zero)
```

---

### 1.4 EMV Constant Placement

**File**: `src/indicators/EMV.jl`, line 39
**Severity**: Low (no issue, minor style note)

```julia
const EMV_BOX_RATIO_SCALE = 100_000_000.0  # Arms' scaling factor for volume normalization
```

**Assessment**: Placing the constant at module level (outside the function) is correct Julia practice. In Julia, `const` declarations at module level are strongly typed and allow the compiler to optimize. Placing `const` inside a function is not allowed in Julia (it would be a syntax error). The `EMV_` prefix namespaces the constant properly, avoiding collisions.

This is the only module-level `const` in the entire `src/` directory, which is clean.

**No issue found.**

---

### 1.5 MFI O(n) Refactor

**File**: `src/indicators/MFI.jl`
**Severity**: Medium (semantic equivalence confirmed, but one subtle behavior difference)

**Original** (O(n*m) where m = window size):
```julia
for j in start:i
    if j == 1 || tp[j] == tp[j-1]
        continue
    elseif tp[j] > tp[j-1]
        pos_flow += mf[j]
    else
        neg_flow += mf[j]
    end
end
```

**New** (O(n) with pre-classification):
```julia
@inbounds for j in 2:nrows
    if tp[j] > tp[j-1]
        pos_mf[j] = mf[j]
    elseif tp[j] < tp[j-1]
        neg_mf[j] = mf[j]
    end
end
```

**Semantic equivalence analysis**:

The original skips bar 1 (`j == 1`) and neutral bars (`tp[j] == tp[j-1]`). The new version:
- `pos_mf[1] = 0.0` and `neg_mf[1] = 0.0` (initialized via `zeros`) -- equivalent to skipping bar 1
- When `tp[j] == tp[j-1]`, neither branch fires, so both remain 0.0 -- equivalent to `continue`
- When `tp[j] > tp[j-1]`, assigns to pos_mf -- equivalent
- When `tp[j] < tp[j-1]`, assigns to neg_mf -- equivalent

The sliding window subtraction (`pos_flow -= pos_mf[i - n]` / `neg_flow -= neg_mf[i - n]`) is equivalent to recomputing the sum each time because the pre-classified arrays are fixed.

**Verdict**: Semantically equivalent. The refactor is correct and improves time complexity from O(n*m) to O(n).

**One observation**: The comment `# tp[j] == tp[j-1] or j == 1: both remain 0.0 (neutral)` at line 83 says "or j == 1" but the loop starts at `j in 2:nrows`, so j is never 1. The comment is slightly misleading; it should say "j == 1 is handled by zeros initialization". This is cosmetic only.

---

### 1.6 CMF O(n) Refactor

**File**: `src/indicators/CMF.jl`
**Severity**: Low (no issue)

Same pattern as MFI: replaced the inner loop with a sliding window. The pre-computed `mfv[]` and `volumes[]` arrays are added/subtracted incrementally. This is a straightforward O(n^2) to O(n) optimization that preserves semantics.

**No issue found.**

---

## 2. Test Restructure Review

### 2.1 File Split Quality

**Severity**: Low (no issue)

The original `test_Indicators.jl` (1849 lines) was split into 5 files:
- `test_Indicators_SISO.jl` (404 lines) -- Single-Input Single-Output
- `test_Indicators_MISO.jl` (693 lines) -- Multi-Input Single-Output
- `test_Indicators_SIMO.jl` (235 lines) -- Single-Input Multi-Output
- `test_Indicators_MIMO.jl` (748 lines) -- Multi-Input Multi-Output
- `test_Indicators_AAPL.jl` (577 lines) -- AAPL integration tests

**Assessment**: The categorization is logical and follows the indicator type signatures:
- SISO: SMA, EMA, DEMA, HMA, etc. (Vector -> Vector)
- MISO: ADL, ATR, OBV, CMF, MFI, NVI, PVI, VPT, EMV, etc. (Matrix -> Vector)
- SIMO: BB, MACD, PPO, KST, StochRSI (Vector -> Matrix)
- MIMO: Stoch, WR, DonchianChannel, KeltnerChannel, Supertrend, DMI, Aroon, SqueezeMomentum, ParabolicSAR, Ichimoku (Matrix -> Matrix)
- AAPL: regression tests against real market data

The split preserves all tests (net +812 lines from 1850 to 2662, which accounts for the added zero-division tests from commit `1898d06`).

---

### 2.2 Data Loading Redundancy

**Severity**: Low (acceptable trade-off)

All four non-AAPL test files load AAPL data independently:
```julia
aapl = CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)
data_ts = aapl[end-100:end]
```

The AAPL test file uses a different subset:
```julia
aapl_full = CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)
aapl = TSFrames.subset(aapl_full, Date("2023-03-01"), Date("2024-06-30"))
```

**Assessment**: Each file loads `aapl.csv` independently. With Julia's `include()` mechanism in `runtests.jl`, each file runs in the same module scope, but the data is re-loaded 5 times. This is a minor inefficiency (CSV parsing is fast for a single file), but it makes each test file fully self-contained, which is a valid design choice. No functional issue.

**Note**: The SISO/MISO/SIMO/MIMO files use `aapl[end-100:end]` (last 101 rows, no date filtering), while the AAPL file uses `TSFrames.subset` with a fixed date range. These are intentionally different: the former is for type/smoke testing, the latter is for regression testing with deterministic date boundaries. This is fine.

---

### 2.3 Fixed Arrays Quality (MISO/MIMO)

**Severity**: Low (good quality)

The MISO file defines 100-row arrays with realistic financial data:
- `_high_col`: trending upward 102.5 to 168.4 with periodic dips
- `_low_col`: below high with realistic spread (~3.0 points)
- `_close_col`: between high and low
- `_vol_col`: varying 25000-53000 (realistic trading volumes)

The MIMO file also defines 100-row arrays:
- `_high_col`: trending upward 52.3 to 116.2
- `_low_col`: below high with spread
- `_close_col`: between high and low

**Assessment**: The data is realistic (not all-zeros, not degenerate). High > Close > Low is maintained throughout. Volume varies realistically. The upward trend with periodic dips mimics real market behavior. This is a significant improvement over the previous `rand()` arrays, which produced non-deterministic test results.

---

### 2.4 Duplicate or Conflicting Assertions

**Severity**: Low (no duplicates found)

After systematic comparison:
- Each indicator appears in exactly one of the SISO/MISO/SIMO/MIMO files (based on its I/O type)
- The AAPL file tests a subset of indicators with real AAPL data (regression focus)
- No indicator is tested in conflicting ways between files
- Some indicators appear in both their type-specific file AND the AAPL file, but the AAPL file focuses on regression values while the type file focuses on correctness/edge cases

**No duplicates or conflicts found.**

---

### 2.5 AAPL Regression Test Brittleness

**Severity**: Medium (design concern, not a bug)

**File**: `test/test_Indicators_AAPL.jl`

The AAPL tests use a fixed date range (`2023-03-01` to `2024-06-30`) which yields exactly 335 rows. Regression values are hardcoded with `atol=1e-6`.

**Risk assessment**:
- If the AAPL CSV data is updated with corrected/adjusted prices, all regression values would break.
- If corporate actions (stock splits) are applied retroactively, values would change.
- The `atol=1e-6` tolerance is tight enough to catch real bugs but will break on any data modification.

**Mitigation already in place**: The data file is checked into the repo and not fetched dynamically, so values are stable as long as the CSV is not modified.

**Recommendation**: Add a checksum or row-count assertion at the top of the AAPL test file:
```julia
@test nrow(aapl) == 335  # already present implicitly via comment
@test closes[1] == <known_value>  # canary to detect data modification
```

This already partially exists (`nrows = nrow(aapl)  # 335` as a comment) but is not asserted. If the data were to change, the first sign would be mysterious regression failures rather than a clear "data changed" message.

---

## 3. Findings Summary

| # | Severity | File | Finding | Recommendation |
|---|----------|------|---------|----------------|
| F1 | Medium | `MFI.jl:83` | Comment says "or j == 1" but j never equals 1 in the loop | Fix comment to clarify that j=1 is handled by zeros init |
| F2 | Medium | `test_Indicators_AAPL.jl` | No canary assertion to detect AAPL data modification | Add `@test nrow(aapl) == 335` and `@test closes[1] == <value>` |
| F3 | Low | `ROC.jl` | Docstring missing from file (only function body visible) | Verify docstring exists (may be in a separate docs file) |
| F4 | Low | `NVI.jl:57` / `PVI.jl:56` | Long ternary expression reduces readability | Consider extracting into a named helper or multi-line if/else |
| F5 | Low | Test files | AAPL CSV loaded 5 times independently | Acceptable for isolation; no action needed |
| F6 | Low | `MFI.jl:100-101` | When both pos_flow and neg_flow are 0 (first bar), returns 100.0 | Documented behavior, but 50.0 could be argued as more neutral. Original behavior preserved -- no change needed. |

---

## 4. Overall Assessment

**The changes are high quality.** The zero-division guards are correctly implemented across all 8 files using idiomatic Julia patterns (`iszero()`, `ifelse` for broadcast). The MFI and CMF refactors from O(n^2) to O(n) are semantically equivalent to the originals. The test restructure is well-organized with realistic fixed data arrays and comprehensive edge case coverage.

**No blocking issues found.** The two Medium findings (F1, F2) are cosmetic/defensive improvements, not correctness bugs.

**Test coverage for zero-division**: Every guarded indicator has at least one explicit zero-denominator test case:
- ROC: `[0.0, 1.0, 2.0, 3.0, 4.0]` with n=1
- PPO: `[0.0, 0.0, 0.0, ...]` prefix
- NVI: `[0.0 2000; 50.0 1500; ...]`
- PVI: `[0.0 1000; 50.0 1500; ...]`
- VPT: `[0.0 1000; 50.0 1500; ...]`
- CMF: `[10 10 10 1000; ...]` (High==Low), `[10 8 9 0; ...]` (zero volume)
- MFI: Covered by edge case tests (equal TP, zero flows)
- EMV: `[10 8 1000; 10 8 2000; ...]` (constant H/L, hl_diff=0 guard tested)
