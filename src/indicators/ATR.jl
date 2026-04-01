"""
    ATR(prices::Matrix{Float64}; n::Int=14, ma_type::Symbol=:EMA) -> Vector{Float64}

Calculate Average True Range (ATR) — a volatility indicator measuring the average range of price movement.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: Lookback period for smoothing the True Range (default: 14). Valid range: `n >= 1`.
- `ma_type`: Moving average type for smoothing (default: `:EMA`).
  Options: `:SMA`, `:EMA`, `:SMMA`/`:RMA`.

## Returns
Vector of ATR values with the same length as the number of input rows.

## Formula
```math
TR_t = \\max(H_t - L_t,\\; |H_t - C_{t-1}|,\\; |L_t - C_{t-1}|), \\quad
ATR_t = MA_n(TR)_t
```

The first True Range value uses `H_1 - L_1` (no previous close available).

## Interpretation
- Higher ATR values indicate increased market volatility.
- Lower ATR values indicate decreased volatility (consolidation).
- Common uses: stop-loss placement (e.g., 2x ATR trailing stop), position sizing, and breakout confirmation.
- ATR measures volatility magnitude, not price direction.
- Created by: J. Welles Wilder Jr. (1978).

## Example
```julia
# prices matrix: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 104.0 99.0 100.0]
result = ATR(prices; n=2, ma_type=:EMA)
```

## See Also
[`BB`](@ref), [`EMA`](@ref), [`SMMA`](@ref)
"""
@inline Base.@propagate_inbounds function ATR(prices::Matrix{Float64}; n::Int=14, ma_type::Symbol=:EMA)
    period = n
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
    end

    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    true_ranges = TR(prices)

    return apply_ma(true_ranges, ma_type; n=period)
end

@inline Base.@propagate_inbounds function TR(prices::Matrix{Float64})
    n = size(prices, 1)
    result = zeros(n)

    result[1] = prices[1, 1] - prices[1, 2]

    @inbounds for i in 2:n
        high = prices[i, 1]
        low = prices[i, 2]
        prev_close = prices[i-1, 3]

        range1 = high - low
        range2 = abs(high - prev_close)
        range3 = abs(low - prev_close)

        result[i] = max(range1, range2, range3)
    end

    return result
end

@prep_miso ATR [High, Low, Close] n=14 ma_type=EMA