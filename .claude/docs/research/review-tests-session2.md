# Test Review Report: Session 2 Changes

**Date**: 2026-04-01
**Scope**: Zero-division fixes (commit 1898d06) + Test restructure (commit ea35fb7)
**Test Result**: All 4107 tests pass (15.8s)

---

## 1. Executive Summary

The test suite is **well-structured and thorough**. The 5-file split (SISO/MISO/SIMO/MIMO/AAPL) provides clear separation by indicator category. Zero-division guards for ROC, NVI, PVI, VPT, and PPO are explicitly tested. CMF and MFI have strong numerical validation. A few gaps remain, primarily around EMV edge cases and MFI/CMF O(n) optimization equivalence testing.

**Overall Assessment**: **Good** -- 3 High-priority gaps, 4 Medium, 2 Low.

---

## 2. Zero-Division Edge Case Coverage

| Indicator | Guard in Source | Test Exists | Test Quality | Notes |
|-----------|----------------|-------------|-------------|-------|
| ROC | `iszero(prices[i-period]) ? 0.0` | YES (SISO L357-360) | **Good** | Tests `[0.0, 1.0, ...]` with `n=1`, verifies no Inf/NaN and result=0.0 |
| NVI | `iszero(closes[i-1]) ? results[i-1]` | YES (MISO L593-597) | **Good** | Tests `[0.0, ...]` close, verifies carry-forward to 1000.0 |
| PVI | `iszero(closes[i-1]) ? results[i-1]` | YES (MISO L650-654) | **Good** | Tests `[0.0, ...]` close, verifies carry-forward to 1000.0 |
| VPT | `iszero(closes[i-1]) ? 0.0` | YES (MISO L536-540) | **Good** | Tests `[0.0, ...]` close, verifies no Inf/NaN and VPT[2]=0.0 |
| PPO | `ifelse(iszero(slow_ema), 0.0, ...)` | YES (SIMO L166-170) | **Good** | Tests 5 leading zeros + normal data, verifies no Inf/NaN |
| CMF | `hl_range <= 0.0` guard | YES (MISO L454-459) | **Good** | Tests H==L case, verifies CLV=0 |
| CMF | `sum_vol == 0.0` guard | YES (MISO L461-466) | **Good** | Tests zero-volume, verifies CMF=0 |
| MFI | `neg_flow == 0.0` guard | YES (MISO L391-392) | **Good** | Tests all-positive flow => MFI=100 |
| MFI | `pos_flow == 0.0` guard | YES (MISO L365-367) | **Good** | Tests all-negative flow => MFI=0 |
| MFI | `neg==0 && pos==0` guard | PARTIAL | **Medium** | First-bar edge case implicitly tested, but no explicit zero-volume test |
| EMV | `hl_diff == 0.0` guard | NO | **Missing** | Source line 55: `if hl_diff == 0.0` not exercised |
| EMV | `box_ratio == 0.0` guard | NO | **Missing** | Source line 59: `if box_ratio == 0.0` not exercised |

---

## 3. MFI/CMF O(n) Optimization Coverage

The CMF and MFI implementations use O(n) sliding-window sums instead of recomputing sums each iteration. This is a correctness-critical optimization.

### CMF O(n) Sliding Window
- **Tested with**: Bull (CLV=1), Bear (CLV=-1), Midpoint (CLV=0), Flat (H==L), Zero-volume, and mixed numerical data
- **Window boundary test**: `n=2` with 3 bars tests window slide from [1,2] to [2,3] (MISO L475-479)
- **Gap**: No test with `n` significantly smaller than data length (e.g., n=3, data=20+) to stress-test the subtraction path `if i > n`

### MFI O(n) Sliding Window
- **Tested with**: Rising (all positive), Falling (all negative), Alternating, and manual 3-bar calculation
- **Window boundary test**: `n=2` with 3 bars (MISO L389-396) and `n=4` with 8 bars (MISO L378-382)
- **Gap**: Same as CMF -- no long-series test to validate accumulated floating-point drift in the sliding window

### Recommendation
Both indicators would benefit from a **numerical equivalence test**: compare O(n) sliding-window output against a naive O(n*k) reference implementation for a ~50-bar series. This would catch any floating-point accumulation issues.

---

## 4. AAPL Integration Test Tolerance Analysis

### Tolerance Levels Used
- Primary tolerance: `atol=1e-6` (used for all regression values)
- Structural checks: `atol=1e-10` (used for mathematical identities like Histogram = Line - Signal)

### Assessment
| Aspect | Verdict | Notes |
|--------|---------|-------|
| Not too tight | **OK** | `1e-6` is appropriate for IEEE-754 double arithmetic with real-world data |
| Not too loose | **OK** | `1e-6` would catch algorithmic errors (wrong formula, off-by-one) |
| Structural checks | **Excellent** | `1e-10` for exact identities is tight and correct |
| Manual verification | **Excellent** | SMA has `sma5[end] approx sum(closes[end-4:end])/5 atol=1e-10` -- gold standard |

### Range/Sanity Checks Present
- RSI: `[0, 100]`
- MFI: `[-1e-8, 100+1e-8]` (tiny fp tolerance)
- CMF: `[-1-1e-8, 1+1e-8]`
- WR: `[-100, 0]`
- Stoch K/D: `[0, 100]`
- ATR: `>= 0`
- CCI: `abs < 500`
- VWAP: within `[min(Low), max(High)]`
- Aroon: Up/Down `[0,100]`, Osc `[-100,100]`
- DMI: DI+ >= 0, DI- >= 0, ADX `[0,100]`
- Supertrend direction: `{1, -1}`
- ParabolicSAR direction: `{1, -1}`
- NVI/PVI: `> 0`
- SqueezeMomentum squeeze: `{0, 1}`

### Verdict: **Tolerances are well-calibrated.**

---

## 5. Trivially Always-True Tests

| Test | File:Line | Assessment |
|------|-----------|------------|
| `CCI: any(x>0) OR any(x<0) OR all(x==0)` | MISO L248 | **Trivially always true** -- this is a tautology (covers all possibilities). Not harmful but adds no value. |
| `CCI: r_rising[end] > 0.0 OR r_rising[end] approx 0.0` | MISO L254 | **Weak** -- the `OR` makes this very hard to fail. Should be just `> 0.0` for linear rising data. |
| Moving Averages: `abs.(ma .- closes) .< 100.0` | AAPL L563 | **Very loose** -- AAPL prices are ~145-220, so a MA 100 points away from price would be catastrophically wrong. Tighten to ~30. |

All other tests appear to test genuine properties and behaviors.

---

## 6. Regression Value Stability (AAPL CSV Risk)

### Risk Assessment
- `aapl.csv` was committed in the initial commit (`ed8c37d`) and has **never been modified since**.
- The AAPL test file uses a **date-filtered subset** (`2023-03-01 to 2024-06-30`), providing 335 rows.
- The CSV contains historical data up to 2024-10-30.
- Regression values are hardcoded Float64 constants computed from this specific data slice.

### Verdict
- **Low risk** of breakage from CSV updates -- the file is checked into git and rarely modified.
- **If the CSV were updated** (e.g., extended with new data), the date filter `subset(aapl_full, Date("2023-03-01"), Date("2024-06-30"))` ensures the test subset remains stable.
- **Potential risk**: If someone replaces the entire CSV with different data (e.g., different adjusted close values), all regression tests would break. This is acceptable and desirable behavior.

---

## 7. Test Isolation

### File Independence
Each test file correctly:
- Imports `using Test, Foxtail, TSFrames, CSV` independently
- Loads its own data (SISO uses `collect(1.0:50.0)`, MISO/MIMO use fixed arrays, AAPL loads CSV)
- Wraps everything in a single top-level `@testset`
- Does not depend on state from other test files

### Shared State Concerns
- MISO and MIMO both load `aapl.csv` and create `data_ts = aapl[end-100:end]` -- this is fine since Julia test files are `include()`-d independently and the data is read-only.
- No mutation of global state detected.
- No inter-file dependencies detected.

### Verdict: **Test isolation is well maintained.**

---

## 8. Gap Summary

### High Priority

| # | Gap | File/Function | Test Needed |
|---|-----|---------------|-------------|
| H1 | EMV `hl_diff == 0` not tested | EMV (MISO) | Test with data where `High == Low` on some bars. Verify raw_emv=0 and no Inf/NaN. |
| H2 | EMV `box_ratio == 0` not tested | EMV (MISO) | Test with `Volume=0` (box_ratio becomes 0). Verify raw_emv=0. |
| H3 | MFI `neg==0 && pos==0` not explicitly tested | MFI (MISO) | Test with constant TP (all bars equal price) and verify MFI=100 (current behavior) or document the convention. |

### Medium Priority

| # | Gap | File/Function | Test Needed |
|---|-----|---------------|-------------|
| M1 | CMF sliding-window O(n) equivalence | CMF (MISO) | Compare CMF output for n=5, 50-bar data against naive double-loop reference. |
| M2 | MFI sliding-window O(n) equivalence | MFI (MISO) | Compare MFI output for n=5, 50-bar data against naive double-loop reference. |
| M3 | CCI tautology test at MISO L248 | CCI (MISO) | Remove or replace with meaningful assertion. |
| M4 | MA tracking tolerance too loose at AAPL L563 | Moving Averages (AAPL) | Tighten `100.0` to `30.0` or better. |

### Low Priority

| # | Gap | File/Function | Test Needed |
|---|-----|---------------|-------------|
| L1 | CMF `hl_range <= 0.0` (negative range) | CMF (MISO) | Test with `Low > High` (malformed data). Currently guarded by `<=` but not tested with `<`. |
| L2 | No regression spot checks for MISO/MIMO unit tests | Multiple | MISO/MIMO have excellent formula-based tests but no regression anchors. Lower priority since AAPL file provides regression. |

---

## 9. Strengths

1. **Excellent numerical validation**: Hand-computed expected values in MISO/MIMO tests (e.g., MFI alternating, CMF mixed CLV, ParabolicSAR step-by-step)
2. **Structural invariant checks**: Histogram = Line - Signal, Upper >= Middle >= Lower, Oscillator = Up - Down
3. **Boundary testing**: First-bar behavior, warmup periods, and range bounds are consistently checked
4. **Zero-division guards well-tested**: 5 of 7 modified indicators have explicit zero-denominator tests
5. **Cross-reference validation**: KST tests replicate the full formula using ROC and SMA primitives
6. **TSFrame wrapper testing**: Every indicator tested for both Matrix and TSFrame input/output
7. **Input validation testing**: Wrong column counts and invalid parameters consistently tested with `@test_throws ArgumentError`
