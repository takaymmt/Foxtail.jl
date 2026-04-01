"""
    Supertrend(prices::Matrix{Float64}; n::Int=7, mult::Float64=3.0) -> Matrix{Float64}

Calculate Supertrend — a trend-following indicator based on ATR that identifies the current trend direction.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: ATR lookback period (default: 7). Valid range: `n >= 1`.
- `mult`: ATR multiplier for band width (default: 3.0). Valid range: `mult > 0`.

## Returns
Matrix of size `(rows, 2)`:
- Column 1: Supertrend value (the active band — lower band in uptrend, upper band in downtrend).
- Column 2: Trend direction (`1.0` = uptrend, `-1.0` = downtrend).

## Formula
```math
TP_t = \\frac{H_t + L_t + C_t}{3}, \\quad
BasicUpper_t = TP_t + mult \\times ATR_t, \\quad
BasicLower_t = TP_t - mult \\times ATR_t
```

Final bands use a state-machine that locks to the previous band when the price does not break through:
- `FinalUpper[t] = min(BasicUpper[t], FinalUpper[t-1])` if `Close[t-1] <= FinalUpper[t-1]`
- `FinalLower[t] = max(BasicLower[t], FinalLower[t-1])` if `Close[t-1] >= FinalLower[t-1]`

## Interpretation
- Direction = 1.0 (uptrend): price closed above the upper band — the lower band becomes the trailing stop.
- Direction = -1.0 (downtrend): price closed below the lower band — the upper band becomes the trailing stop.
- Created by: Olivier Seban.

## Example
```julia
# prices: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 104.0 99.0 100.0]
result = Supertrend(prices; n=2, mult=3.0)
# result[:,1] = Supertrend value, result[:,2] = Direction
```

## See Also
[`ATR`](@ref), [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function Supertrend(prices::Matrix{Float64}; n::Int=7, mult::Float64=3.0)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end

    if n < 1
        throw(ArgumentError("period must be positive"))
    end

    if mult <= 0.0
        throw(ArgumentError("multiplier must be positive"))
    end

    len = size(prices, 1)

    # Compute ATR using the existing function
    atr_vals = ATR(prices; n=n)

    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]

    # Pre-allocate output
    value = zeros(len)
    direction = zeros(len)
    final_upper = zeros(len)
    final_lower = zeros(len)

    # Initialize bar 1
    @inbounds begin
        tp1 = (highs[1] + lows[1] + closes[1]) / 3.0
        basic_upper1 = tp1 + mult * atr_vals[1]
        basic_lower1 = tp1 - mult * atr_vals[1]
        final_upper[1] = basic_upper1
        final_lower[1] = basic_lower1
        direction[1] = 1.0
        value[1] = final_lower[1]
    end

    @inbounds for i in 2:len
        tp = (highs[i] + lows[i] + closes[i]) / 3.0
        basic_upper = tp + mult * atr_vals[i]
        basic_lower = tp - mult * atr_vals[i]

        # Final Upper Band: tighten downward (use smaller value) when price stays below
        if basic_upper < final_upper[i-1] || closes[i-1] > final_upper[i-1]
            final_upper[i] = basic_upper
        else
            final_upper[i] = final_upper[i-1]
        end

        # Final Lower Band: tighten upward (use larger value) when price stays above
        if basic_lower > final_lower[i-1] || closes[i-1] < final_lower[i-1]
            final_lower[i] = basic_lower
        else
            final_lower[i] = final_lower[i-1]
        end

        # Determine trend direction
        if closes[i] > final_upper[i-1]
            direction[i] = 1.0    # uptrend
        elseif closes[i] < final_lower[i-1]
            direction[i] = -1.0   # downtrend
        else
            direction[i] = direction[i-1]  # maintain previous
        end

        # Value = active band
        if direction[i] == 1.0
            value[i] = final_lower[i]
        else
            value[i] = final_upper[i]
        end
    end

    return hcat(value, direction)
end

@prep_mimo Supertrend [High, Low, Close] [Value, Direction] n=7 mult=3.0
