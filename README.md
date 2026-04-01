# Foxtail

> **Fi**nancial **O**bservation and e**X**ploration **T**echnical **A**nalysis **I**ndicators **L**ibrary

Foxtail is a high-performance library for technical analysis indicators using the online algorithm. Currently, the time series data input/output is dependent on TSFrames.

## Prerequisites

-   TSFrames

## Getting Started

```julia
using Foxtail, TSFrames, DataFrames, Dates

ts = TSFrame(DataFrame(Index=Date(2024,1,1):Date(2024,1,20), Close=collect(1.0:20.0)))

d = Date(1980,1,1):Date(2024,12,31)
ts = TSFrame(DataFrame(Index=d, Close=rand(length(d))*250))

sma = SMA(ts, 200)
ema = EMA(ts, 50)
```

## Priority Legend

| Stars | Priority |
|-------|----------|
| ★★★★★ | Critical — high market impact, implement immediately |
| ★★★★  | High — widely used, strong practical value |
| ★★★   | Medium — standard indicator, useful to have |
| ★★    | Low — niche or derivative use cases |
| ★     | Minimal — rarely used in practice |

## Support Indicators

### Momentum Indicators

-   MACD (Moving Average Convergence Divergence)
    -   MACD3
-   RSI (Relative Strength Index)
-   Stochastic
-   StochasticRSI
-   Williams %R

ToDos (not implemented yet)

-   DMI (Directional Movement Index) / ADX ★★★★★ — universal trend strength filter; used in nearly all professional strategies as a signal validator (`ADX > 25` threshold)
-   CCI (Commodity Channel Index) ★★★
-   MFI (Money Flow Index) ★★★
-   Connors RSI ★★★ — 3-component RSI composite (RSI + Streak RSI + %Rank); favored by systematic short-term traders
-   ROC (Rate of Change) ★★★ — core momentum measure for factor investing and screening
-   KST (Know Sure Thing) ★★ — depends on ROC
-   PPO (Percentage Price Oscillator) ★★
-   CMF (Chaikin Money Flow) ★★
-   Ultimate Oscillator ★★
-   DPO (Detrended Price Oscillator) ★

### Volume Indicators

-   ADL (Accumulation/Distribution Line)
-   Chaikin Oscillator
-   OBV (On Balance Volume)

ToDos (not implemented yet)

-   VWAP (Volume Weighted Average Price) ★★★★★ — the primary institutional execution benchmark; institutional algorithms defend VWAP creating self-fulfilling support/resistance levels
-   Anchored VWAP ★★★ — VWAP from a user-defined anchor point (e.g., earnings date); growing institutional adoption
-   Force Index ★★
-   VPT (Volume Price Trend) ★★
-   EMV (Ease of Movement) ★★
-   NVI/PVI (Negative/Positive Volume Index) ★

### Volatility Indicators

-   ATR (Average True Range)
-   Bollinger Bands

ToDos (not implemented yet)

-   Keltner Channel ★★★★ — prerequisite for Squeeze Momentum (TTM Squeeze); easy to implement (EMA + ATR already available)
-   Donchian Channel ★★★★ — foundation of breakout systems; used by Turtle Traders and systematic quant funds
-   Squeeze Momentum (TTM Squeeze) ★★★★ — TradingView's most-liked community indicator (76K+ likes); detects volatility compression before breakouts; requires Keltner Channel + Bollinger Bands
-   Mass Index ★

### Trending Indicators

ToDos (not implemented yet)

-   Supertrend ★★★★★ — one of TradingView's most popular indicators; trend-following with dynamic ATR-based stops; easy to implement
-   Ichimoku Cloud ★★★★★ — defines market structure for millions of traders; dominant in JPY-pair and Asian markets
-   Parabolic SAR ★★★★ — classic stop-and-reverse trend indicator; universal stop placement tool
-   ADX (Average Directional Index) ★★★★★ — same as DMI/ADX above
-   Aroon Indicator ★★
-   Vortex Indicator ★★

### Moving Averages

-   ALMA
-   DEMA
-   EMA
-   HMA
-   JMA (Jurik MA)
-   KAMA (Kaufman's Adaptive MA)
-   SMA
-   SMMA (RMA)
-   T3
-   TEMA
-   TMA (TRIMA)
-   WMA
-   ZLEMA

### Pivot Points

ToDos (not implemented yet)

-   Pivot Points (Standard/Fibonacci/Woodie/Camarilla/DM) ★★★★ — strongest self-fulfilling prophecy effect: all market participants calculate identical levels from the same prior-period OHLC formula; widely embedded in trading platform algorithms

### Price Action Patterns (just memo, not intended to be implemented)

-   Support/Resistance Levels ★★★
-   Fibonacci Retracement/Extension ★★★
-   Price Channels ★★

### Experimental/Advanced (just memo, not intended to be implemented)

-   Ehlers Indicators (Cyber Cycle, Roofing Filter) ★★
-   Hurst Exponent ★★
-   Fractal Dimension Index ★
-   Ehlers Fisher Transform ★

## Acknowledgments

The implementation is heavily influenced by:

-   [`tailpp`](https://github.com/nardew/talipp)
-   [`OnlineTechnicalIndicators.jl`](https://github.com/femtotrader/OnlineTechnicalIndicators.jl) (Julia translation of tailpp)
-   The Circular Buffer implementation references the design patterns from [`DataStructures.jl`](https://juliacollections.github.io/DataStructures.jl/stable/).
