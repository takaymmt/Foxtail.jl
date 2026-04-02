# Test Coverage Review: AnchoredVWAP

**Date**: 2026-04-02
**Reviewer**: Test Reviewer (Opus subagent)
**Test Suite Result**: 4,570 tests PASS (including AnchoredVWAP)

---

## Implementation Summary

- **File**: `src/indicators/AnchoredVWAP.jl` (114 lines)
- **Functions**: 3
  - `AnchoredVWAP(data::Matrix{Float64}; anchor::Int=1)` -- raw computation
  - `_anchored_vwap_resolve(ts, anchor)` -- Int/Date anchor resolution
  - `AnchoredVWAP(ts::TSFrame; anchor, fields)` -- TSFrame wrapper

## Coverage Checklist

| Category | Test Case | Status | Location |
|----------|-----------|--------|----------|
| **Happy path** | Basic type check (Vector{Float64}) | PASS | MISO:227 |
| | TSFrame type check | PASS | MISO:228-230 |
| | Column name = "AnchoredVWAP" | PASS | MISO:230 |
| | anchor=1 parity with VWAP | PASS | MISO:233 |
| | Pre-anchor NaN, post-anchor finite | PASS | MISO:236-238 |
| | Hand-calculated numerical accuracy (5 rows, anchor=3) | PASS | MISO:242-252 |
| | Verify anchor=3 matches VWAP on sliced data | PASS | MISO:254-256 |
| **Boundary** | anchor=1 (first row) | PASS | MISO:227,233 |
| | anchor=n (last row) | PASS | MISO:260-264 |
| | Last-row result = typical price | PASS | MISO:263-264 |
| **Error cases** | anchor=0 | PASS | MISO:274 |
| | anchor > nrow | PASS | MISO:275 |
| | Wrong column count (3 cols) | PASS | MISO:276 |
| | Empty matrix | PASS | MISO:277 |
| | Date not found in TSFrame | PASS | MISO:278 |
| **TSFrame** | Int anchor | PASS | MISO:269 |
| | Date anchor | PASS | MISO:270 |
| | Int vs Date equivalence (isequal) | PASS | MISO:271 |
| **AAPL integration** | Output length matches input | PASS | AAPL:357 |
| | TSFrame index matches input | PASS | AAPL:361 |
| | anchor=1 matches VWAP exactly | PASS | AAPL:364-365 |
| | Mid-range anchor: pre-NaN, post-finite | PASS | AAPL:368-371 |
| | Date vs Int equivalence on real data | PASS | AAPL:374-377 |
| | Post-anchor values within [min(Low), max(High)] | PASS | AAPL:379-384 |

## Gaps Found

### Gap 1: Volume = 0 edge case
- **Priority**: Medium
- **Description**: The implementation returns `0.0` when cumulative volume is zero (line 63). This is a deliberate design choice but is not tested. The VWAP test doesn't test this either. A test with all-zero volumes (or zero volume at anchor point) would document this behavior.
- **Suggested test**:
  ```julia
  # Volume=0 at all rows: returns 0.0 (not NaN)
  zero_vol = Float64[10 8 9 0; 12 10 11 0; 14 12 13 0]
  r_zero = AnchoredVWAP(zero_vol; anchor=1)
  @test all(r_zero .== 0.0)
  ```

### Gap 2: Constant prices edge case
- **Priority**: Low
- **Description**: The VWAP test has a constant-price test (`const_data`), but AnchoredVWAP does not. This is a minor gap since the computation is identical, but for completeness:
  ```julia
  const_data = Float64[10 10 10 500; 10 10 10 500; 10 10 10 500]
  r_const = AnchoredVWAP(const_data; anchor=1)
  @test all(r_const .≈ 10.0)
  ```

### Gap 3: Negative anchor value
- **Priority**: Low
- **Description**: `anchor=-1` is implicitly covered by `anchor=0` (both fail `anchor < 1`), but an explicit negative test would improve clarity. Very low priority since the branch is already exercised.

### Gap 4: `_anchored_vwap_resolve` TSFrame integer out-of-range
- **Priority**: Low
- **Description**: Lines 84-87 validate integer anchors in the TSFrame wrapper. Currently, the tests for anchor=0 and anchor>nrow go through the raw Matrix function (lines 274-275), not through the TSFrame wrapper. The TSFrame wrapper's integer validation is technically unreachable in the current test suite for out-of-range integers.
- **Suggested test**:
  ```julia
  @test_throws ArgumentError AnchoredVWAP(data_ts; anchor=0)
  @test_throws ArgumentError AnchoredVWAP(data_ts; anchor=nrow(data_ts)+1)
  ```

### Gap 5: Single-row data
- **Priority**: Low
- **Description**: A 1-row matrix with `anchor=1` is not tested. This is the minimal valid input. The result should equal the typical price.
  ```julia
  single = Float64[10 8 9 1000]
  r_single = AnchoredVWAP(single; anchor=1)
  @test length(r_single) == 1
  @test r_single[1] == 9.0
  ```

## Quality Assessment

### Strengths
1. **Hand-calculated numerical validation** -- The 5-row test with explicit TP/cumulative calculations (MISO:242-252) is excellent and catches any formula bugs.
2. **VWAP parity test** -- Testing `AnchoredVWAP(anchor=1) == VWAP()` is a strong cross-validation.
3. **Slice equivalence** -- Verifying `r[3:5] == VWAP(data[3:5,:])` (MISO:254-256) validates the anchor offset logic.
4. **Comprehensive error coverage** -- All 5 error branches are tested.
5. **AAPL integration with range bounds** -- The loop checking `min_low <= avwap[i] <= max_high` (AAPL:379-384) is a strong invariant test on real data.
6. **Int/Date equivalence** tested in both MISO and AAPL contexts.

### Minor Observations
- No `@test !any(isinf, ...)` test (VWAP has this). Not critical since `isfinite` checks in MISO:238 cover both NaN and Inf for post-anchor.
- The `_anchored_vwap_resolve` helper is a private function, so indirect testing through the public API is acceptable.

## Overall Verdict

**Coverage: GOOD** -- The test suite covers all critical paths with strong numerical validation and real-data integration. The identified gaps are all Medium or Low priority. The most actionable gap is Gap 1 (volume=0 behavior), which documents an important edge case in the implementation.

| Metric | Rating |
|--------|--------|
| Happy path | Excellent |
| Boundary values | Good |
| Error cases | Excellent |
| Edge cases | Adequate (volume=0, constant-price gaps) |
| Numerical accuracy | Excellent |
| Integration (AAPL) | Excellent |
| Overall | Good |
