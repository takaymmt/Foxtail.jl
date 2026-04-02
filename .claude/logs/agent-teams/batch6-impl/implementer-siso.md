# Work Log: Implementer-SISO

## Summary
Implemented ConnorsRSI indicator with two internal helpers (`_streak`, `_percentile_rank`) and comprehensive tests. All 260 SISO tests pass (including 52 new ConnorsRSI tests).

## Tasks Completed
- [x] ConnorsRSI: Composite oscillator combining RSI(price), RSI(streak), PercentRank(ROC1) averaged to [0,100] range
- [x] `_streak` helper: Consecutive up/down counter with equal-close reset to 0
- [x] `_percentile_rank` helper: Rolling percentile rank using strictly-less-than comparison, excluding current value
- [x] Tests: Type checks, column name, range validation, isolated helper tests, argument error tests

## Files Modified
- `src/indicators/ConnorsRSI.jl` (NEW) -- Core function + 2 helpers + `@prep_siso` macro call
- `test/test_Indicators_SISO.jl` (APPEND) -- 11 test cases in ConnorsRSI testset

## Key Decisions
1. **`_percentile_rank` window**: Uses `data[max(1, i-lookback):i-1]` (excludes current value), with `count / length(window) * 100` -- matches Connors' original spec and task test expectations
2. **Validation**: `length(prices) > 1` (delegating deeper validation to RSI/ROC which check `length > period + 1`)
3. **Column name**: Just `ConnorsRSI` (no `_n` suffix since no bare `n` parameter) -- handled automatically by `@prep_siso` macro
4. **Helper visibility**: Functions are module-internal (`_streak`, `_percentile_rank`) but accessible via `Foxtail._streak` for testing

## Issues Encountered
- 2 pre-existing test errors in `Indicators MIMO` (PivotPoints, Vortex) -- unrelated to this change. All 260 SISO tests pass cleanly.
