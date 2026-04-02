# Foxtail.jl

> **Fi**nancial **O**bservation and e**X**ploration **T**echnical **A**nalysis **I**ndicators **L**ibrary

A high-performance Julia library for technical analysis indicators using **online (streaming) algorithms**. Designed for use with [TSFrames.jl](https://github.com/xKDR/TSFrames.jl) time series data.

## Features

- **50 technical indicators** across 7 categories (moving averages, trend, momentum, oscillators, volume, volatility, pivot points)
- **Online algorithm design** -- incremental computation using circular buffers for O(1) per-bar updates
- **TSFrames integration** -- accepts `TSFrame` input and returns properly named `TSFrame` output
- **4,100+ tests** with comprehensive edge case coverage
- **Zero external API dependencies** -- pure computation from OHLCV data

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/takaymmt/Foxtail.jl")
```

## Quick Start

```julia
using Foxtail, TSFrames, DataFrames, Dates

# Create sample time series
dates = Date(2020,1,1):Day(1):Date(2024,12,31)
n = length(dates)
ts = TSFrame(DataFrame(
    Index  = dates,
    Open   = cumsum(randn(n)) .+ 100,
    High   = cumsum(randn(n)) .+ 102,
    Low    = cumsum(randn(n)) .+ 98,
    Close  = cumsum(randn(n)) .+ 100,
    Volume = abs.(randn(n)) .* 1e6
))

# Moving Averages
sma = SMA(ts; n=200)
ema = EMA(ts; n=50)

# Trend
supertrend = Supertrend(ts; n=7, mult=3.0)
ichimoku   = Ichimoku(ts)

# Momentum & Oscillators
rsi  = RSI(ts; n=14)
macd = MACD(ts; fast=12, slow=26, signal=9)

# Volume
vwap = VWAP(ts)
obv  = OBV(ts)

# Volatility
bb  = BB(ts; n=20, num_std=2.0)
atr = ATR(ts; n=14)

# Pivot Points (5 methods: Classic, Fibonacci, Woodie, Camarilla, DeMark)
pivots = PivotPoints(ts; method=:Classic)
```

## Supported Indicators

### Moving Averages (13)

| Indicator | Description |
|-----------|-------------|
| ALMA | Arnaud Legoux Moving Average |
| DEMA | Double Exponential Moving Average |
| EMA | Exponential Moving Average |
| HMA | Hull Moving Average |
| JMA | Jurik Moving Average |
| KAMA | Kaufman Adaptive Moving Average |
| SMA | Simple Moving Average |
| SMMA | Smoothed Moving Average (Wilder's / RMA) |
| T3 | Tillson T3 Moving Average |
| TEMA | Triple Exponential Moving Average |
| TMA | Triangular Moving Average (TRIMA) |
| WMA | Weighted Moving Average |
| ZLEMA | Zero-Lag Exponential Moving Average |

### Trend Indicators (8)

| Indicator | Description |
|-----------|-------------|
| Aroon | Aroon Up/Down/Oscillator |
| DMI | Directional Movement Index / ADX |
| DonchianChannel | Donchian Channel (Breakout Bands) |
| Ichimoku | Ichimoku Cloud (Kinko Hyo) |
| KeltnerChannel | Keltner Channel (ATR Envelopes) |
| ParabolicSAR | Parabolic Stop and Reverse |
| Supertrend | ATR-based Trend Following |
| Vortex | Vortex Indicator (VI+/VI-) |

### Momentum Indicators (10)

| Indicator | Description |
|-----------|-------------|
| CCI | Commodity Channel Index |
| ConnorsRSI | Connors RSI (3-component composite) |
| DPO | Detrended Price Oscillator |
| KST | Know Sure Thing |
| MACD | Moving Average Convergence Divergence |
| MACD3 | Triple MACD |
| PPO | Percentage Price Oscillator |
| ROC | Rate of Change |
| RSI | Relative Strength Index |
| StochRSI | Stochastic RSI |

### Oscillators (4)

| Indicator | Description |
|-----------|-------------|
| Stoch | Stochastic Oscillator |
| UltimateOscillator | Ultimate Oscillator (3-timeframe) |
| WR | Williams %R |
| SqueezeMomentum | TTM Squeeze Momentum |

### Volume Indicators (11)

| Indicator | Description |
|-----------|-------------|
| ADL | Accumulation/Distribution Line |
| ChaikinOsc | Chaikin Oscillator |
| CMF | Chaikin Money Flow |
| EMV | Ease of Movement |
| ForceIndex | Force Index |
| MFI | Money Flow Index |
| NVI | Negative Volume Index |
| OBV | On Balance Volume |
| PVI | Positive Volume Index |
| VPT | Volume Price Trend |
| VWAP | Volume Weighted Average Price |

### Volatility Indicators (3)

| Indicator | Description |
|-----------|-------------|
| ATR | Average True Range |
| BB | Bollinger Bands |
| MassIndex | Mass Index (Reversal Bulge Detection) |

### Pivot Points (1)

| Indicator | Description |
|-----------|-------------|
| PivotPoints | Pivot Points (Classic / Fibonacci / Woodie / Camarilla / DeMark) |

## Documentation

For detailed API signatures, parameters, formulas, and usage examples, see the [Indicator Reference](docs/indicator-reference.md).

## Acknowledgments

The implementation is heavily influenced by:

- [`talipp`](https://github.com/nardew/talipp)
- [`OnlineTechnicalIndicators.jl`](https://github.com/femtotrader/OnlineTechnicalIndicators.jl) (Julia translation of talipp)
- The Circular Buffer implementation references the design patterns from [`DataStructures.jl`](https://juliacollections.github.io/DataStructures.jl/stable/).
