# Test Coverage Review: 17 Technical Indicators

**Date**: 2026-04-01
**Reviewer**: Test Reviewer (Opus subagent)
**Scope**: 17 new indicators + MinMaxQueue extensions
**Test Suite Result**: 3702/3702 PASS (14.4s)

---

## Executive Summary

Test quality is **strong overall**. All 17 indicators have dedicated test blocks with numerical validation, type checks, smoke tests against AAPL data, and directional correctness tests. The MinMaxQueue `get_max_idx`/`get_min_idx` methods are well tested. The main gaps are in **input validation coverage** (most indicators with `ArgumentError` throws lack corresponding test cases) and **edge case coverage** for division-by-zero and NaN-propagation scenarios.

**Overall Rating**: B+ (solid happy paths and numerics, but systematic gap in error-path testing)

---

## Coverage Matrix

| Indicator | Happy Path | Numerical | Error Cases | Edge Cases | TSFrame | Smoke (AAPL) |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|
| ROC | YES | YES (n=3, n=1) | NO | Startup period | YES | YES (via data_ts) |
| DPO | YES | YES (n=4) | NO | Startup, constant prices | YES | YES (via data_ts) |
| DonchianChannel | YES | YES (2 datasets) | NO | Linear data | YES | YES |
| KeltnerChannel | YES | YES (cross-ref EMA+ATR) | NO | Band ordering | YES | YES |
| Supertrend | YES | YES | NO | Direction validity, rising/falling | YES | YES |
| DMI/ADX | YES | YES (uptrend/downtrend) | NO | ADX bounds [0,100] | YES | YES |
| VWAP | YES | YES (3-bar manual) | NO | Constant prices, bounds | YES | YES |
| CCI | YES | YES (MAD calc at i=3) | NO | Constant TP (MAD=0), rising | YES | YES |
| PPO | YES | YES (cross-ref EMA) | NO | MACD sign consistency | YES | YES (via isfinite) |
| ForceIndex | YES | YES (raw force + EMA) | NO | Rising/falling/constant | YES | YES |
| MFI | YES | YES (manual MFR calc) | NO | All-rising=100, all-falling=0, alternating | YES | YES |
| CMF | YES | YES (mixed CLV) | NO | H==L, Volume==0, bullish/bearish | YES | YES |
| Aroon | YES | YES (multiple datasets) | **YES** (2 checks) | Rising/falling monotonic | YES | YES |
| VPT | YES | YES (5-bar manual) | NO | Constant price, rising/falling | YES | YES |
| NVI | YES | YES (4-bar manual) | NO | Volume increase=no update | YES | YES |
| PVI | YES | YES (4-bar manual) | NO | Volume decrease=no update | YES | YES |
| SqueezeMomentum | YES | YES (linreg direction) | **YES** (1 check) | Low-vol=ON, high-vol=OFF | YES | YES |
| ParabolicSAR | YES | YES (6-bar reversal) | **YES** (2 checks) | Alternating, direction flip | YES | YES |
| Ichimoku | YES | YES (extensive known data) | **YES** (3 checks) | NaN regions, future rows, Chikou | YES | YES |
| KST | YES | PARTIAL (sign/convergence) | NO | Finite values | YES | YES (via data_ts) |
| EMV | YES | PARTIAL (first bar, const) | NO | Distance moved=0 | YES | YES |
| MinMaxQueue | YES | YES (stress test) | **YES** (empty queue) | Index accessors, monotonicity | N/A | N/A |

---

## Detailed Findings

### 1. Input Validation Tests (Error Cases)

**Priority: Medium**

Many indicators have `ArgumentError` throws in source code that are **not tested**:

| Indicator | Validation in Source | Test Coverage |
|-----------|---------------------|---------------|
| ROC | period<1, len<period+1 | **MISSING** |
| DonchianChannel | wrong cols, period<1, len<period | **MISSING** |
| KeltnerChannel | wrong cols, period<1 | **MISSING** |
| Supertrend | wrong cols, period<1, mult<=0 | **MISSING** |
| DMI | wrong cols, period<1 | **MISSING** |
| VWAP | wrong cols (4 required) | **MISSING** |
| CCI | wrong cols, period<1 | **MISSING** |
| PPO | len <= slow period | **MISSING** |
| ForceIndex | wrong cols (2 required) | **MISSING** |
| MFI | wrong cols, period<1 | **MISSING** |
| CMF | wrong cols, period<1 | **MISSING** |
| VPT | wrong cols (2 required) | **MISSING** |
| NVI | wrong cols (2 required) | **MISSING** |
| PVI | wrong cols (2 required) | **MISSING** |
| EMV | (no explicit validation) | N/A |
| KST | (no explicit validation) | N/A |
| DPO | (no explicit validation) | N/A |
| Aroon | wrong cols, period<1, empty | **COVERED** (2/3) |
| SqueezeMomentum | wrong cols, period<2 | **PARTIAL** (1/2) |
| ParabolicSAR | wrong cols, af_start, af_step, af_max | **PARTIAL** (2/4) |
| Ichimoku | wrong cols, period<1, displacement<1 | **COVERED** (3/3) |

**Indicators with zero input validation tests**: ROC, DonchianChannel, KeltnerChannel, Supertrend, DMI, VWAP, CCI, PPO, ForceIndex, MFI, CMF, VPT, NVI, PVI (14 indicators).

**Recommendation**: Add `@test_throws ArgumentError` for each throw path. This is systematic and can be added in batch.

---

### 2. Edge Case Gaps

**Priority: Medium-High**

#### 2a. Division by Zero in VPT and NVI/PVI

VPT computes `(closes[i] - closes[i-1]) / closes[i-1]`. If `closes[i-1] == 0.0`, this produces `Inf` or `NaN`. No test covers this. Same pattern exists in NVI and PVI.

**Affected**: VPT, NVI, PVI
**Test needed**: Input with a zero close price to verify behavior (crash, NaN propagation, or graceful handling).

#### 2b. ROC Division by Zero

`ROC` computes `(prices[i] - prices[i-period]) / prices[i-period] * 100.0`. If `prices[i-period] == 0.0`, this produces `Inf`. No test covers this.

**Affected**: ROC
**Test needed**: Input with zero price value at lookback position.

#### 2c. NaN Input Propagation

No indicator test uses NaN input values. While Julia naturally propagates NaN through arithmetic, testing confirms the library does not silently replace NaN with 0 or crash.

**Affected**: All 17 indicators
**Priority**: Low (Julia's NaN propagation is reliable, but a single cross-cutting test would be reassuring).

#### 2d. Single-Element and Minimum-Length Input

Most indicators are tested with 5-10+ element arrays. Minimum-length edge cases (e.g., exactly `n+1` elements for ROC) are not systematically tested. Some indicators like Ichimoku have length validation but the boundary (exact minimum) is not tested.

**Priority**: Low (most indicators degrade gracefully via the startup period convention).

---

### 3. Numerical Validation Depth

**Priority: Low**

#### 3a. KST: Weak Numerical Validation

KST tests only check:
- Shape and sign of output
- Signal convergence toward line
- Finiteness

No hand-computed intermediate values are verified. Given KST is a composition of ROC + SMA operations (which are individually well-tested), this is acceptable but not ideal.

**Recommendation**: Add a cross-reference test: compute `1*SMA(ROC(p,r1),s1) + 2*SMA(ROC(p,r2),s2) + ...` manually and compare with `KST(p)[:,1]`.

#### 3b. EMV: Minimal Numerical Validation

EMV tests verify:
- First bar = 0
- Constant H/L = 0
- Finiteness

No hand-computed value is checked for a non-trivial bar. The formula involves `distance_moved / box_ratio` with the `1e8` scaling factor, which would benefit from at least one explicit numerical check.

---

### 4. Structural Quality

**Priority: Informational**

#### Strengths

1. **Consistent test structure**: Every indicator has type checks (Vector, TSFrame), column naming checks, AAPL smoke tests, and at least one numerical validation block.
2. **Cross-reference validation**: PPO tests verify against EMA components; KeltnerChannel tests verify against EMA+ATR; ForceIndex verifies raw force + EMA composition. This is excellent practice.
3. **Directional tests**: Most indicators verify behavior under monotonic rising/falling/constant input. This catches sign errors and formula inversions.
4. **MinMaxQueue index accessors**: Well covered with 6 sub-scenarios including empty queue, single element, different high/low, and sliding window.
5. **Ichimoku**: Exemplary test coverage with NaN region checks, future date generation, displacement customization, and extensive known-data validation.

#### Weaknesses

1. **No shared edge-case suite**: Each indicator re-implements its own test data. A shared set of edge-case inputs (empty, single, constant, NaN) would improve consistency.
2. **No parametric/property-based tests**: All tests are example-based. Property-based tests (e.g., "CMF always in [-1,1]") are present for some but not all bounded indicators.
3. **Random data without seed**: `vec2 = rand(100,2) * 100` in MISO/MIMO sections uses unseeded random data. While unlikely to cause flaky tests, a fixed seed would improve reproducibility.

---

## Summary of Gaps by Priority

### High Priority
(None -- no critical gaps; all indicators have meaningful coverage)

### Medium-High Priority
| # | Gap | Indicators Affected |
|---|-----|-------------------|
| 1 | Division-by-zero close price not tested | VPT, NVI, PVI, ROC |

### Medium Priority
| # | Gap | Indicators Affected |
|---|-----|-------------------|
| 2 | Missing input validation tests (@test_throws) | 14 of 21 indicators |
| 3 | SqueezeMomentum: period<2 validation not tested | SqueezeMomentum |
| 4 | ParabolicSAR: af_step and af_max validation not tested | ParabolicSAR |

### Low Priority
| # | Gap | Indicators Affected |
|---|-----|-------------------|
| 5 | KST numerical cross-reference test | KST |
| 6 | EMV non-trivial numerical value check | EMV |
| 7 | NaN input propagation test | All 17 |
| 8 | Minimum-length input boundary test | All with len validation |
| 9 | Random data reproducibility (fixed seed) | MISO/MIMO sections |

---

## Test Count Breakdown (Estimated)

From the 3702 total tests, the indicator test file contributes approximately:
- Pre-existing indicators (SMA, EMA, BB, MACD, etc.): ~700 tests
- New 17 indicators: ~800+ tests
- MinMaxQueue: ~200+ tests (including stress test with 1100 iterations)

The new indicators represent a substantial portion of the test suite with good depth.
