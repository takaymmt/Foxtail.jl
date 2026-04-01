"""
    WR(prices::Matrix{Float64}; n::Int=14) -> Matrix{Float64}

Calculate Williams %R (Williams Percent Range) — a momentum oscillator measuring overbought/oversold levels.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: Lookback period (default: 14). Valid range: `n >= 1`.

## Returns
Matrix of size `(rows, 2)`:
- Column 1: Raw Williams %R values
- Column 2: EMA of Williams %R (period `n-1`)

## Formula
```math
\\%R_t = -100 \\times \\frac{HH_n - C_t}{HH_n - LL_n}
```

Where `HH_n` = highest high and `LL_n` = lowest low over the last `n` periods.

## Interpretation
- Oscillates between 0 and -100.
- Overbought: %R >= -20 (price near the top of its recent range).
- Oversold: %R <= -80 (price near the bottom of its recent range).
- Mathematically the inverse of Fast Stochastic %K (mirrored and shifted).
- Most useful for identifying potential reversal points in ranging markets.
- Created by: Larry Williams.

## Example
```julia
# prices: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 102.0; 107.0 99.0 105.0]
result = WR(prices; n=2)
# result[:,1] = raw %R, result[:,2] = EMA of %R
```

## See Also
[`Stoch`](@ref), [`RSI`](@ref)
"""
@inline Base.@propagate_inbounds function WR(prices::Matrix{Float64}; n::Int=14)
    period = n
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
    end

    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    len = size(prices, 1)
    if len < period
        throw(ArgumentError("price series length must be greater than period"))
    end

    # Extract price data
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]

    # Pre-allocate result array
    results = zeros(len)

    q = MinMaxQueue{Float64}(period+1)

    @inbounds for i in 1:period
        update!(q, highs[i], lows[i], i)

        w_max = get_max(q)
        w_min = get_min(q)

        denominator = w_max - w_min

        if denominator ≈ 0.0
            results[i] = -50.0  # Default to middle value when price range is zero
        else
            results[i] = -100.0 * (w_max - closes[i]) / denominator
        end
    end

    @inbounds for i in (period+1):len
        remove_old!(q, i - period)
        update!(q, highs[i], lows[i], i)

        w_max = get_max(q)
        w_min = get_min(q)

        denominator = w_max - w_min

        if denominator ≈ 0.0
            results[i] = -50.0  # Default to middle value when price range is zero
        else
            results[i] = -100.0 * (w_max - closes[i]) / denominator
        end
    end

    ema = EMA(results; n = period - 1)
    return hcat(results, ema)
end

@prep_mimo WR [High, Low, Close] [raw, EMA] n=14