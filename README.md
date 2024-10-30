# Foxtail

> **Fi**nancial **O**bservation and e**X**ploration **T**echnical **A**nalysis **I**ndicators **L**ibrary

Foxtail is a high-performance library for technical analysis indicators. It achieves exceptional speed by implementing incremental calculations for each indicator. Currently, the time series data input/output is dependent on TSFrames.

### Prerequisites

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
    -   DEMA
    -   EMA
    -   HMA
    -   SMA
    -   SMMA (RMA)
    -   T3
    -   TEMA
    -   TMA (TRIMA)
    -   WMA

## Acknowledgments

The implementation is heavily influenced by:

-   [`tailpp`](https://github.com/nardew/talipp)
-   [`OnlineTechnicalIndicators.jl`](https://github.com/femtotrader/OnlineTechnicalIndicators.jl) (Julia translation of tailpp)
-   The Circular Buffer implementation references the design patterns from [`DataStructures.jl`](https://juliacollections.github.io/DataStructures.jl/stable/).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
Copyright (c) 2024 [Takayuki Yamamoto <dev@ymmt.cc>]

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
