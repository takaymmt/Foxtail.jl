# Batch 6 Review Fixes

> Date: 2026-04-02
> Status: Complete
> Test result: 4,307 pass (0 fail)

## Fix 1: ConnorsRSI length validation (Security-02)

**File:** `src/indicators/ConnorsRSI.jl` (lines 48-52)

**Change:** Replaced `len > 1` with a proper minimum length check: `min_len = max(n_rsi, n_streak) + 2`. This ensures the input is long enough for RSI computation on both the price and streak components. Kept existing `n_rsi < 1`, `n_streak < 1`, `n_pctrank < 1` checks.

## Fix 2: ConnorsRSI test -- add isnan check (Test-M01)

**File:** `test/test_Indicators_SISO.jl` (line 419)

**Change:** Added `@test !any(isnan, result_vec)` after the existing `!any(isinf, result_vec)` test in the ConnorsRSI testset.

## Fix 3: Vortex test -- add isfinite check (Test Low)

**File:** `test/test_Indicators_MIMO.jl` (line 769)

**Change:** Added `@test all(isfinite, vx)` after the existing `!any(isinf, vx)` check in the Vortex testset.

## Fix 4: MassIndex rolling sum -- O(1) refactor (Quality-M01)

**File:** `src/indicators/MassIndex.jl` (lines 86-95)

**Change:** Replaced O(n) per-bar `sum(buf)` loop with O(1) running sum pattern matching Vortex.jl. Uses `isfull(cb)` / `first(cb)` to subtract oldest before push, then adds new value.

## Fix 5: UltimateOsc rolling sums -- O(1) refactor (Quality-M02)

**File:** `src/indicators/UltimateOsc.jl` (lines 83-132)

**Change:** Replaced 6 O(n) per-bar buffer iteration loops with 6 O(1) running sums. Each of the 6 CircBuff pairs (bp_fast, bp_medium, bp_slow, tr_fast, tr_medium, tr_slow) now maintains a running sum using the same `isfull` / `first` pattern as Vortex.jl.

## Fix 6: AAPL regression tests for 5 new indicators (Test Low)

**File:** `test/test_Indicators_AAPL.jl`

**Changes:**
- Added `opens` and `hlco` data setup variables (line 20-21)
- Added 5 new testsets: MassIndex, UltimateOsc, Vortex, ConnorsRSI, PivotPoints
- Each testset checks: type/size, no NaN, no Inf, 3-4 regression values at indices 100/200/300/end
- PivotPoints additionally checks structural ordering: S3 < S2 < S1 < P < R1 < R2 < R3
- Total new tests: ~40

## Fix 7: Design doc Woodie typo

**File:** `.claude/docs/DESIGN-remaining-indicators.md` (line 366)

**Change:** Fixed `P = (H + L + 2C) / 4` to `P = (H + L + 2*O) / 4` in the Woodie method section. The implementation was already correct; only the design doc had the typo.

## Verification

```
Test Summary: | Pass  Total   Time
Foxtail.jl    | 4307   4307  12.0s
```

All 4,307 tests pass. Previous count was 4,115 -- net gain of 192 tests (from batch 6 indicators + these review fixes).
