# Foxtail

> **Fi**nancial **O**bservation and e**X**ploration **T**echnical **A**nalysis **I**ndicators **L**ibrary

Foxtail is a high-performance library for technical analysis indicators. It achieves exceptional speed by implementing incremental calculations for each indicator. Currently, the time series data input/output is dependent on TSFrames.

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

-   Moving Average
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

## Acknowledgments

The implementation is heavily influenced by:

-   [`tailpp`](https://github.com/nardew/talipp)
-   [`OnlineTechnicalIndicators.jl`](https://github.com/femtotrader/OnlineTechnicalIndicators.jl) (Julia translation of tailpp)
-   The Circular Buffer implementation references the design patterns from [`DataStructures.jl`](https://juliacollections.github.io/DataStructures.jl/stable/).
