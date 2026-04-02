# Foxtail.jl Indicator Reference

Complete reference for all 45 technical indicators in Foxtail.jl.

## Summary Table

### Moving Averages

| # | Indicator | Type | Description | Key Parameters | Output Columns |
|---|-----------|------|-------------|----------------|----------------|
| 1 | [ALMA](#alma) | SISO | Arnaud Legoux Moving Average | `n=10`, `offset=0.85`, `sigma=6.0` | `ALMA_n` |
| 2 | [DEMA](#dema) | SISO | Double Exponential Moving Average | `n=10` | `DEMA_n` |
| 3 | [EMA](#ema) | SISO | Exponential Moving Average | `n=10` | `EMA_n` |
| 4 | [HMA](#hma) | SISO | Hull Moving Average | `n=10` | `HMA_n` |
| 5 | [JMA](#jma) | SISO | Jurik Moving Average | `n=7`, `phase=0.0` | `JMA_n` |
| 6 | [KAMA](#kama) | SISO | Kaufman Adaptive Moving Average | `n=10`, `fast=2`, `slow=30` | `KAMA_n` |
| 7 | [SMA](#sma) | SISO | Simple Moving Average | `n=14` | `SMA_n` |
| 8 | [SMMA](#smma) | SISO | Smoothed Moving Average (Wilder's) | `n=10` | `SMMA_n` |
| 9 | [T3](#t3) | SISO | Tillson T3 Moving Average | `n=10`, `a=0.7` | `T3_n` |
| 10 | [TEMA](#tema) | SISO | Triple Exponential Moving Average | `n=10` | `TEMA_n` |
| 11 | [TMA](#tma) | SISO | Triangular Moving Average | `n=10` | `TMA_n` |
| 12 | [WMA](#wma) | SISO | Weighted Moving Average | `n=10` | `WMA_n` |
| 13 | [ZLEMA](#zlema) | SISO | Zero-Lag EMA | `n=10` | `ZLEMA_n` |

### Trend Indicators

| # | Indicator | Type | Description | Key Parameters | Output Columns |
|---|-----------|------|-------------|----------------|----------------|
| 14 | [Aroon](#aroon) | MIMO | Aroon Indicator | `n=25` | `Aroon_Up`, `Aroon_Down`, `Aroon_Oscillator` |
| 15 | [DMI](#dmi) | MIMO | Directional Movement Index / ADX | `n=14` | `DMI_DIPlus`, `DMI_DIMinus`, `DMI_ADX` |
| 16 | [DonchianChannel](#donchianchannel) | MIMO | Donchian Channel | `n=20` | `DonchianChannel_Upper`, `_Lower`, `_Middle` |
| 17 | [Ichimoku](#ichimoku) | MIMO | Ichimoku Cloud | `tenkan=9`, `kijun=26`, `senkou_b=52`, `displacement=26` | `Ichimoku_Tenkan`, `_Kijun`, `_SenkouA`, `_SenkouB`, `_Chikou` |
| 18 | [KeltnerChannel](#keltnerchannel) | MIMO | Keltner Channel | `n=20`, `mult=2.0`, `ma_type=:EMA` | `KeltnerChannel_Middle`, `_Upper`, `_Lower` |
| 19 | [ParabolicSAR](#parabolicsar) | MIMO | Parabolic Stop and Reverse | `af_start=0.02`, `af_step=0.02`, `af_max=0.20` | `ParabolicSAR_Value`, `_Direction` |
| 20 | [Supertrend](#supertrend) | MIMO | Supertrend | `n=7`, `mult=3.0` | `Supertrend_Value`, `_Direction` |

### Momentum Indicators

| # | Indicator | Type | Description | Key Parameters | Output Columns |
|---|-----------|------|-------------|----------------|----------------|
| 21 | [CCI](#cci) | MISO | Commodity Channel Index | `n=20` | `CCI_n` |
| 22 | [DPO](#dpo) | SISO | Detrended Price Oscillator | `n=20` | `DPO_n` |
| 23 | [KST](#kst) | SIMO | Know Sure Thing | `r1=10`, `r2=13`, `r3=15`, `r4=20`, ... | `KST_Line`, `KST_Signal` |
| 24 | [MACD](#macd) | SIMO | Moving Average Convergence Divergence | `fast=12`, `slow=26`, `signal=9` | `MACD_Line`, `_Signal`, `_Histogram` |
| 25 | [MACD3](#macd3) | SIMO | Triple MACD | `fast=5`, `middle=20`, `slow=40`, `ma_type=:EMA` | `MACD3_Fast`, `_Middle`, `_Slow` |
| 26 | [PPO](#ppo) | SIMO | Percentage Price Oscillator | `fast=12`, `slow=26`, `signal=9` | `PPO_Line`, `_Signal`, `_Histogram` |
| 27 | [ROC](#roc) | SISO | Rate of Change | `n=14` | `ROC_n` |
| 28 | [RSI](#rsi) | SISO | Relative Strength Index | `n=14`, `ma_type=:SMMA` | `RSI_n` |
| 29 | [StochRSI](#stochrsi) | SIMO | Stochastic RSI | `n=14`, `k_smooth=3`, `d_smooth=3` | `StochRSI_K`, `StochRSI_D` |

### Oscillators

| # | Indicator | Type | Description | Key Parameters | Output Columns |
|---|-----------|------|-------------|----------------|----------------|
| 30 | [Stoch](#stoch) | MIMO | Stochastic Oscillator | `n=14`, `k_smooth=3`, `d_smooth=3` | `Stoch_K`, `Stoch_D` |
| 31 | [WR](#wr) | MIMO | Williams %R | `n=14` | `WR_raw`, `WR_EMA` |
| 32 | [SqueezeMomentum](#squeezemomentum) | MIMO | TTM Squeeze Momentum | `n=20`, `bb_mult=2.0`, `kc_mult=1.5` | `SqueezeMomentum_Histogram`, `_Squeeze` |

### Volume Indicators

| # | Indicator | Type | Description | Key Parameters | Output Columns |
|---|-----------|------|-------------|----------------|----------------|
| 33 | [ADL](#adl) | MISO | Accumulation/Distribution Line | *(none)* | `ADL` |
| 34 | [ChaikinOsc](#chaikinosc) | MISO | Chaikin Oscillator | `fast=3`, `slow=10` | `ChaikinOsc` |
| 35 | [CMF](#cmf) | MISO | Chaikin Money Flow | `n=20` | `CMF_n` |
| 36 | [EMV](#emv) | MISO | Ease of Movement | `n=14` | `EMV_n` |
| 37 | [ForceIndex](#forceindex) | MISO | Force Index | `n=13` | `ForceIndex_n` |
| 38 | [MFI](#mfi) | MISO | Money Flow Index | `n=14` | `MFI_n` |
| 39 | [NVI](#nvi) | MISO | Negative Volume Index | *(none)* | `NVI` |
| 40 | [OBV](#obv) | MISO | On Balance Volume | *(none)* | `OBV` |
| 41 | [PVI](#pvi) | MISO | Positive Volume Index | *(none)* | `PVI` |
| 42 | [VPT](#vpt) | MISO | Volume Price Trend | *(none)* | `VPT` |
| 43 | [VWAP](#vwap) | MISO | Volume Weighted Average Price | *(none)* | `VWAP` |

### Volatility Indicators

| # | Indicator | Type | Description | Key Parameters | Output Columns |
|---|-----------|------|-------------|----------------|----------------|
| 44 | [ATR](#atr) | MISO | Average True Range | `n=14`, `ma_type=:EMA` | `ATR_n` |
| 45 | [BB](#bb) | SIMO | Bollinger Bands | `n=14`, `num_std=2.0`, `ma_type=:SMA` | `BB_Center`, `BB_Upper`, `BB_Lower` |

**Type legend**: SISO = Single Input Single Output, MISO = Multiple Input Single Output, SIMO = Single Input Multiple Output, MIMO = Multiple Input Multiple Output.

**Column naming**: `_n` in the output column means the column name includes the `n` parameter value at runtime (e.g., `SMA_20` when called with `n=20`). Indicators without `n` use a fixed name. SIMO/MIMO output columns use the pattern `IndicatorName_Suffix`.

---

## Moving Averages

### ALMA

**Arnaud Legoux Moving Average** -- a Gaussian-weighted moving average that reduces lag while maintaining smoothness.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `ALMA(prices::Vector; n::Int=10, offset::Float64=0.85, sigma::Float64=6.0) -> Vector{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (window size), `offset=0.85` (weight center, 0.0-1.0), `sigma=6.0` (Gaussian width) |
| Output columns | `ALMA_n` |

```julia
# TSFrame usage
ALMA(ts)                                    # defaults: n=10, offset=0.85, sigma=6.0
ALMA(ts; n=21, offset=0.9, sigma=5.5)       # custom parameters
ALMA(ts; field=:Volume, n=10)               # apply to Volume column
```

**See Also**: [`EMA`](#ema), [`HMA`](#hma), [`KAMA`](#kama)

---

### DEMA

**Double Exponential Moving Average** -- reduces lag by combining two EMAs: `2*EMA - EMA(EMA)`.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `DEMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (smoothing period) |
| Output columns | `DEMA_n` |

```julia
DEMA(ts)                # defaults: n=10
DEMA(ts; n=20)          # custom period
```

**See Also**: [`EMA`](#ema), [`TEMA`](#tema), [`ZLEMA`](#zlema)

---

### EMA

**Exponential Moving Average** -- a weighted moving average giving more weight to recent prices.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `EMA(data::Vector{T}; n::Int=10) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (smoothing period, alpha = 2/(n+1)) |
| Output columns | `EMA_n` |

```julia
EMA(ts)                # defaults: n=10
EMA(ts; n=50)          # long-term EMA
```

Also provides `EMA_stats(data; n)` returning a Matrix with EMA and standard deviation (not exported via TSFrame wrapper).

**See Also**: [`SMA`](#sma), [`DEMA`](#dema), [`TEMA`](#tema), [`ZLEMA`](#zlema)

---

### HMA

**Hull Moving Average** -- a fast, smooth moving average with minimal lag using nested WMAs.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `HMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (primary period, must be >= 2) |
| Output columns | `HMA_n` |

```julia
HMA(ts)                # defaults: n=10
HMA(ts; n=20)          # custom period
```

**See Also**: [`WMA`](#wma), [`EMA`](#ema), [`DEMA`](#dema)

---

### JMA

**Jurik Moving Average** -- a triple adaptive filter with superior noise reduction and minimal lag.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `JMA(data::Vector{Float64}; n::Int=7, phase::Float64=0.0) -> Vector{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=7` (base smoothing period, > 1), `phase=0.0` (lag/smoothing trade-off, -100.0 to 100.0) |
| Output columns | `JMA_n` |

```julia
JMA(ts)                         # defaults: n=7, phase=0.0
JMA(ts; n=14, phase=50.0)      # faster response with positive phase
JMA(ts; n=14, phase=-50.0)     # smoother with negative phase
```

**See Also**: [`EMA`](#ema), [`KAMA`](#kama), [`ALMA`](#alma)

---

### KAMA

**Kaufman Adaptive Moving Average** -- adapts smoothing speed based on market efficiency ratio.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `KAMA(data::AbstractVector{T}; n::Int=10, fast::Int=2, slow::Int=30) where T <: AbstractFloat -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (efficiency ratio period), `fast=2` (fast EMA period), `slow=30` (slow EMA period) |
| Output columns | `KAMA_n` |

```julia
KAMA(ts)                            # defaults: n=10, fast=2, slow=30
KAMA(ts; n=20, fast=5, slow=25)     # custom parameters
```

**See Also**: [`EMA`](#ema), [`JMA`](#jma), [`ALMA`](#alma)

---

### SMA

**Simple Moving Average** -- the arithmetic mean of prices over a moving window.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `SMA(data::Vector{T}; n::Int=14) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=14` (window length) |
| Output columns | `SMA_n` |

```julia
SMA(ts)                # defaults: n=14
SMA(ts; n=200)         # long-term SMA
SMA(ts; field=:Volume) # apply to Volume column
```

Also provides `SMA_stats(prices; n)` returning a Matrix with SMA and standard deviation (not exported via TSFrame wrapper).

**See Also**: [`EMA`](#ema), [`WMA`](#wma), [`TMA`](#tma)

---

### SMMA

**Smoothed Moving Average** (also known as RMA / Wilder's Smoothing) -- an EMA variant with `alpha = 1/n`.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `SMMA(data::Vector{T}; n::Int=14) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (smoothing period; note: raw function defaults to 14, TSFrame wrapper defaults to 10) |
| Output columns | `SMMA_n` |
| Aliases | `RMA(ts; n=14, field=:Close)` -- TSFrame-only alias |

```julia
SMMA(ts)               # defaults: n=10
SMMA(ts; n=14)         # Wilder's standard period
RMA(ts; n=14)          # alias for SMMA
```

Also provides `SMMA_stats(data; n)` returning a Matrix with SMMA and standard deviation (not exported).

**See Also**: [`EMA`](#ema), [`SMA`](#sma), [`RSI`](#rsi)

---

### T3

**Tillson T3 Moving Average** -- a six-stage EMA combination producing an ultra-smooth, low-lag indicator.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `T3(prices::Vector{T}; n::Int=10, a::Float64=0.7) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (period for each EMA stage), `a=0.7` (volume factor, 0.0-1.0) |
| Output columns | `T3_n` |

```julia
T3(ts)                     # defaults: n=10, a=0.7
T3(ts; n=20, a=0.6)       # custom parameters
```

**See Also**: [`EMA`](#ema), [`TEMA`](#tema), [`DEMA`](#dema)

---

### TEMA

**Triple Exponential Moving Average** -- reduces lag beyond DEMA using three cascaded EMAs.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `TEMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (smoothing period) |
| Output columns | `TEMA_n` |

```julia
TEMA(ts)               # defaults: n=10
TEMA(ts; n=20)         # custom period
```

**See Also**: [`EMA`](#ema), [`DEMA`](#dema), [`T3`](#t3)

---

### TMA

**Triangular Moving Average** -- a double-smoothed SMA with triangular weight distribution.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `TMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (first SMA period; second SMA uses `div(n+1, 2)`) |
| Output columns | `TMA_n` |
| Aliases | `TRIMA(ts; n=10, field=:Close)` -- TSFrame-only alias |

```julia
TMA(ts)                # defaults: n=10
TMA(ts; n=20)          # custom period
TRIMA(ts; n=20)        # alias for TMA
```

**See Also**: [`SMA`](#sma), [`DEMA`](#dema), [`TEMA`](#tema)

---

### WMA

**Weighted Moving Average** -- linearly weighted, giving more weight to recent prices.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `WMA(data::Vector{T}; n::Int=10) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (window length; weights scale from 1 to n) |
| Output columns | `WMA_n` |

```julia
WMA(ts)                # defaults: n=10
WMA(ts; n=20)          # custom period
```

**See Also**: [`SMA`](#sma), [`EMA`](#ema), [`HMA`](#hma)

---

### ZLEMA

**Zero-Lag Exponential Moving Average** -- compensates for EMA lag using a de-lagged price input.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `ZLEMA(data::Vector{T}; n::Int=10) where T -> Vector{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=10` (smoothing period) |
| Output columns | `ZLEMA_n` |

```julia
ZLEMA(ts)              # defaults: n=10
ZLEMA(ts; n=20)        # custom period
```

**See Also**: [`EMA`](#ema), [`DEMA`](#dema), [`TEMA`](#tema)

---

## Trend Indicators

### Aroon

**Aroon Indicator** -- measures trend strength by tracking how long since the highest high and lowest low within a lookback window.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `Aroon(prices::Matrix{Float64}; n::Int=25) -> Matrix{Float64}` |
| Input fields | `[:High, :Low]` (configurable via `fields`) |
| Parameters | `n=25` (lookback period) |
| Output columns | `Aroon_Up`, `Aroon_Down`, `Aroon_Oscillator` |

```julia
Aroon(ts)              # defaults: n=25
Aroon(ts; n=14)        # shorter lookback
```

**Notes**:
- Aroon Up/Down range is [0, 100]. Oscillator range is [-100, 100].
- Aroon Up > 70 indicates a strong uptrend (recent new high). Aroon Down > 70 indicates a strong downtrend.
- The Oscillator (Up - Down) near zero signals consolidation.
- Created by Tushar Chande (1995).

**See Also**: [`DMI`](#dmi), [`Supertrend`](#supertrend), [`Stoch`](#stoch)

---

### DMI

**Directional Movement Index / ADX** -- measures both trend strength (ADX) and direction (+DI / -DI) using Wilder's smoothing.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `DMI(prices::Matrix{Float64}; n::Int=14) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=14` (smoothing period for DI and ADX calculations) |
| Output columns | `DMI_DIPlus`, `DMI_DIMinus`, `DMI_ADX` |

```julia
DMI(ts)                # defaults: n=14
DMI(ts; n=20)          # custom period
```

**Notes**:
- All three outputs range [0, 100].
- ADX > 25 indicates a strong trend (regardless of direction). ADX < 20 suggests a weak/range-bound market.
- +DI crossing above -DI is a buy signal; -DI crossing above +DI is a sell signal.
- Uses SMMA (Wilder's smoothing) internally for +DM, -DM, TR, and DX.
- Created by J. Welles Wilder Jr. (1978).

**See Also**: [`ATR`](#atr), [`Supertrend`](#supertrend), [`Aroon`](#aroon)

---

### DonchianChannel

**Donchian Channel** -- a breakout indicator showing the highest high and lowest low over a rolling window.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `DonchianChannel(prices::Matrix{Float64}; n::Int=20) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=20` (lookback period) |
| Output columns | `DonchianChannel_Upper`, `DonchianChannel_Lower`, `DonchianChannel_Middle` |

```julia
DonchianChannel(ts)            # defaults: n=20
DonchianChannel(ts; n=50)     # longer lookback
```

**Notes**:
- Upper = highest high over n bars. Lower = lowest low over n bars. Middle = (Upper + Lower) / 2.
- Uses MinMaxQueue for O(1) amortized sliding-window max/min.
- Price breaking above the upper channel signals a potential uptrend breakout; breaking below the lower channel signals a potential downtrend.

**See Also**: [`KeltnerChannel`](#keltnerchannel), [`BB`](#bb), [`Supertrend`](#supertrend)

---

### Ichimoku

**Ichimoku Cloud (Ichimoku Kinko Hyo)** -- a comprehensive trend-following indicator system with five components.

| Property | Value |
|----------|-------|
| Type | MIMO (custom TSFrame wrapper) |
| Raw signature | `Ichimoku(prices::Matrix{Float64}; tenkan::Int=9, kijun::Int=26, senkou_b::Int=52, displacement::Int=26) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `tenkan=9` (Conversion Line period), `kijun=26` (Base Line period), `senkou_b=52` (Leading Span B period), `displacement=26` (forward/backward projection) |
| Output columns | `Ichimoku_Tenkan`, `Ichimoku_Kijun`, `Ichimoku_SenkouA`, `Ichimoku_SenkouB`, `Ichimoku_Chikou` |

```julia
Ichimoku(ts)                                               # defaults
Ichimoku(ts; tenkan=9, kijun=26, senkou_b=52, displacement=26)  # explicit defaults
Ichimoku(ts; tenkan=7, kijun=22, senkou_b=44, displacement=22)  # crypto-optimized
```

**Notes**:
- The output TSFrame has `nrow(ts) + displacement` rows. Senkou Spans are projected forward, and Chikou Span is shifted backward.
- Future dates are inferred from the median time step of the input index.
- Price above the cloud is bullish; Tenkan crossing above Kijun (TK Cross) is a bullish signal.
- Created by Goichi Hosoda (1960s).

**See Also**: [`DMI`](#dmi), [`Supertrend`](#supertrend), [`Stoch`](#stoch)

---

### KeltnerChannel

**Keltner Channel** -- volatility-based envelopes using ATR around a moving average of Close.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `KeltnerChannel(prices::Matrix{Float64}; n::Int=20, mult::Float64=2.0, ma_type::Symbol=:EMA) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=20` (period for MA and ATR), `mult=2.0` (ATR multiplier for band width), `ma_type=:EMA` (MA type for center line) |
| Output columns | `KeltnerChannel_Middle`, `KeltnerChannel_Upper`, `KeltnerChannel_Lower` |

```julia
KeltnerChannel(ts)                             # defaults: n=20, mult=2.0, ma_type=:EMA
KeltnerChannel(ts; n=20, mult=1.5)            # narrower bands
KeltnerChannel(ts; n=10, ma_type=:SMA)        # SMA center line
```

**Notes**:
- Middle = MA(Close, n). Upper = Middle + mult * ATR(n). Lower = Middle - mult * ATR(n).
- Used by SqueezeMomentum for squeeze detection (BB inside KC).

**See Also**: [`BB`](#bb), [`ATR`](#atr), [`DonchianChannel`](#donchianchannel), [`SqueezeMomentum`](#squeezemomentum)

---

### ParabolicSAR

**Parabolic Stop and Reverse** -- Wilder's trend-following indicator providing trailing stop levels with an accelerating factor.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `ParabolicSAR(prices::Matrix{Float64}; af_start::Float64=0.02, af_step::Float64=0.02, af_max::Float64=0.20) -> Matrix{Float64}` |
| Input fields | `[:High, :Low]` (configurable via `fields`) |
| Parameters | `af_start=0.02` (initial acceleration factor), `af_step=0.02` (AF increment per new extreme), `af_max=0.20` (maximum AF) |
| Output columns | `ParabolicSAR_Value`, `ParabolicSAR_Direction` |

```julia
ParabolicSAR(ts)                                               # defaults
ParabolicSAR(ts; af_start=0.01, af_step=0.01, af_max=0.10)   # slower acceleration
```

**Notes**:
- Direction: `1.0` = uptrend (SAR below price), `-1.0` = downtrend (SAR above price).
- SAR is clamped so it does not exceed the two previous bars' lows (uptrend) or highs (downtrend).
- A reversal occurs when price crosses the SAR level; the SAR resets to the previous extreme point.
- Created by J. Welles Wilder Jr. (1978).

**See Also**: [`Supertrend`](#supertrend), [`ATR`](#atr), [`DMI`](#dmi)

---

### Supertrend

**Supertrend** -- a trend-following indicator based on ATR that identifies the current trend direction with a trailing stop.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `Supertrend(prices::Matrix{Float64}; n::Int=7, mult::Float64=3.0) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=7` (ATR lookback period), `mult=3.0` (ATR multiplier for band width) |
| Output columns | `Supertrend_Value`, `Supertrend_Direction` |

```julia
Supertrend(ts)                     # defaults: n=7, mult=3.0
Supertrend(ts; n=10, mult=2.0)    # tighter bands
```

**Notes**:
- Direction: `1.0` = uptrend (lower band active), `-1.0` = downtrend (upper band active).
- Bands are computed from Typical Price +/- mult * ATR, with a state machine that locks bands to the previous value when price stays within range.
- Created by Olivier Seban.

**See Also**: [`ATR`](#atr), [`ParabolicSAR`](#parabolicsar), [`DMI`](#dmi)

---

## Momentum Indicators

### CCI

**Commodity Channel Index** -- a momentum oscillator measuring deviation of Typical Price from its statistical mean.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `CCI(prices::Matrix{Float64}; n::Int=20) -> Vector{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=20` (lookback for SMA and Mean Absolute Deviation) |
| Output columns | `CCI_n` |

```julia
CCI(ts)                # defaults: n=20
CCI(ts; n=14)          # shorter period
```

**Notes**:
- CCI = (TP - SMA(TP)) / (0.015 * MAD). The 0.015 constant ensures ~70-80% of values fall between -100 and +100.
- CCI > +100 signals overbought / strong uptrend; CCI < -100 signals oversold / strong downtrend.
- For bars before the full window is available, a partial window is used. When MAD = 0, CCI = 0.
- Created by Donald Lambert (1980).

**See Also**: [`RSI`](#rsi), [`ROC`](#roc), [`MFI`](#mfi)

---

### DPO

**Detrended Price Oscillator** -- removes the trend component from prices to highlight underlying cycles.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `DPO(prices::Vector{Float64}; n::Int=20) -> Vector{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=20` (SMA period) |
| Output columns | `DPO_n` |

```julia
DPO(ts)                # defaults: n=20
DPO(ts; n=14)          # shorter cycle detection
```

**Notes**:
- Formula: `DPO[t] = Price[t] - SMA(n)[t - shift]` where `shift = floor(n/2) + 1`.
- During the startup period (first `shift` elements), values are `0.0`.
- Positive DPO means price is above the lagged MA; negative means below.
- Useful for identifying overbought/oversold conditions within price cycles.

**See Also**: [`SMA`](#sma), [`ROC`](#roc)

---

### KST

**Know Sure Thing** -- a momentum oscillator based on smoothed rate-of-change across four timeframes, weighted to emphasize longer cycles.

| Property | Value |
|----------|-------|
| Type | SIMO |
| Raw signature | `KST(prices::Vector{Float64}; r1::Int=10, r2::Int=13, r3::Int=15, r4::Int=20, s1::Int=10, s2::Int=13, s3::Int=15, s4::Int=20, signal::Int=9) -> Matrix{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `r1=10` (ROC period 1), `r2=13` (ROC period 2), `r3=15` (ROC period 3), `r4=20` (ROC period 4), `s1=10` (SMA smoothing 1), `s2=13` (SMA smoothing 2), `s3=15` (SMA smoothing 3), `s4=20` (SMA smoothing 4), `signal=9` (signal line SMA) |
| Output columns | `KST_Line`, `KST_Signal` |

```julia
KST(ts)                # all defaults
KST(ts; r1=10, r2=15, r3=20, r4=30, signal=9)  # custom ROC periods
```

**Notes**:
- KST = 1*SMA(ROC1) + 2*SMA(ROC2) + 3*SMA(ROC3) + 4*SMA(ROC4). Longer-term ROC components receive higher weights.
- KST crossing above the signal line is a bullish signal; crossing below is bearish.
- Created by Martin Pring.

**See Also**: [`ROC`](#roc), [`MACD`](#macd), [`PPO`](#ppo)

---

### MACD

**Moving Average Convergence Divergence** -- a trend-following momentum indicator based on EMA differences.

| Property | Value |
|----------|-------|
| Type | SIMO |
| Raw signature | `MACD(prices::Vector{Float64}; fast::Int=12, slow::Int=26, signal::Int=9) -> Matrix{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `fast=12` (fast EMA period), `slow=26` (slow EMA period), `signal=9` (signal line EMA period) |
| Output columns | `MACD_Line`, `MACD_Signal`, `MACD_Histogram` |

```julia
MACD(ts)                                   # defaults: fast=12, slow=26, signal=9
MACD(ts; fast=8, slow=21, signal=5)        # custom parameters
```

**See Also**: [`EMA`](#ema), [`PPO`](#ppo), [`MACD3`](#macd3), [`RSI`](#rsi)

---

### MACD3

**Triple MACD** -- a three-line MACD variant using fast, middle, and slow moving averages with ALMA smoothing.

| Property | Value |
|----------|-------|
| Type | SIMO |
| Raw signature | `MACD3(prices::Vector{Float64}; fast::Int=5, middle::Int=20, slow::Int=40, ma_type::Symbol=:EMA) -> Matrix{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `fast=5`, `middle=20`, `slow=40`, `ma_type=:EMA` (`:EMA`, `:HAJ`, `:JAK`, `:KAMA`, `:ALMA`) |
| Output columns | `MACD3_Fast`, `MACD3_Middle`, `MACD3_Slow` |

The `ma_type` parameter selects the MA combination:

| `ma_type` | Fast MA | Middle MA | Slow MA |
|-----------|---------|-----------|---------|
| `:EMA` (default) | EMA | EMA | EMA |
| `:HAJ` | HMA | ALMA | JMA |
| `:JAK` | JMA | ALMA | KAMA |
| `:KAMA` | KAMA | KAMA | KAMA |
| `:ALMA` | ALMA | ALMA | ALMA |

All output lines are smoothed with `ALMA(n=4, offset=0.9)`.

```julia
MACD3(ts)                                              # defaults
MACD3(ts; fast=10, middle=30, slow=50, ma_type=:HAJ)   # custom MA combination
```

**See Also**: [`MACD`](#macd), [`EMA`](#ema), [`ALMA`](#alma), [`HMA`](#hma)

---

### PPO

**Percentage Price Oscillator** -- a percentage-normalized version of MACD, enabling cross-asset comparison.

| Property | Value |
|----------|-------|
| Type | SIMO |
| Raw signature | `PPO(prices::Vector{Float64}; fast::Int=12, slow::Int=26, signal::Int=9) -> Matrix{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `fast=12` (fast EMA period), `slow=26` (slow EMA period), `signal=9` (signal line EMA period) |
| Output columns | `PPO_Line`, `PPO_Signal`, `PPO_Histogram` |

```julia
PPO(ts)                                    # defaults: fast=12, slow=26, signal=9
PPO(ts; fast=10, slow=21, signal=7)       # custom parameters
```

**Notes**:
- PPO = (EMA_fast - EMA_slow) / EMA_slow * 100. Signal = EMA(PPO). Histogram = PPO - Signal.
- Functionally identical to MACD but expressed as a percentage, making it comparable across securities with different price levels.
- Requires input length >= `slow`.
- Created by Gerald Appel (derived from MACD).

**See Also**: [`MACD`](#macd), [`EMA`](#ema), [`KST`](#kst)

---

### ROC

**Rate of Change** -- measures the percentage change between the current price and the price n periods ago.

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `ROC(prices::Vector{Float64}; n::Int=14) -> Vector{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=14` (lookback period) |
| Output columns | `ROC_n` |

```julia
ROC(ts)                # defaults: n=14
ROC(ts; n=10)          # shorter lookback
```

**Notes**:
- Formula: `ROC[i] = (Price[i] - Price[i-n]) / Price[i-n] * 100`.
- The first n values are `0.0` (startup period).
- If the denominator (past price) is zero, ROC = 0.0.

**See Also**: [`KST`](#kst), [`PPO`](#ppo), [`RSI`](#rsi)

---

### RSI

**Relative Strength Index** -- a momentum oscillator measuring speed and magnitude of price changes (0-100 scale).

| Property | Value |
|----------|-------|
| Type | SISO |
| Raw signature | `RSI(prices::Vector{Float64}; n::Int=14, ma_type::Symbol=:SMMA) -> Vector{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=14` (lookback period), `ma_type=:SMMA` (smoothing type: `:SMMA`, `:EMA`, `:SMA`) |
| Output columns | `RSI_n` |

```julia
RSI(ts)                            # defaults: n=14, ma_type=:SMMA
RSI(ts; n=10, ma_type=:EMA)       # custom parameters
```

**See Also**: [`StochRSI`](#stochrsi), [`SMMA`](#smma), [`MACD`](#macd), [`CCI`](#cci)

---

### StochRSI

**Stochastic RSI** -- applies the Stochastic oscillator formula to RSI values instead of raw prices.

| Property | Value |
|----------|-------|
| Type | SIMO |
| Raw signature | `StochRSI(prices::Vector{Float64}; n::Int=14, k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA) -> Matrix{Float64}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=14` (RSI + stochastic period), `k_smooth=3`, `d_smooth=3`, `ma_type=:SMA` (`:SMA`, `:EMA`, `:SMMA`/`:RMA`, `:WMA`) |
| Output columns | `StochRSI_K`, `StochRSI_D` |

```julia
StochRSI(ts)                                       # defaults
StochRSI(ts; n=21, k_smooth=5, d_smooth=5)         # custom parameters
StochRSI(ts; ma_type=:EMA)                         # EMA smoothing
```

**See Also**: [`RSI`](#rsi), [`Stoch`](#stoch)

---

## Oscillators

### Stoch

**Stochastic Oscillator** -- compares closing price to the high-low range over a lookback period.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `Stoch(prices::Matrix{Float64}; n::Int=14, k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=14` (lookback), `k_smooth=3` (%K smoothing), `d_smooth=3` (%D smoothing), `ma_type=:SMA` |
| Output columns | `Stoch_K`, `Stoch_D` |

```julia
Stoch(ts)                                          # defaults
Stoch(ts; n=21, k_smooth=5, d_smooth=5)            # custom parameters
Stoch(ts; ma_type=:EMA)                            # EMA smoothing
```

**See Also**: [`StochRSI`](#stochrsi), [`WR`](#wr), [`RSI`](#rsi)

---

### WR

**Williams %R (Williams Percent Range)** -- a momentum oscillator measuring overbought/oversold levels (0 to -100 scale).

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `WR(prices::Matrix{Float64}; n::Int=14) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=14` (lookback period) |
| Output columns | `WR_raw`, `WR_EMA` |

```julia
WR(ts)                 # defaults: n=14
WR(ts; n=21)           # custom period
```

**See Also**: [`Stoch`](#stoch), [`RSI`](#rsi)

---

### SqueezeMomentum

**TTM Squeeze Momentum** -- a volatility and momentum indicator combining Bollinger Bands, Keltner Channels, and linear regression momentum.

| Property | Value |
|----------|-------|
| Type | MIMO |
| Raw signature | `SqueezeMomentum(prices::Matrix{Float64}; n::Int=20, bb_mult::Float64=2.0, kc_mult::Float64=1.5) -> Matrix{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=20` (period for BB, KC, rolling high/low, EMA, and linear regression, must be >= 2), `bb_mult=2.0` (BB standard deviation multiplier), `kc_mult=1.5` (KC ATR multiplier) |
| Output columns | `SqueezeMomentum_Histogram`, `SqueezeMomentum_Squeeze` |

```julia
SqueezeMomentum(ts)                                    # defaults
SqueezeMomentum(ts; n=20, bb_mult=2.0, kc_mult=1.5)  # explicit defaults
```

**Notes**:
- Squeeze = `1.0` when BB is inside KC (low volatility, potential breakout imminent); `0.0` when BB expands beyond KC.
- Histogram: linear regression fitted value of momentum, where momentum = Close - (midpoint of rolling HH/LL + EMA(Close)) / 2.
- Positive histogram = upward momentum. Histogram color change (increasing/decreasing) signals momentum shifts.
- Created by John Carter (TTM Squeeze).

**See Also**: [`BB`](#bb), [`KeltnerChannel`](#keltnerchannel), [`EMA`](#ema)

---

## Volume Indicators

### ADL

**Accumulation/Distribution Line** -- a cumulative volume-weighted indicator measuring money flow.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `ADL(prices::Matrix{T}) where T <: AbstractFloat -> Vector{T}` |
| Input fields | `[:High, :Low, :Close, :Volume]` (configurable via `fields`) |
| Parameters | *(none)* |
| Output columns | `ADL` |

```julia
ADL(ts)                # no parameters needed
```

**See Also**: [`OBV`](#obv), [`ChaikinOsc`](#chaikinosc), [`CMF`](#cmf)

---

### ChaikinOsc

**Chaikin Oscillator** -- momentum indicator derived from the difference of two EMAs of the ADL.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `ChaikinOsc(prices::Matrix{Float64}; fast::Int=3, slow::Int=10) -> Vector{Float64}` |
| Input fields | `[:High, :Low, :Close, :Volume]` (configurable via `fields`) |
| Parameters | `fast=3` (fast EMA period), `slow=10` (slow EMA period) |
| Output columns | `ChaikinOsc` |

```julia
ChaikinOsc(ts)                     # defaults: fast=3, slow=10
ChaikinOsc(ts; fast=5, slow=20)    # custom parameters
```

**See Also**: [`ADL`](#adl), [`OBV`](#obv), [`CMF`](#cmf), [`EMA`](#ema)

---

### CMF

**Chaikin Money Flow** -- a volume-weighted indicator measuring buying and selling pressure over a rolling window.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `CMF(prices::Matrix{Float64}; n::Int=20) -> Vector{Float64}` |
| Input fields | `[:High, :Low, :Close, :Volume]` (configurable via `fields`) |
| Parameters | `n=20` (lookback period for rolling sum) |
| Output columns | `CMF_n` |

```julia
CMF(ts)                # defaults: n=20
CMF(ts; n=10)          # shorter lookback
```

**Notes**:
- Oscillates between -1 and +1.
- CMF = Sum(CLV * Volume, n) / Sum(Volume, n), where CLV = (2*Close - High - Low) / (High - Low).
- CMF > 0 indicates buying pressure (accumulation); CMF < 0 indicates selling pressure (distribution).
- When High == Low, CLV = 0. When sum of Volume is 0, CMF = 0.
- Created by Marc Chaikin.

**See Also**: [`ADL`](#adl), [`ChaikinOsc`](#chaikinosc), [`MFI`](#mfi)

---

### EMV

**Ease of Movement** -- a volume-weighted momentum indicator that relates the magnitude of price change to volume.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `EMV(prices::Matrix{Float64}; n::Int=14) -> Vector{Float64}` |
| Input fields | `[:High, :Low, :Volume]` (configurable via `fields`) |
| Parameters | `n=14` (SMA smoothing period) |
| Output columns | `EMV_n` |

```julia
EMV(ts)                # defaults: n=14
EMV(ts; n=20)          # longer smoothing
```

**Notes**:
- EMV = Distance Moved / Box Ratio, where Distance Moved = midpoint change, Box Ratio = (Volume / 10^8) / (High - Low).
- The raw EMV is smoothed by SMA(n).
- Positive EMV: price moving up on low volume (easy upward movement). Negative EMV: price moving down on low volume.
- When High == Low, raw EMV = 0.
- Created by Richard W. Arms Jr.

**See Also**: [`OBV`](#obv), [`ADL`](#adl), [`ForceIndex`](#forceindex)

---

### ForceIndex

**Force Index** -- a volume-weighted momentum indicator that measures the force behind price movements using EMA smoothing.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `ForceIndex(data::Matrix{Float64}; n::Int=13) -> Vector{Float64}` |
| Input fields | `[:Close, :Volume]` (configurable via `fields`) |
| Parameters | `n=13` (EMA smoothing period) |
| Output columns | `ForceIndex_n` |

```julia
ForceIndex(ts)                 # defaults: n=13
ForceIndex(ts; n=2)            # short-term entry timing
```

**Notes**:
- Raw Force = (Close[t] - Close[t-1]) * Volume[t], then smoothed by EMA(n).
- Positive: buyers in control. Negative: sellers in control. Zero crossing: potential trend change.
- Short period (n=2) identifies short-term pressure; long period (n=13) confirms broader trends.
- Created by Alexander Elder.

**See Also**: [`OBV`](#obv), [`EMA`](#ema), [`EMV`](#emv)

---

### MFI

**Money Flow Index** -- a volume-weighted momentum oscillator (0-100) measuring buying and selling pressure, often called "volume-weighted RSI".

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `MFI(prices::Matrix{Float64}; n::Int=14) -> Vector{Float64}` |
| Input fields | `[:High, :Low, :Close, :Volume]` (configurable via `fields`) |
| Parameters | `n=14` (lookback period for rolling money flow sum) |
| Output columns | `MFI_n` |

```julia
MFI(ts)                # defaults: n=14
MFI(ts; n=20)          # longer lookback
```

**Notes**:
- Range [0, 100]. Overbought >= 80. Oversold <= 20.
- MFI = 100 - 100 / (1 + Positive MF Sum / Negative MF Sum), where MF = Typical Price * Volume.
- Positive/negative classification is based on whether Typical Price increased or decreased vs. the previous bar.
- When Negative MF sum is 0, MFI = 100; when Positive MF sum is 0, MFI = 0.
- Created by Gene Quong and Avrum Soudack.

**See Also**: [`RSI`](#rsi), [`CMF`](#cmf), [`ADL`](#adl)

---

### NVI

**Negative Volume Index** -- a cumulative indicator that tracks price changes only on days when volume decreases, reflecting "smart money" activity.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `NVI(data::Matrix{Float64}) -> Vector{Float64}` |
| Input fields | `[:Close, :Volume]` (configurable via `fields`) |
| Parameters | *(none)* |
| Output columns | `NVI` |

```julia
NVI(ts)                # starts at 1000.0
```

**Notes**:
- Starting value is 1000.0 (conventional).
- NVI updates only when today's volume < yesterday's volume: `NVI[t] = NVI[t-1] * (1 + pct_change)`.
- Rising NVI suggests smart money is buying (bullish). Often used with a 255-day EMA for signal generation.
- Created by Paul Dysart (1930s), popularized by Norman Fosback.

**See Also**: [`PVI`](#pvi), [`OBV`](#obv)

---

### OBV

**On Balance Volume** -- a cumulative volume-based indicator measuring buying and selling pressure.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `OBV(data::Matrix{Float64}) -> Vector{Float64}` |
| Input fields | `[:Close, :Volume]` (configurable via `fields`) |
| Parameters | *(none)* |
| Output columns | `OBV` |

```julia
OBV(ts)                # no parameters needed
```

**See Also**: [`ADL`](#adl), [`ChaikinOsc`](#chaikinosc), [`VPT`](#vpt)

---

### PVI

**Positive Volume Index** -- a cumulative indicator that tracks price changes only on days when volume increases, reflecting "crowd" activity.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `PVI(data::Matrix{Float64}) -> Vector{Float64}` |
| Input fields | `[:Close, :Volume]` (configurable via `fields`) |
| Parameters | *(none)* |
| Output columns | `PVI` |

```julia
PVI(ts)                # starts at 1000.0
```

**Notes**:
- Starting value is 1000.0 (conventional).
- PVI updates only when today's volume > yesterday's volume: `PVI[t] = PVI[t-1] * (1 + pct_change)`.
- PVI is the complement of NVI; together they separate smart money from crowd behavior.
- When PVI is below its moving average, the market is considered bearish.
- Created by Paul Dysart (1930s), popularized by Norman Fosback.

**See Also**: [`NVI`](#nvi), [`OBV`](#obv)

---

### VPT

**Volume Price Trend** -- a cumulative indicator that relates volume to the magnitude of price change (unlike OBV which only considers direction).

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `VPT(data::Matrix{Float64}) -> Vector{Float64}` |
| Input fields | `[:Close, :Volume]` (configurable via `fields`) |
| Parameters | *(none)* |
| Output columns | `VPT` |

```julia
VPT(ts)                # no parameters needed
```

**Notes**:
- VPT[t] = VPT[t-1] + Volume[t] * (Close[t] - Close[t-1]) / Close[t-1]. First value is 0.0.
- Unlike OBV, VPT weighs volume by the magnitude of price change, making it more proportional.
- Rising VPT supports the trend; divergence from price can signal reversals.

**See Also**: [`OBV`](#obv), [`ADL`](#adl), [`NVI`](#nvi)

---

### VWAP

**Volume Weighted Average Price** -- a cumulative indicator that weights the Typical Price by volume, representing the true average price paid.

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `VWAP(data::Matrix{Float64}) -> Vector{Float64}` |
| Input fields | `[:High, :Low, :Close, :Volume]` (configurable via `fields`) |
| Parameters | *(none)* |
| Output columns | `VWAP` |

```julia
VWAP(ts)               # no parameters needed
```

**Notes**:
- VWAP = Cumulative(TP * Volume) / Cumulative(Volume), where TP = (High + Low + Close) / 3.
- Price above VWAP suggests bullish sentiment; below suggests bearish.
- Commonly used by institutional traders for execution benchmarking.
- This implementation is cumulative across the entire series (not session-reset).

**See Also**: [`OBV`](#obv), [`ADL`](#adl), [`MFI`](#mfi)

---

## Volatility Indicators

### ATR

**Average True Range** -- measures the average range of price movement (volatility).

| Property | Value |
|----------|-------|
| Type | MISO |
| Raw signature | `ATR(prices::Matrix{Float64}; n::Int=14, ma_type::Symbol=:EMA) -> Vector{Float64}` |
| Input fields | `[:High, :Low, :Close]` (configurable via `fields`) |
| Parameters | `n=14` (smoothing period), `ma_type=:EMA` (`:SMA`, `:EMA`, `:SMMA`/`:RMA`) |
| Output columns | `ATR_n` |

```julia
ATR(ts)                            # defaults: n=14, ma_type=:EMA
ATR(ts; n=21, ma_type=:SMA)       # custom parameters
```

Also provides an internal `TR(prices::Matrix{Float64})` function for True Range calculation (not exported).

**See Also**: [`BB`](#bb), [`KeltnerChannel`](#keltnerchannel), [`Supertrend`](#supertrend)

---

### BB

**Bollinger Bands** -- volatility bands placed above and below a moving average.

| Property | Value |
|----------|-------|
| Type | SIMO |
| Raw signature | `BB(prices::Vector{T}; n::Int=14, num_std::Float64=2.0, ma_type::Symbol=:SMA) where T -> Matrix{T}` |
| Input field | `:Close` (configurable via `field`) |
| Parameters | `n=14` (period), `num_std=2.0` (standard deviations for band width), `ma_type=:SMA` (`:SMA`, `:EMA`, `:SMMA`) |
| Output columns | `BB_Center`, `BB_Upper`, `BB_Lower` |

```julia
BB(ts)                                     # defaults: n=14, num_std=2.0, ma_type=:SMA
BB(ts; n=20, num_std=2.0)                  # standard Bollinger Bands (n=20)
BB(ts; n=20, num_std=3.0, ma_type=:EMA)   # wide bands with EMA
```

**See Also**: [`SMA`](#sma), [`EMA`](#ema), [`ATR`](#atr), [`KeltnerChannel`](#keltnerchannel)

---

## Indicator Relationships

The following diagram shows how indicators relate to and build upon each other:

```
SMA ─────────────────────── TMA (= SMA of SMA)
 |                           (alias: TRIMA)
 |
EMA ──┬── DEMA (= 2*EMA - EMA(EMA))
 |    ├── TEMA (= 3*(EMA-EMA2) + EMA3)
 |    ├── T3 (= weighted sum of 6 cascaded EMAs)
 |    └── ZLEMA (= EMA of de-lagged prices)
 |
WMA ──┬── HMA (= WMA(sqrt(n)) of 2*WMA(n/2) - WMA(n))
 |
SMMA ─── (alias: RMA)
 |
 ├── RSI (uses apply_ma for gain/loss smoothing)
 |    └── StochRSI (Stochastic of RSI values)
 |
 ├── ATR (apply_ma of True Range)
 |    ├── KeltnerChannel (MA +/- mult*ATR)
 |    └── Supertrend (TP +/- mult*ATR with state machine)
 |
 ├── DMI (SMMA of +DM/-DM/TR/DX -> +DI/-DI/ADX)
 |
ALMA ─── MACD3 (ALMA smoothing of MA differences)
 |
KAMA ─── (adaptive MA via Efficiency Ratio)
JMA  ─── (triple adaptive filter)

MACD ─── (EMA(fast) - EMA(slow), Signal, Histogram)
PPO  ─── (MACD as percentage of slow EMA)
ROC  ─── (percentage price change over n periods)
 └── KST (weighted sum of 4 smoothed ROCs)
DPO  ─── (price minus lagged SMA)
CCI  ─── (deviation from mean / MAD)

ADL ──── ChaikinOsc (= EMA(fast)(ADL) - EMA(slow)(ADL))
     └── CMF (rolling CLV * Volume / Volume)
OBV ──── (cumulative volume by price direction)
VPT ──── (cumulative volume weighted by price change)
NVI/PVI ─ (price change on decreasing/increasing volume days)
VWAP ─── (cumulative TP*Volume / Volume)
MFI  ─── (volume-weighted RSI using Money Flow)
ForceIndex ── (EMA of price-change * volume)
EMV  ─── (SMA of distance moved / box ratio)

Stoch ── (MIMO: %K and %D from High/Low/Close)
WR ───── (MIMO: Williams %R from High/Low/Close)
BB ───── (SIMO: Center/Upper/Lower bands)
 └── SqueezeMomentum (BB inside KC detection + linreg momentum)

DonchianChannel ── (rolling highest high / lowest low)
Aroon ──────────── (bars since highest high / lowest low)
ParabolicSAR ───── (accelerating stop-and-reverse)
Ichimoku ────────── (5-component cloud: Tenkan/Kijun/SenkouA/SenkouB/Chikou)
```

---

## Input Field Requirements

| Required Columns | Indicators |
|-----------------|------------|
| `:Close` only | SMA, EMA, DEMA, TEMA, T3, WMA, HMA, ZLEMA, SMMA, KAMA, JMA, ALMA, RSI, StochRSI, MACD, MACD3, BB, ROC, DPO, PPO, KST |
| `:Close`, `:Volume` | OBV, ForceIndex, NVI, PVI, VPT |
| `:High`, `:Low` | Aroon, ParabolicSAR |
| `:High`, `:Low`, `:Close` | ATR, Stoch, WR, DonchianChannel, KeltnerChannel, Supertrend, DMI, Ichimoku, SqueezeMomentum, CCI |
| `:High`, `:Low`, `:Volume` | EMV |
| `:High`, `:Low`, `:Close`, `:Volume` | ADL, ChaikinOsc, CMF, MFI, VWAP |

---

## Parameter Types Quick Reference

| Parameter | Type | Common Values | Used By |
|-----------|------|---------------|---------|
| `n` | `Int` | 7, 10, 14, 20, 50, 200 | Most indicators |
| `field` | `Symbol` | `:Close`, `:Volume` | All SISO/SIMO indicators |
| `fields` | `Vector{Symbol}` | `[:High, :Low, :Close]` | All MISO/MIMO indicators |
| `ma_type` | `Symbol` | `:SMA`, `:EMA`, `:SMMA`, `:RMA`, `:WMA` | RSI, ATR, BB, Stoch, StochRSI, KeltnerChannel, MACD3 |
| `fast` / `slow` | `Int` | 2-30 | MACD, MACD3, ChaikinOsc, KAMA, PPO |
| `signal` | `Int` | 9 | MACD, PPO, KST |
| `k_smooth` / `d_smooth` | `Int` | 3 | Stoch, StochRSI |
| `num_std` | `Float64` | 1.0, 2.0, 3.0 | BB |
| `offset` | `Float64` | 0.85 | ALMA |
| `sigma` | `Float64` | 6.0 | ALMA |
| `phase` | `Float64` | -100.0 to 100.0 | JMA |
| `a` | `Float64` | 0.7 | T3 |
| `middle` | `Int` | 20 | MACD3 |
| `mult` | `Float64` | 1.5, 2.0, 3.0 | KeltnerChannel, Supertrend |
| `bb_mult` / `kc_mult` | `Float64` | 1.5, 2.0 | SqueezeMomentum |
| `af_start` / `af_step` / `af_max` | `Float64` | 0.02, 0.02, 0.20 | ParabolicSAR |
| `tenkan` / `kijun` / `senkou_b` | `Int` | 9, 26, 52 | Ichimoku |
| `displacement` | `Int` | 26 | Ichimoku |
| `r1`-`r4` / `s1`-`s4` | `Int` | 10, 13, 15, 20 | KST |
