"""
    MACD(prices::Vector{Float64}; fast::Int=12, slow::Int=26, signal::Int=9) -> Matrix{Float64}

Calculate Moving Average Convergence Divergence (MACD) — a trend-following momentum indicator based on EMA differences.

## Parameters
- `prices`: Input price vector (`Float64`), typically closing prices.
- `fast`: Period for the fast EMA (default: 12). Valid range: `fast >= 1`.
- `slow`: Period for the slow EMA (default: 26). Valid range: `slow > fast`.
- `signal`: Period for the signal line EMA (default: 9). Valid range: `signal >= 1`.

## Returns
Matrix of size `(length(prices), 3)`:
- Column 1: MACD line (`fast EMA - slow EMA`)
- Column 2: Signal line (`EMA of MACD line`)
- Column 3: Histogram (`MACD - Signal`)

Requires input length >= `slow`.

## Formula
```math
\\begin{aligned}
MACD_t &= EMA_{\\text{fast}}(P)_t - EMA_{\\text{slow}}(P)_t \\\\
Signal_t &= EMA_{\\text{signal}}(MACD)_t \\\\
Histogram_t &= MACD_t - Signal_t
\\end{aligned}
```

## Interpretation
- MACD crossing above signal line: bullish signal.
- MACD crossing below signal line: bearish signal.
- MACD crossing zero line: indicates trend direction change.
- Increasing histogram: momentum is building.
- Divergence between MACD and price: potential trend reversal.
- Works best in trending markets; less reliable in ranging markets.
- Created by: Gerald Appel (late 1970s).

## Example
```julia
prices = [100.0, 101.5, 99.8, 102.3, 103.5, 104.0, 103.2]
result = MACD(prices; fast=12, slow=26, signal=9)
# result[:,1] = MACD line, result[:,2] = Signal, result[:,3] = Histogram
```

## See Also
[`EMA`](@ref), [`RSI`](@ref), [`MACD3`](@ref)
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