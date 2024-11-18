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

## Support Indicators

### Momentum Indicators

-   MACD (Moving Average Convergence Divergence)
    -   MACD3
-   RSI (Relative Strength Index)
-   Stochastic
-   StochasticRSI
-   Williams %R

ToDos

-   DMI (Directional Movement Index) / ADX ★★★
-   CCI (Commodity Channel Index) ★★★
-   MFI (Money Flow Index) ★★★
-   ROC (Rate of Change) ★★
-   Ultimate Oscillator ★★
-   PPO (Percentage Price Oscillator) ★★
-   CMF (Chaikin Money Flow) ★★
-   DPO (Detrended Price Oscillator) ★
-   KST (Know Sure Thing) ★

### Volume Indicators

-   ADL (Accumulation/Distribution Line)
-   Chaikin Oscillator
-   OBV (On Balance Volume)

ToDos

-   VWAP (Volume Weighted Average Price) ★★★
-   Force Index ★★
-   EMV (Ease of Movement) ★★
-   VWP (Volume Price Trend) ★★
-   NVI/PVI (Negative/Positive Volume Index) ★

### Volatility Indicators

-   ATR (Average True Range)
-   Bollinger Bands

ToDos

-   Keltner Channel ★★★
-   Donchian Channel ★★★
-   VIX (Volatility Index calculation) ★★
-   Mass Index ★

### Trending Indicators

ToDos

-   Ichimoku Cloud ★★★
-   Parabolic SAR ★★★
-   Supertrend ★★★
-   ADX (Average Directional Index) ★★★
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

### Price Action Patterns (just memo, not intended to be implemented)

-   Pivot Points (Standard/Fibonacci/Woodie/Camarilla) ★★★
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
