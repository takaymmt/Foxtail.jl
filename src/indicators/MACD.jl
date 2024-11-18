"""
    MACD
    MACD(prices::Vector{Float64}; fast::Int = 12, slow::Int = 26, signal::Int = 9) -> Matrix{Float64}

Moving Average Convergence Divergence (MACD) is a trend-following momentum indicator that shows the relationship between two moving averages of an asset's price.

## Basic Concept
- MACD is calculated by subtracting a longer-term EMA from a shorter-term EMA
- A signal line (typically 9-period EMA of MACD) is used to generate trading signals
- The histogram shows the difference between MACD and its signal line
- Developed by Gerald Appel in the late 1970s

## Interpretation / Trading Signals
- MACD crossing above signal line: Bullish signal
- MACD crossing below signal line: Bearish signal
- MACD crossing zero line: Indicates trend direction change
- Histogram increasing: Momentum is building
- Divergence between MACD and price: Potential trend reversal
- Works best in trending markets, less reliable in ranging markets

## Usage Examples
```julia
# Basic usage with default parameters
prices = [100.0, 101.5, 99.8, 102.3, 103.5]
result = MACD(prices)

# Custom parameters for different timeframes
result = MACD(prices; fast=8, slow=21, signal=5)  # More sensitive settings
```

## Core Formula
```math
\\begin{align*}
MACD &= EMA(price, fast) - EMA(price, slow) \\\\
Signal &= EMA(MACD, signal) \\\\
Histogram &= MACD - Signal
\\end{align*}
```

Key components:
- MACD line: Difference between fast and slow EMAs
- Signal line: EMA of MACD line
- Histogram: Visual representation of MACD and signal line difference

## Parameters and Arguments
- `prices::Vector{Float64}`:
  - Price series for calculation
  - Typically closing prices
  - Must have length greater than slow period

- `fast::Int`: (Default: 12)
  - Period for fast EMA
  - Valid range: > 0
  - Shorter values increase sensitivity
  - Common values: 8-13

- `slow::Int`: (Default: 26)
  - Period for slow EMA
  - Valid range: > fast period
  - Common values: 21-30
  - Impact: Defines trend length being analyzed

- `signal::Int`: (Default: 9)
  - Period for signal line EMA
  - Valid range: > 0
  - Common values: 5-13
  - Impact: Affects signal generation timing

## Returns
- `Matrix{Float64}`: A matrix with 3 columns:
  - Column 1: MACD line
  - Column 2: Signal line
  - Column 3: Histogram
  - Rows correspond to input price series length

## Implementation Details
Algorithm overview:
- Calculate fast and slow EMAs of price series
- Compute MACD line as difference of EMAs
- Calculate signal line as EMA of MACD line
- Compute histogram as difference between MACD and signal

Performance characteristics:
- Time complexity: O(n), where n is price series length
- Space complexity: O(n)
- Requires minimum price series length equal to slow period
"""
function MACD(prices::Vector{Float64}; fast::Int = 12, slow::Int = 26, signal::Int = 9)
    len = length(prices)
    if len < slow
        throw(ArgumentError("price series length must be greater than slow period"))
    end

    # Calculate EMAs
    fast_ema = EMA(prices; n=fast)
    slow_ema = EMA(prices; n=slow)

    # Calculate MACD line
    macd_line = fast_ema - slow_ema

    # Calculate signal line
    signal_line = EMA(macd_line; n=signal)

    # Calculate histogram
    histogram = macd_line - signal_line

    # Combine results
    results = zeros(len, 3)
    results[:, 1] = macd_line
    results[:, 2] = signal_line
    results[:, 3] = histogram

    return results
end

@prep_simo MACD [Line, Signal, Histogram] fast=12 slow=26 signal=9