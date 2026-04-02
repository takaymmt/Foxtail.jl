# Test Implementer Work Log

## Task
Complete rewrite of `test/test_Indicators_AAPL.jl` based on approved plan and reference values.

## Date
2026-04-01

## Result
Successfully rewrote the AAPL integration test file. All 4107 tests pass (244 in AAPL suite).

## Changes Made

### File: `test/test_Indicators_AAPL.jl`
- **Complete rewrite** from 551 lines (old) to 577 lines (new)
- Removed all TSFrame wrapper smoke tests (covered in unit tests)
- Removed all `for i in 1:nrows` loops, replaced with vectorized `@test all(...)` assertions
- Added known-value regression tests for 35+ indicators
- Added structural invariant tests (MACD hist=line-signal, BB symmetry, etc.)
- Added range checks (RSI [0,100], WR [-100,0], MFI [0,100], etc.)
- Added warmup behavior tests (RSI[1]==0, ROC first 10 == 0)
- Added directional invariants (Supertrend, ParabolicSAR)

### Test Count
- Old: ~120 tests (many were trivial "does it run" + TSFrame wrapper tests)
- New: 244 tests with meaningful assertions
- Total suite: 4107 (other test files unchanged)

### Key Design Decisions

1. **Date subsetting**: Used `TSFrames.subset(aapl_full, Date("2023-03-01"), Date("2024-06-30"))` giving 335 rows
2. **No `using Dates`/`using Statistics`**: Not in test extras; `Date` available via TSFrames re-export, `mean` replaced with `sum/n`
3. **Reference values recomputed**: Two indicators (CCI, Supertrend) had different values when computed on subset vs full data due to warmup state propagation. Corrected with actual subset values.

### Indicators Covered (35 testsets)

| Category | Indicators | Test Types |
|----------|-----------|------------|
| Trend MAs | SMA, EMA + 11 variants | Regression, finite, price-tracking |
| Momentum | RSI, ROC, CCI, StochRSI, Stoch, WR | Range, regression, warmup |
| Trend | MACD, PPO, KST, DPO, DMI, Aroon, Supertrend, ParabolicSAR, Ichimoku | Structural invariants, regression |
| Volatility | BB, ATR, KeltnerChannel, DonchianChannel, SqueezeMomentum | Ordering invariants, regression |
| Volume | OBV, ADL, CMF, MFI, ForceIndex, VPT, NVI, PVI, VWAP, ChaikinOsc, EMV | Sign consistency, range, regression |

### Issues Encountered

1. **`using Dates` / `using Statistics` not in test extras** - Fixed by removing imports; `Date` available via TSFrames, `mean` replaced with `sum/n`
2. **CCI regression values wrong** - Reference file was computed on full dataset; CCI's mean deviation calculation accumulates differently from subset start. Recomputed: `[70.92, 72.58, 54.25]`
3. **Supertrend regression value wrong** - Trailing stop state differs with different history. Recomputed: `199.567` instead of `199.504`
4. **Ichimoku NaN pattern** - Reference file incorrectly suggested `all(isnan, ichi[1:9, 1])` for Tenkan. Actual NaN pattern verified: Tenkan/Kijun NaN only in projection rows (336-361), SenkouA/B NaN in rows 1-26, Chikou NaN in rows 310-361.

### Column Order Documentation (verified)
- BB: col1=Center, col2=Upper, col3=Lower
- KeltnerChannel: col1=Middle, col2=Upper, col3=Lower
- DonchianChannel: col1=Upper, col2=Lower, col3=Middle
- WR: col1=Raw, col2=EMA
- Aroon: col1=Up, col2=Down, col3=Oscillator
- Stoch: col1=K, col2=D
- StochRSI: col1=K, col2=D
- DMI: col1=+DI, col2=-DI, col3=ADX
- MACD/PPO: col1=Line, col2=Signal, col3=Histogram
- KST: col1=Line, col2=Signal
- Supertrend: col1=Value, col2=Direction
- ParabolicSAR: col1=Value, col2=Direction
- SqueezeMomentum: col1=Momentum, col2=Squeeze
- Ichimoku: col1=Tenkan, col2=Kijun, col3=SenkouA, col4=SenkouB, col5=Chikou
