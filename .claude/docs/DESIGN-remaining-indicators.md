# Design: Remaining 5 Indicators

> Date: 2026-04-02
> Status: Draft
> Indicators: Pivot Points, Connors RSI, Vortex Indicator, Ultimate Oscillator, Mass Index

---

## Implementation Order

| Order | Indicator | Macro | Rationale |
|-------|-----------|-------|-----------|
| 1 | Mass Index | `@prep_miso` | Simplest; no dependencies on new helpers |
| 2 | Vortex Indicator | `@prep_mimo` | Simple; reuses TR only |
| 3 | Ultimate Oscillator | `@prep_miso` | Moderate; uses TR, simple multi-period logic |
| 4 | Connors RSI | `@prep_siso` | Requires 2 new internal helpers (streak, percentile_rank) |
| 5 | Pivot Points | `@prep_mimo` | Most complex; method dispatch, 4-column input, 7 outputs |

Rationale: Start with the indicators that have zero new helper dependencies, then add composite indicators that need helpers, and finish with the multi-method Pivot Points which requires the most design decisions.

---

## Design Decision #1: Pivot Points DM Method

**Decision: Return NaN for unused columns (R2/R3/S2/S3) when `method=:DM`.**

Rationale:
- Consistent output shape across all methods (always 7 columns) simplifies downstream code.
- TSFrame column names remain stable regardless of method -- users always get `PivotPoints_Pivot`, `PivotPoints_R1`, etc.
- NaN is the standard "not applicable" signal in Julia numerical code. The codebase only avoids NaN for warmup (uses 0.0), but "structurally absent" is a different semantic.
- Alternative (separate functions) would require either manual wrappers bypassing the macro or two differently-named indicators -- both violate the one-indicator-per-file convention.
- Users can easily filter NaN columns if they only want DeMark levels.

**Exception considered:** Using 0.0 instead of NaN. Rejected because 0.0 is a valid pivot level for some instruments (e.g., rates), and NaN clearly communicates "this column is not computed for this method."

## Design Decision #2: Connors RSI Helpers

**Decision: Internal (non-exported) helper functions defined in the same file.**

The two helpers needed:
1. `_streak(prices::Vector{Float64}) -> Vector{Float64}` -- consecutive up/down streak counter
2. `_percentile_rank(data::Vector{Float64}, lookback::Int) -> Vector{Float64}` -- rolling percentile rank

Rationale:
- These are specific to Connors RSI and unlikely to be reused by other indicators.
- Keeping them in the same file follows the single-file-per-indicator pattern.
- The underscore prefix signals internal/private status.
- If future indicators need percentile rank, it can be promoted to a shared utility in `tools/` at that time (YAGNI).

Both helpers return `Vector{Float64}` of the same length as input, with 0.0 for warmup positions.

## Design Decision #3: Warmup Convention

**Decision: Follow the existing codebase convention of 0.0 for warmup periods.**

All 5 indicators will use 0.0 (not NaN) for positions where insufficient data exists. This is consistent with RSI, ROC, EMA, ATR, DMI, and all other existing indicators.

The only exception is Pivot Points DM method's structurally absent columns (R2/R3/S2/S3), which use NaN as discussed in Decision #1.

---

## 1. Mass Index

### Overview
Detects trend reversals by measuring the narrowing and widening of the range between high and low prices. Uses a ratio of double-EMA to single-EMA of the high-low spread.

### Macro & Signature
```julia
@prep_miso MassIndex [High, Low] n=25 ema_period=9
```

### Core Function
```julia
@inline Base.@propagate_inbounds function MassIndex(
    prices::Matrix{Float64};
    n::Int=25,
    ema_period::Int=9
) -> Vector{Float64}
```

### Parameters
- `prices`: Matrix with 2 columns `[High, Low]`
- `n`: Summation period (default: 25) -- number of single EMA / double EMA ratios to sum
- `ema_period`: EMA smoothing period for the range (default: 9)

### Algorithm
1. Validate: 2 columns, `n >= 1`, `ema_period >= 1`
2. `range = highs - lows` (element-wise)
3. `single_ema = EMA(range; n=ema_period)`
4. `double_ema = EMA(single_ema; n=ema_period)`
5. `ratio[i] = single_ema[i] / double_ema[i]` (guard division by zero -> 0.0)
6. `mass_index[i] = sum(ratio[max(1, i-n+1):i])` -- rolling sum using CircBuff

### Building Blocks Reused
- `EMA(data::Vector; n)` -- called twice (single + double EMA)
- `CircBuff{Float64}(n)` -- for efficient rolling sum

### Output
- Single column: `MassIndex_25` (via `_n` suffix convention)

### Warmup
- First `ema_period` values: EMA is still warming up, ratio may be imprecise. Mass index begins meaningful values after `n + ema_period` bars.
- Convention: 0.0 for initial bars (inherited from EMA warmup behavior -- EMA uses data[1] as seed, so values are technically computed from bar 1).

### Test Notes
- Range: typically 20-30 for trending; "reversal bulge" = crosses above 27 then back below 26.5
- Input validation: wrong column count, n=0, ema_period=0

---

## 2. Vortex Indicator

### Overview
Identifies trend direction and strength using the relationship between true range and positive/negative trend movement. Captures upward and downward price spiral patterns.

### Macro & Signature
```julia
@prep_mimo Vortex [High, Low, Close] [VIPlus, VIMinus] n=14
```

### Core Function
```julia
@inline Base.@propagate_inbounds function Vortex(
    prices::Matrix{Float64};
    n::Int=14
) -> Matrix{Float64}
```

### Parameters
- `prices`: Matrix with 3 columns `[High, Low, Close]`
- `n`: Lookback period for summing VM and TR (default: 14)

### Algorithm
1. Validate: 3 columns, `n >= 1`
2. For each bar `i >= 2`:
   - `vm_plus[i] = abs(highs[i] - lows[i-1])`
   - `vm_minus[i] = abs(lows[i] - highs[i-1])`
3. `tr_vals = TR(prices)` -- reuse existing TR function
4. Rolling sums over `n` periods (using CircBuff for each):
   - `sum_vm_plus = sum(vm_plus[i-n+1:i])`
   - `sum_vm_minus = sum(vm_minus[i-n+1:i])`
   - `sum_tr = sum(tr_vals[i-n+1:i])`
5. `vi_plus[i] = sum_vm_plus / sum_tr` (guard div-by-zero -> 0.0)
6. `vi_minus[i] = sum_vm_minus / sum_tr` (guard div-by-zero -> 0.0)

### Building Blocks Reused
- `TR(prices::Matrix)` -- True Range
- `CircBuff{Float64}(n)` -- 3 buffers for rolling sums

### Output
- Column 1: VI+ (Positive Vortex Indicator), typically oscillates around 1.0
- Column 2: VI- (Negative Vortex Indicator), typically oscillates around 1.0
- TSFrame names: `Vortex_VIPlus`, `Vortex_VIMinus`

### Warmup
- Bar 1: vm_plus and vm_minus are 0.0 (no previous bar)
- Bars 1 to n-1: partial window sums (values are computed but may be less meaningful)
- Convention: 0.0 via zeros() initialization for early bars

### Test Notes
- VI+ > VI-: uptrend; VI- > VI+: downtrend
- VI+ crossing above VI-: bullish signal
- Values typically range from 0.5 to 2.0
- Input validation: wrong column count, n=0

---

## 3. Ultimate Oscillator

### Overview
Multi-timeframe momentum oscillator that combines buying pressure over three different periods to reduce false signals. Created by Larry Williams (1976).

### Macro & Signature
```julia
@prep_miso UltimateOsc [High, Low, Close] fast=7 medium=14 slow=28
```

Note: No `n` parameter -- uses `fast`, `medium`, `slow` instead. Column name will be just `UltimateOsc` (no `_n` suffix per macro convention).

### Core Function
```julia
@inline Base.@propagate_inbounds function UltimateOsc(
    prices::Matrix{Float64};
    fast::Int=7,
    medium::Int=14,
    slow::Int=28
) -> Vector{Float64}
```

### Parameters
- `prices`: Matrix with 3 columns `[High, Low, Close]`
- `fast`: Short period (default: 7)
- `medium`: Medium period (default: 14)
- `slow`: Long period (default: 28)

### Algorithm
1. Validate: 3 columns, all periods >= 1
2. For each bar `i >= 2`:
   - `true_low = min(lows[i], closes[i-1])`
   - `bp[i] = closes[i] - true_low` (Buying Pressure)
3. `tr_vals = TR(prices)` -- reuse existing TR
4. Rolling sums over each period (3 CircBuffs for BP, 3 for TR):
   - `avg_fast = sum_bp_fast / sum_tr_fast`
   - `avg_medium = sum_bp_medium / sum_tr_medium`
   - `avg_slow = sum_bp_slow / sum_tr_slow`
5. `uo[i] = 100.0 * (4.0 * avg_fast + 2.0 * avg_medium + 1.0 * avg_slow) / 7.0`

### Building Blocks Reused
- `TR(prices::Matrix)` -- True Range
- `CircBuff{Float64}(period)` -- 6 buffers (3 periods x 2: bp + tr)

### Output
- Single column: `UltimateOsc` (no `_n` suffix since parameter is not named `n`)

### Warmup
- Bar 1: bp is 0.0 (no previous close), tr is high-low
- Bars 1 to slow-1: partial windows (using partial sums available in CircBuff)
- Convention: 0.0 for bar 1; partial computations for bars 2 through slow

### Test Notes
- Range: [0, 100]
- Overbought > 70, Oversold < 30
- Guard division by zero when sum_tr is 0.0
- Input validation: wrong column count, any period = 0

---

## 4. Connors RSI

### Overview
Composite momentum oscillator combining three components: short-term RSI, streak RSI, and percentile rank of rate of change. Created by Larry Connors.

### Macro & Signature
```julia
@prep_siso ConnorsRSI n_rsi=3 n_streak=2 n_pctrank=100
```

Note: No `n` parameter -- uses `n_rsi`, `n_streak`, `n_pctrank`. Column name will be just `ConnorsRSI`.

### Core Function
```julia
@inline Base.@propagate_inbounds function ConnorsRSI(
    prices::Vector{Float64};
    n_rsi::Int=3,
    n_streak::Int=2,
    n_pctrank::Int=100
) -> Vector{Float64}
```

### Parameters
- `prices`: Close price vector
- `n_rsi`: RSI period for the price RSI component (default: 3)
- `n_streak`: RSI period applied to the streak values (default: 2)
- `n_pctrank`: Lookback for percentile rank of 1-period ROC (default: 100)

### Algorithm
1. Validate: `length(prices) > max(n_rsi, n_streak) + 1`, all periods >= 1
2. **Component 1: RSI of prices**
   - `rsi_price = RSI(prices; n=n_rsi)` -- reuse existing RSI
3. **Component 2: Streak RSI**
   - `streaks = _streak(prices)` -- consecutive up/down counter
   - `rsi_streak = RSI(streaks; n=n_streak)` -- RSI applied to streak values
4. **Component 3: Percentile Rank of ROC(1)**
   - `roc1 = ROC(prices; n=1)` -- reuse existing ROC
   - `pct_rank = _percentile_rank(roc1, n_pctrank)` -- rolling percentile rank
5. `crsi[i] = (rsi_price[i] + rsi_streak[i] + pct_rank[i]) / 3.0`

### Helper Functions (Internal)

#### `_streak(prices::Vector{Float64}) -> Vector{Float64}`
```
streak[1] = 0.0
For i >= 2:
  if prices[i] > prices[i-1]:  streak[i] = max(streak[i-1], 0) + 1
  if prices[i] < prices[i-1]:  streak[i] = min(streak[i-1], 0) - 1
  if prices[i] == prices[i-1]: streak[i] = 0
```
Returns integer-valued Float64 vector (e.g., -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0).

#### `_percentile_rank(data::Vector{Float64}, lookback::Int) -> Vector{Float64}`
```
For i >= 2 (need at least 2 values to rank):
  window = data[max(1, i-lookback+1):i]
  count = number of values in window[1:end-1] that are < data[i]
  pct_rank[i] = count / (length(window) - 1) * 100.0
```
Returns values in [0, 100]. First value is 0.0.

### Building Blocks Reused
- `RSI(data::Vector; n, ma_type)` -- called twice (price RSI + streak RSI)
- `ROC(data::Vector; n)` -- with n=1 for single-period rate of change

### Output
- Single column: `ConnorsRSI`

### Warmup
- The effective warmup is `max(n_rsi + 1, n_streak + 1, 2)` bars before values are meaningful.
- Warmup is inherited from the component functions (RSI returns 0.0 for bar 1, ROC returns 0.0 for bars 1..n).

### Test Notes
- Range: [0, 100]
- Overbought > 90, Oversold < 10
- Verify each component independently, then verify the composite
- Streak helper: test with known up/down/flat sequences
- Input validation: price series too short, any period = 0

---

## 5. Pivot Points

### Overview
Support and resistance levels calculated from the previous period's high, low, close (and optionally open). Multiple calculation methods exist: Classic, Fibonacci, Woodie, Camarilla, DeMark.

### Macro & Signature
```julia
@prep_mimo PivotPoints [High, Low, Close, Open] [Pivot, R1, R2, R3, S1, S2, S3] method=Classic
```

Note: 4-column input includes Open (first time in the codebase). The `method` parameter is a Symbol.

### Core Function
```julia
@inline Base.@propagate_inbounds function PivotPoints(
    prices::Matrix{Float64};
    method::Symbol=:Classic
) -> Matrix{Float64}
```

### Parameters
- `prices`: Matrix with 4 columns `[High, Low, Close, Open]`
- `method`: Calculation method (default: `:Classic`)
  - `:Classic` -- Standard floor trader pivots
  - `:Fibonacci` -- Fibonacci retracement levels from pivot
  - `:Woodie` -- Woodie's method (more weight on close)
  - `:Camarilla` -- Camarilla equation
  - `:DeMark` -- DeMark method (uses open, conditional formula)

### Algorithm

All methods compute per-bar levels from `[H, L, C, O]` of the **current** bar (same-bar calculation). Users are expected to pass the appropriate periodicity (e.g., daily data for daily pivots). The indicator does NOT shift data forward -- that is the user's responsibility.

#### Classic Method
```
P  = (H + L + C) / 3
R1 = 2P - L
S1 = 2P - H
R2 = P + (H - L)
S2 = P - (H - L)
R3 = H + 2(P - L)
S3 = L - 2(H - P)
```

#### Fibonacci Method
```
P  = (H + L + C) / 3
R1 = P + 0.382 * (H - L)
S1 = P - 0.382 * (H - L)
R2 = P + 0.618 * (H - L)
S2 = P - 0.618 * (H - L)
R3 = P + 1.000 * (H - L)
S3 = P - 1.000 * (H - L)
```

#### Woodie Method
```
P  = (H + L + 2*O) / 4
R1 = 2P - L
S1 = 2P - H
R2 = P + (H - L)
S2 = P - (H - L)
R3 = H + 2(P - L)
S3 = L - 2(H - P)
```

#### Camarilla Method
```
P  = (H + L + C) / 3
R1 = C + 1.1 * (H - L) / 12
S1 = C - 1.1 * (H - L) / 12
R2 = C + 1.1 * (H - L) / 6
S2 = C - 1.1 * (H - L) / 6
R3 = C + 1.1 * (H - L) / 4
S3 = C - 1.1 * (H - L) / 4
```

#### DeMark Method
```
if C < O:   X = H + 2L + C
if C > O:   X = 2H + L + C
if C == O:  X = H + L + 2C

P  = X / 4
R1 = X / 2 - L
S1 = X / 2 - H
R2 = NaN  (not defined for DeMark)
S2 = NaN
R3 = NaN
S3 = NaN
```

### Implementation Structure
```julia
function PivotPoints(prices::Matrix{Float64}; method::Symbol=:Classic)
    # validate 4 columns, valid method symbol
    len = size(prices, 1)
    result = zeros(len, 7)  # or fill with NaN for DeMark

    if method == :Classic
        _pivot_classic!(result, highs, lows, closes)
    elseif method == :Fibonacci
        _pivot_fibonacci!(result, highs, lows, closes)
    elseif method == :Woodie
        _pivot_woodie!(result, highs, lows, closes)
    elseif method == :Camarilla
        _pivot_camarilla!(result, highs, lows, closes)
    elseif method == :DeMark
        _pivot_demark!(result, highs, lows, closes, opens)
    else
        throw(ArgumentError("Unknown method: $method. Valid: :Classic, :Fibonacci, :Woodie, :Camarilla, :DeMark"))
    end

    return result
end
```

Each `_pivot_*!` is a mutating helper that fills the `result` matrix in-place. This keeps the main function clean and each method's formula self-contained.

### Building Blocks Reused
- None -- pure arithmetic, no MA or TR dependencies

### Output
- 7 columns: `[Pivot, R1, R2, R3, S1, S2, S3]`
- TSFrame names: `PivotPoints_Pivot`, `PivotPoints_R1`, `PivotPoints_R2`, `PivotPoints_R3`, `PivotPoints_S1`, `PivotPoints_S2`, `PivotPoints_S3`
- DeMark method: R2, R3, S2, S3 columns are NaN

### Warmup
- No warmup needed -- each bar is computed independently from its own HLCO values.
- All values are valid from bar 1.

### Test Notes
- Test each method independently with known HLCO values
- Verify DeMark NaN columns
- Verify DeMark conditional logic (C<O, C>O, C==O)
- Level ordering: S3 < S2 < S1 < P < R1 < R2 < R3 (for Classic, Fibonacci, Camarilla)
- Woodie P differs from Classic P due to close weighting
- Input validation: wrong column count, invalid method symbol
- For DeMark: `any(isnan, result[:, 4])` should be true (R2 column), `!any(isnan, result[:, 1])` should be true (Pivot)

### Special Macro Consideration
The `method` parameter is a Symbol type. In the `@prep_mimo` call:
```julia
@prep_mimo PivotPoints [High, Low, Close, Open] [Pivot, R1, R2, R3, S1, S2, S3] method=Classic
```
This follows the same pattern as `ma_type=SMMA` -- Symbol parameters are unquoted in macros and wrapped with QuoteNode by `process_args`.

---

## Summary: Files to Create/Modify

### New Files (src/indicators/)
| File | Lines (est.) | Dependencies |
|------|-------------|-------------|
| `MassIndex.jl` | ~60 | EMA, CircBuff |
| `Vortex.jl` | ~70 | TR, CircBuff |
| `UltimateOsc.jl` | ~80 | TR, CircBuff |
| `ConnorsRSI.jl` | ~100 | RSI, ROC + 2 internal helpers |
| `PivotPoints.jl` | ~150 | None (pure arithmetic) + 5 method helpers |

### Test Modifications
| File | Changes |
|------|---------|
| `test_Indicators_MISO.jl` | Add testsets: MassIndex, UltimateOsc |
| `test_Indicators_MIMO.jl` | Add testsets: Vortex, PivotPoints |
| `test_Indicators_SISO.jl` | Add testset: ConnorsRSI |
| `test_Indicators_AAPL.jl` | Add AAPL regression tests for all 5 (phase 2) |

### No Modifications Needed
- `src/Foxtail.jl` -- auto-includes new indicator files
- `test/runtests.jl` -- test files already included
- No manual exports -- macros handle it

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| RSI called on streak values may throw if series too short | Medium | Validate `length(prices) > max(n_rsi, n_streak) + 1` in ConnorsRSI |
| Division by zero in Vortex/UltimateOsc when TR sum = 0 | Low | Guard with `if sum_tr > 0.0` else 0.0 |
| PivotPoints DeMark NaN propagation in user code | Low | Document clearly; NaN is standard Julia convention |
| 4-column input for PivotPoints is new pattern | Low | AAPL CSV already has Open column; test data just needs 4th column |
| CircBuff partial window behavior during warmup | Low | Existing pattern well-tested; sum accumulates correctly |

---

## Open Questions (Resolved)

1. **Q: Should Pivot Points use previous-bar HLCO (shift by 1)?**
   A: No. Compute from current bar's values. Users control the shift by passing appropriate data. This is simpler and more flexible.

2. **Q: Should _percentile_rank use `<=` or `<` for comparison?**
   A: Use strict `<` (number of values less than current value). This matches the standard Connors RSI definition where rank = (count of values < current) / (total count - 1) * 100.

3. **Q: Should PivotPoints validate that Open column is present?**
   A: Yes, validate `size(prices, 2) == 4`. But only DeMark actually uses Open. The other methods receive it but ignore it. This keeps the interface consistent.
