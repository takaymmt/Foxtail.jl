# Foxtail.jl Indicator Reference

Complete reference for all 24 technical indicators in Foxtail.jl.

## Summary Table

| # | Indicator | Type | Description | Key Parameters | Output Columns |
|---|-----------|------|-------------|----------------|----------------|
| 1 | [ALMA](#alma) | SISO | Arnaud Legoux Moving Average | `n=10`, `offset=0.85`, `sigma=6.0` | `ALMA_n` |
| 2 | [ADL](#adl) | MISO | Accumulation/Distribution Line | *(none)* | `ADL` |
| 3 | [ATR](#atr) | MISO | Average True Range | `n=14`, `ma_type=:EMA` | `ATR_n` |
| 4 | [BB](#bb) | SIMO | Bollinger Bands | `n=14`, `num_std=2.0`, `ma_type=:SMA` | `BB_Center`, `BB_Upper`, `BB_Lower` |
| 5 | [ChaikinOsc](#chaikinosc) | MISO | Chaikin Oscillator | `fast=3`, `slow=10` | `ChaikinOsc` |
| 6 | [DEMA](#dema) | SISO | Double Exponential Moving Average | `n=10` | `DEMA_n` |
| 7 | [EMA](#ema) | SISO | Exponential Moving Average | `n=10` | `EMA_n` |
| 8 | [HMA](#hma) | SISO | Hull Moving Average | `n=10` | `HMA_n` |
| 9 | [JMA](#jma) | SISO | Jurik Moving Average | `n=7`, `phase=0.0` | `JMA_n` |
| 10 | [KAMA](#kama) | SISO | Kaufman Adaptive Moving Average | `n=10`, `fast=2`, `slow=30` | `KAMA_n` |
| 11 | [MACD](#macd) | SIMO | Moving Average Convergence Divergence | `fast=12`, `slow=26`, `signal=9` | `MACD_Line`, `MACD_Signal`, `MACD_Histogram` |
| 12 | [MACD3](#macd3) | SIMO | Triple MACD | `fast=5`, `middle=20`, `slow=40`, `ma_type=:EMA` | `MACD3_Fast`, `MACD3_Middle`, `MACD3_Slow` |
| 13 | [OBV](#obv) | MISO | On Balance Volume | *(none)* | `OBV` |
| 14 | [RSI](#rsi) | SISO | Relative Strength Index | `n=14`, `ma_type=:SMMA` | `RSI_n` |
| 15 | [SMA](#sma) | SISO | Simple Moving Average | `n=14` | `SMA_n` |
| 16 | [SMMA](#smma) | SISO | Smoothed Moving Average (Wilder's) | `n=10` | `SMMA_n` |
| 17 | [Stoch](#stoch) | MIMO | Stochastic Oscillator | `n=14`, `k_smooth=3`, `d_smooth=3`, `ma_type=:SMA` | `Stoch_K`, `Stoch_D` |
| 18 | [StochRSI](#stochrsi) | SIMO | Stochastic RSI | `n=14`, `k_smooth=3`, `d_smooth=3`, `ma_type=:SMA` | `StochRSI_K`, `StochRSI_D` |
| 19 | [T3](#t3) | SISO | Tillson T3 Moving Average | `n=10`, `a=0.7` | `T3_n` |
| 20 | [TEMA](#tema) | SISO | Triple Exponential Moving Average | `n=10` | `TEMA_n` |
| 21 | [TMA](#tma) | SISO | Triangular Moving Average | `n=10` | `TMA_n` |
| 22 | [WMA](#wma) | SISO | Weighted Moving Average | `n=10` | `WMA_n` |
| 23 | [WR](#wr) | MIMO | Williams %R | `n=14` | `WR_raw`, `WR_EMA` |
| 24 | [ZLEMA](#zlema) | SISO | Zero-Lag EMA | `n=10` | `ZLEMA_n` |

**Type legend**: SISO = Single Input Single Output, MISO = Multiple Input Single Output, SIMO = Single Input Multiple Output, MIMO = Multiple Input Multiple Output.

**Column naming**: `_n` in the output column means the column name includes the `n` parameter value at runtime (e.g., `SMA_20` when called with `n=20`). Indicators without `n` use a fixed name.

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

## Momentum Oscillators

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

**See Also**: [`StochRSI`](#stochrsi), [`SMMA`](#smma), [`MACD`](#macd)

---

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

## Trend / Momentum Indicators

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

**See Also**: [`EMA`](#ema), [`RSI`](#rsi), [`MACD3`](#macd3)

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

**See Also**: [`BB`](#bb), [`EMA`](#ema), [`SMMA`](#smma)

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

**See Also**: [`SMA`](#sma), [`EMA`](#ema), [`ATR`](#atr)

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

**See Also**: [`OBV`](#obv), [`ChaikinOsc`](#chaikinosc)

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

**See Also**: [`ADL`](#adl), [`OBV`](#obv), [`EMA`](#ema)

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

**See Also**: [`ADL`](#adl), [`ChaikinOsc`](#chaikinosc)

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
 |
ALMA ─── MACD3 (ALMA smoothing of MA differences)
 |
KAMA ─── (adaptive MA via Efficiency Ratio)
JMA  ─── (triple adaptive filter)

MACD ─── (EMA(fast) - EMA(slow), Signal, Histogram)

ADL ──── ChaikinOsc (= EMA(fast)(ADL) - EMA(slow)(ADL))
OBV ──── (cumulative volume)

Stoch ── (MIMO: %K and %D from High/Low/Close)
WR ───── (MIMO: Williams %R from High/Low/Close)
BB ───── (SIMO: Center/Upper/Lower bands)
```

---

## Input Field Requirements

| Required Columns | Indicators |
|-----------------|------------|
| `:Close` only | SMA, EMA, DEMA, TEMA, T3, WMA, HMA, ZLEMA, SMMA, KAMA, JMA, ALMA, RSI, StochRSI, MACD, MACD3, BB |
| `:Close`, `:Volume` | OBV |
| `:High`, `:Low`, `:Close` | ATR, Stoch, WR |
| `:High`, `:Low`, `:Close`, `:Volume` | ADL, ChaikinOsc |

---

## Parameter Types Quick Reference

| Parameter | Type | Common Values | Used By |
|-----------|------|---------------|---------|
| `n` | `Int` | 7, 10, 14, 20, 50, 200 | Most indicators |
| `field` | `Symbol` | `:Close`, `:Volume` | All SISO/SIMO indicators |
| `fields` | `Vector{Symbol}` | `[:High, :Low, :Close]` | All MISO/MIMO indicators |
| `ma_type` | `Symbol` | `:SMA`, `:EMA`, `:SMMA`, `:RMA`, `:WMA` | RSI, ATR, BB, Stoch, StochRSI, WR, MACD3 |
| `fast` / `slow` | `Int` | 2-30 | MACD, MACD3, ChaikinOsc, KAMA |
| `signal` | `Int` | 9 | MACD |
| `k_smooth` / `d_smooth` | `Int` | 3 | Stoch, StochRSI |
| `num_std` | `Float64` | 1.0, 2.0, 3.0 | BB |
| `offset` | `Float64` | 0.85 | ALMA |
| `sigma` | `Float64` | 6.0 | ALMA |
| `phase` | `Float64` | -100.0 to 100.0 | JMA |
| `a` | `Float64` | 0.7 | T3 |
| `middle` | `Int` | 20 | MACD3 |
