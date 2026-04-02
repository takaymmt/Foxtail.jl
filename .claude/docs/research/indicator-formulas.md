# Technical Indicator Formulas: Batch 6 Research

Research date: 2026-04-02
Sources: TradingView, StockCharts ChartSchool, Wikipedia, Investopedia, Backtrader

---

## 1. Pivot Points (5 Methods)

### Overview
Pivot Points calculate support/resistance levels from prior-period OHLC data.
All methods use **previous period** High (H), Low (L), Close (C). Woodie and DeMark also use Open (O).

### 1a. Standard (Traditional/Classic)

```
PP = (H + L + C) / 3

R1 = 2 * PP - L
S1 = 2 * PP - H
R2 = PP + (H - L)
S2 = PP - (H - L)
R3 = PP * 2 + (H - 2 * L)       # equivalently: R1 + (H - L)
S3 = PP * 2 - (2 * H - L)       # equivalently: S1 - (H - L)
```

Output columns: PP, S1, S2, S3, R1, R2, R3 (7 levels)

### 1b. Fibonacci

```
PP = (H + L + C) / 3
Range = H - L

R1 = PP + 0.382 * Range
S1 = PP - 0.382 * Range
R2 = PP + 0.618 * Range
S2 = PP - 0.618 * Range
R3 = PP + 1.000 * Range
S3 = PP - 1.000 * Range
```

Output columns: PP, S1, S2, S3, R1, R2, R3 (7 levels)

### 1c. Woodie

Uses **current** Open instead of previous Close for PP weighting.

```
PP = (H + L + 2 * O_current) / 4    # O_current = current period's open

R1 = 2 * PP - L
S1 = 2 * PP - H
R2 = PP + (H - L)
S2 = PP - (H - L)
R3 = H + 2 * (PP - L)
S3 = L - 2 * (H - PP)
```

Output columns: PP, S1, S2, S3, R1, R2, R3 (7 levels)

**Implementation note**: Woodie uses current bar's Open, not previous bar's Open.
In daily data, this means the pivot is recalculated intraday.

### 1d. Camarilla

```
PP = (H + L + C) / 3
Range = H - L

R1 = C + Range * 1.1 / 12
S1 = C - Range * 1.1 / 12
R2 = C + Range * 1.1 / 6
S2 = C - Range * 1.1 / 6
R3 = C + Range * 1.1 / 4
S3 = C - Range * 1.1 / 4
R4 = C + Range * 1.1 / 2
S4 = C - Range * 1.1 / 2
```

Output columns: PP, S1, S2, S3, S4, R1, R2, R3, R4 (9 levels)

**Note**: Camarilla levels are centered on Close (not PP). The PP is still calculated
as Traditional for reference. Primary trading levels are S3/R3 (range) and S4/R4 (breakout).

### 1e. DeMark

Conditional calculation based on Open vs Close relationship:

```
if C < O:
    X = H + 2*L + C
elif C > O:
    X = 2*H + L + C
elif C == O:
    X = H + L + 2*C

PP = X / 4
R1 = X / 2 - L
S1 = X / 2 - H
```

Output columns: PP, S1, R1 **only** (3 levels)

**Critical difference**: DeMark produces ONLY PP, R1, S1 (no R2/R3/S2/S3).
This means DeMark has a different output schema than all other methods.

### Pivot Points: Default Parameters
- Timeframe: Daily (using previous day's OHLC)
- No period parameter needed (always uses single prior bar)

### Pivot Points: Boundary Conditions
- Requires at least 2 bars (current + previous)
- First bar: NaN/missing (no previous data)
- When H == L (no range): all S/R levels collapse to PP for Standard/Fibonacci;
  Camarilla levels all equal Close

### Pivot Points: Implementation Notes
- Input: OHLC data (Matrix with [High, Low, Close] minimum; Woodie/DeMark also need Open)
- Macro type: MIMO (multi-input [O,H,L,C], multi-output [PP, S1..S3, R1..R3])
- Consider: Single function with `method` parameter, or separate functions per method
- DeMark's different output shape is a design decision:
  Option A: Return NaN for missing S2/S3/R2/R3 columns
  Option B: Return fewer columns (breaks uniform interface)
  **Recommendation**: Option A (NaN padding) for uniform output, with method parameter

### Pivot Points: Foxtail.jl Macro Pattern
- MIMO: `@prep_mimo PivotPoints [Open, High, Low, Close] [PP, S1, S2, S3, R1, R2, R3] method=Standard`
- Or separate per method if output columns differ significantly

---

## 2. Connors RSI (CRSI)

### Overview
Composite oscillator by Larry Connors combining three normalized components.
Range: 0-100.

### Formula
```
CRSI(rsi_n, streak_n, pctrank_n) = (RSI(Close, rsi_n) + RSI(Streak, streak_n) + PercentRank(ROC1, pctrank_n)) / 3
```

Default parameters: `(3, 2, 100)`

### Component 1: RSI of Price — RSI(Close, 3)

Standard RSI applied to closing prices with period = 3.
Uses Wilder's smoothing (SMMA) as per standard RSI.

### Component 2: RSI of Streak — RSI(Streak, 2)

**Step 1: Calculate Streak Series**
```
streak[0] = 0  # initial

For each bar i (from 1 onward):
    if close[i] > close[i-1]:
        if streak[i-1] > 0:
            streak[i] = streak[i-1] + 1
        else:
            streak[i] = 1
    elif close[i] < close[i-1]:
        if streak[i-1] < 0:
            streak[i] = streak[i-1] - 1
        else:
            streak[i] = -1
    else:  # close[i] == close[i-1]
        streak[i] = 0    # RESET to zero on unchanged close
```

**Step 2: Apply RSI(2) to Streak series**
Standard RSI with period = 2 applied to the streak values.

**Key edge case**: Equal consecutive closes reset streak to 0 (not continue previous streak).

### Component 3: Percentile Rank of ROC(1) — PercentRank(ROC1, 100)

**Step 1: Calculate 1-period Rate of Change**
```
roc1[i] = (close[i] - close[i-1]) / close[i-1] * 100
# Or equivalently: roc1[i] = close[i] / close[i-1] - 1
```

Note: Some implementations use raw price change `close[i] - close[i-1]` instead of
percentage ROC. The percentile rank normalizes either way, but percentage ROC is
the standard per Connors' original definition and TradingView.

**Step 2: Rolling Percentile Rank over lookback period**
```
PercentRank(roc1, n)[i] = (count of roc1[j] < roc1[i], for j in [i-n..i-1]) / n * 100
```

**Important**: The standard formula counts values **strictly less than** the current value
(not less than or equal). This matches the Excel PERCENTRANK function behavior and
Connors' original specification. TradingView's `ta.percentrank` uses "less than" (strictly).

Alternative interpretation (some implementations): count values <= current / n * 100.
**Recommendation**: Use strictly less than, per original Connors specification.

The lookback window does NOT include the current value — it compares the current
ROC against the previous `n` ROC values.

### Connors RSI: Default Parameters
- RSI period: 3
- Streak RSI period: 2
- PercentRank lookback: 100

### Connors RSI: Boundary Conditions
- Needs at least max(rsi_n, streak_n, pctrank_n) + warmup bars
- Practical minimum: ~104 bars (100 for percentile rank + RSI warmup)
- Before enough data: NaN/0.0 for early bars
- First bar: streak = 0 (no prior bar to compare)

### Connors RSI: Output Range
- 0 to 100
- Overbought: > 90
- Oversold: < 10

### Connors RSI: Implementation Pitfalls
1. **Streak reset on equal close**: Must be 0, not continuation of previous streak
2. **PercentRank window**: Compare against previous n values, NOT including current
3. **ROC vs raw change**: Use percentage ROC, not absolute price change
4. **PercentRank strictly less vs less-or-equal**: Use strictly less than
5. **RSI of Streak**: The streak series contains negative values; RSI handles this
   via gains/losses separation (positive changes are gains, negative changes are losses)

### Connors RSI: Foxtail.jl Pattern
- SISO: `@prep_siso ConnorsRSI rsi_n=3 streak_n=2 pctrank_n=100`
- Depends on existing: `RSI()` function
- New helpers needed: `streak()`, `percent_rank()`

---

## 3. Vortex Indicator (VI)

### Overview
Created by Etienne Botes and Douglas Siepman (2010).
Identifies trend direction and strength using two lines: VI+ and VI-.
Based on the concept of vortex motion in water (Schauberger).

### Formula

**Step 1: Vortex Movement (per bar)**
```
VM_plus[i]  = abs(high[i] - low[i-1])     # uptrend movement
VM_minus[i] = abs(low[i] - high[i-1])     # downtrend movement
```

**Step 2: True Range (per bar)**
```
TR[i] = max(high[i] - low[i], abs(high[i] - close[i-1]), abs(low[i] - close[i-1]))
```

**Step 3: N-period Summation**
```
sum_VM_plus[i]  = sum(VM_plus[i-n+1 .. i])
sum_VM_minus[i] = sum(VM_minus[i-n+1 .. i])
sum_TR[i]       = sum(TR[i-n+1 .. i])
```

**Step 4: Normalize**
```
VI_plus[i]  = sum_VM_plus[i] / sum_TR[i]
VI_minus[i] = sum_VM_minus[i] / sum_TR[i]
```

### Vortex Indicator: Default Parameters
- Period (n): 14 (common alternatives: 21, 25)

### Vortex Indicator: Output Range
- Typically oscillates around 1.0
- Range roughly 0.5 to 1.5 (not bounded)
- VI+ > VI-: uptrend
- VI+ < VI-: downtrend
- Signal: crossover of VI+ and VI-

### Vortex Indicator: Boundary Conditions
- Needs n+1 bars minimum (1 bar for VM/TR calculation + n bars for sum)
- First n bars: NaN/0.0 (not enough data for full summation)
- Bar 1 (index 0): Cannot calculate VM or TR (no previous bar)

### Vortex Indicator: Implementation Pitfalls
1. **Absolute values**: VM+ and VM- use absolute values
2. **True Range**: Same as ATR's True Range — reuse existing TR if available
3. **Sum, not average**: Uses rolling SUM (not SMA) for VM and TR
4. **Division by zero**: If sum_TR == 0 (all bars identical), handle gracefully

### Vortex Indicator: Foxtail.jl Pattern
- MIMO: `@prep_mimo Vortex [High, Low, Close] [Plus, Minus] n=14`
- Reuse: True Range calculation from ATR indicator

---

## 4. Ultimate Oscillator (UO)

### Overview
Created by Larry Williams (1976/1985). Combines three timeframes to reduce
false signals. Measures buying pressure relative to true range.

### Formula

**Step 1: Buying Pressure (BP) and True Range (TR) per bar**
```
BP[i] = close[i] - min(low[i], close[i-1])
TR[i] = max(high[i], close[i-1]) - min(low[i], close[i-1])
```

Note: This TR definition is equivalent to the standard True Range.

**Step 2: Three-period Averages (ratio of sums)**
```
avg7[i]  = sum(BP[i-6..i])  / sum(TR[i-6..i])
avg14[i] = sum(BP[i-13..i]) / sum(TR[i-13..i])
avg28[i] = sum(BP[i-27..i]) / sum(TR[i-27..i])
```

**Important**: These are NOT simple averages. They are sum(BP)/sum(TR), i.e.,
the ratio of the sums, not the average of ratios.

**Step 3: Weighted Combination**
```
UO[i] = 100 * (4 * avg7[i] + 2 * avg14[i] + 1 * avg28[i]) / (4 + 2 + 1)
```

Simplified:
```
UO[i] = 100 * (4 * avg7[i] + 2 * avg14[i] + avg28[i]) / 7
```

### Ultimate Oscillator: Default Parameters
- Period 1 (short): 7
- Period 2 (medium): 14
- Period 3 (long): 28
- Weights: 4, 2, 1 (short has highest weight)

### Ultimate Oscillator: Output Range
- 0 to 100
- Overbought: > 70
- Oversold: < 30

### Ultimate Oscillator: Boundary Conditions
- Needs max(p1, p2, p3) + 1 bars minimum = 29 bars with defaults
- First 28 bars: NaN/0.0
- Bar 0: Cannot calculate BP or TR (no previous close)
- Edge case: If TR == 0 for entire sum window, division by zero

### Ultimate Oscillator: Implementation Pitfalls
1. **Sum ratio, not average ratio**: avg7 = sum(BP,7)/sum(TR,7), NOT mean(BP/TR)
2. **BP calculation**: Uses min(low, prev_close), not just low
3. **TR calculation**: Same True Range as standard definition
4. **Weights must be configurable**: Though defaults are 4:2:1
5. **First bar**: No previous close available; start calculations from bar 2

### Ultimate Oscillator: Foxtail.jl Pattern
- MISO: `@prep_miso UltimateOsc [High, Low, Close] p1=7 p2=14 p3=28`
- Reuse: True Range / Buying Pressure are simple per-bar calculations

---

## 5. Mass Index (MI)

### Overview
Created by Donald Dorsey (1992). Detects trend reversals by measuring
range expansion/contraction. Uses EMA of price range, not price itself.

### Formula

**Step 1: Single EMA of Range**
```
range[i] = high[i] - low[i]
single_ema[i] = EMA(range, ema_period)[i]      # 9-period EMA of H-L range
```

**Step 2: Double EMA of Range**
```
double_ema[i] = EMA(single_ema, ema_period)[i]  # 9-period EMA of single_ema
```

**Step 3: EMA Ratio**
```
ema_ratio[i] = single_ema[i] / double_ema[i]
```

**Step 4: Mass Index (Rolling Sum)**
```
MI[i] = sum(ema_ratio[i-sum_period+1 .. i])     # 25-period sum of ema_ratio
```

### Mass Index: Default Parameters
- EMA period: 9
- Summation period: 25

### Mass Index: Output Range
- Not bounded to 0-100
- Typically oscillates around 25 (since sum of ~25 values near 1.0)
- When single_ema ≈ double_ema, ratio ≈ 1.0, so MI ≈ 25
- Range expansion → ratio > 1.0 → MI rises above 25
- Range contraction → ratio < 1.0 → MI falls below 25

### Signal: Reversal Bulge
- MI rises above 27.0
- Then falls below 26.5 (or 26.0 for more signals)
- Indicates probable trend reversal (direction determined by other indicators)

### Mass Index: Boundary Conditions
- EMA warmup: ~2 * ema_period bars for double EMA convergence
- Sum warmup: sum_period bars
- Practical minimum: 2 * 9 + 25 = 43 bars (conservative)
- First ~33 bars: NaN/0.0 (9 for single EMA + 9 for double EMA warm-up is approximate,
  but since EMA starts from bar 1 in Foxtail, the sum needs 25 bars of valid ratio)
- Division by zero: If double_ema == 0 (impossible with positive H-L range unless
  all ranges are exactly 0.0, i.e., H == L for extended period)

### Mass Index: Implementation Pitfalls
1. **Double EMA is NOT DEMA**: It's EMA(EMA(x)), not the Mulloy DEMA formula (2*EMA - EMA(EMA))
2. **Sum, not average**: Final step is SUM over 25 periods, not moving average
3. **EMA initialization**: Both EMA passes use same period (9); second EMA operates
   on output of first EMA — handle warmup of cascaded EMAs
4. **Range must be non-negative**: high >= low always, so range >= 0
5. **Division stability**: double_ema approaches single_ema, so ratio hovers near 1.0;
   no division-by-zero concern unless range is persistently 0

### Mass Index: Foxtail.jl Pattern
- MISO: `@prep_miso MassIndex [High, Low] ema_period=9 sum_period=25`
- Reuse: existing `EMA()` function for both passes

---

## Summary: Implementation Complexity and Dependencies

| Indicator | Type | Inputs | Outputs | Dependencies | Complexity |
|-----------|------|--------|---------|--------------|------------|
| Pivot Points | MIMO | O,H,L,C | PP,S1-S3,R1-R3 | None | Low (pure arithmetic) |
| Connors RSI | SISO | Close | CRSI | RSI, ROC | Medium (3 sub-calculations) |
| Vortex | MIMO | H,L,C | VI+, VI- | True Range | Low-Medium |
| Ultimate Osc | MISO | H,L,C | UO | None (inline BP/TR) | Low-Medium |
| Mass Index | MISO | H,L | MI | EMA | Low |

## Key Design Decisions for Foxtail.jl

1. **Pivot Points method parameter**: Single function with `method::Symbol` param
   (:Standard, :Fibonacci, :Woodie, :Camarilla, :DeMark) — DeMark fills
   S2/S3/R2/R3 with NaN. Or separate functions per method.

2. **Connors RSI helper functions**: Need `streak()` and `percent_rank()` as
   reusable internal helpers. Percent rank is useful elsewhere too.

3. **True Range reuse**: Vortex and Ultimate Oscillator both need True Range.
   ATR already calculates it — extract TR into a shared utility if not already done.

4. **EMA reuse**: Mass Index needs two cascaded EMA(9) calls. Existing `EMA()`
   function in Foxtail.jl handles this directly.

5. **Camarilla R4/S4**: Additional output columns beyond the standard 7.
   Decide whether to always output 9 levels or only for Camarilla.

---

## Sources

- [TradingView Pivot Points Standard](https://www.tradingview.com/support/solutions/43000521824-pivot-points-standard/)
- [TradingView ConnorsRSI](https://www.tradingview.com/support/solutions/43000502017-connors-rsi-crsi/)
- [TradingView Vortex Indicator](https://www.tradingview.com/support/solutions/43000591352-vortex-indicator/)
- [TradingView Ultimate Oscillator](https://www.tradingview.com/support/solutions/43000502328-ultimate-oscillator-uo/)
- [TradingView Mass Index](https://www.tradingview.com/support/solutions/43000589169-mass-index/)
- [StockCharts ConnorsRSI](https://chartschool.stockcharts.com/table-of-contents/technical-indicators-and-overlays/technical-indicators/connorsrsi)
- [StockCharts Vortex Indicator](https://chartschool.stockcharts.com/table-of-contents/technical-indicators-and-overlays/technical-indicators/vortex-indicator)
- [StockCharts Ultimate Oscillator](https://chartschool.stockcharts.com/table-of-contents/technical-indicators-and-overlays/technical-indicators/ultimate-oscillator)
- [StockCharts Mass Index](https://chartschool.stockcharts.com/table-of-contents/technical-indicators-and-overlays/technical-indicators/mass-index)
- [Wikipedia Vortex Indicator](https://en.wikipedia.org/wiki/Vortex_indicator)
- [Wikipedia Ultimate Oscillator](https://en.wikipedia.org/wiki/Ultimate_oscillator)
- [BabyPips Pivot Point Methods](https://www.babypips.com/learn/forex/other-pivot-point-calculation-methods)
- [Backtrader ConnorsRSI Implementation](https://www.backtrader.com/recipes/indicators/crsi/crsi/)
- [Camarilla Pivot Points (Defcofx)](https://www.defcofx.com/camarilla-pivot-points/)
