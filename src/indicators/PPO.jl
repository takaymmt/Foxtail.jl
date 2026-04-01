"""
    PPO(prices::Vector{Float64}; fast::Int=12, slow::Int=26, signal::Int=9) -> Matrix{Float64}

Calculate Percentage Price Oscillator (PPO) — a percentage-normalized version of MACD that measures the difference between two EMAs as a percentage of the slower EMA.

## Parameters
- `prices`: Input price vector (`Float64`), typically closing prices.
- `fast`: Period for the fast EMA (default: 12). Valid range: `fast >= 1`.
- `slow`: Period for the slow EMA (default: 26). Valid range: `slow > fast`.
- `signal`: Period for the signal line EMA (default: 9). Valid range: `signal >= 1`.

## Returns
Matrix of size `(length(prices), 3)`:
- Column 1: PPO line (`(fast EMA - slow EMA) / slow EMA * 100`)
- Column 2: Signal line (`EMA of PPO line`)
- Column 3: Histogram (`PPO - Signal`)

Requires input length >= `slow`.

## Formula
```math
\\begin{aligned}
PPO_t &= \\frac{EMA_{\\text{fast}}(P)_t - EMA_{\\text{slow}}(P)_t}{EMA_{\\text{slow}}(P)_t} \\times 100 \\\\
Signal_t &= EMA_{\\text{signal}}(PPO)_t \\\\
Histogram_t &= PPO_t - Signal_t
\\end{aligned}
```

## Interpretation
- PPO crossing above signal line: bullish signal.
- PPO crossing below signal line: bearish signal.
- PPO crossing zero line: indicates trend direction change.
- Expressed as a percentage, making it comparable across securities with different price levels.
- Functionally identical to MACD but normalized, enabling cross-asset comparison.
- Created by: Gerald Appel (derived from MACD).

## Example
```julia
prices = [100.0, 101.5, 99.8, 102.3, 103.5, 104.0, 103.2]
result = PPO(prices; fast=12, slow=26, signal=9)
# result[:,1] = PPO line, result[:,2] = Signal, result[:,3] = Histogram
```

## See Also
[`MACD`](@ref), [`EMA`](@ref), [`RSI`](@ref)
"""
function PPO(prices::Vector{Float64}; fast::Int = 12, slow::Int = 26, signal::Int = 9)
    len = length(prices)
    if len < slow
        throw(ArgumentError("price series length must be greater than slow period"))
    end

    # Calculate EMAs
    fast_ema = EMA(prices; n=fast)
    slow_ema = EMA(prices; n=slow)

    # Calculate PPO line (percentage difference)
    ppo_line = @. (fast_ema - slow_ema) / slow_ema * 100

    # Calculate signal line
    signal_line = EMA(ppo_line; n=signal)

    # Calculate histogram
    histogram = ppo_line - signal_line

    # Combine results
    results = zeros(len, 3)
    results[:, 1] = ppo_line
    results[:, 2] = signal_line
    results[:, 3] = histogram

    return results
end

@prep_simo PPO [Line, Signal, Histogram] fast=12 slow=26 signal=9
