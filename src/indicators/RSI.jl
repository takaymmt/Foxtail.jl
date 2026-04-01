"""
    RSI(prices::Vector{Float64}; n::Int=14, ma_type::Symbol=:SMMA) -> Vector{Float64}

Calculate Relative Strength Index (RSI) — a momentum oscillator measuring the speed and magnitude of price changes.

## Parameters
- `prices`: Input price vector (`Float64`).
- `n`: Lookback period for gain/loss smoothing (default: 14). Valid range: `n >= 1`.
- `ma_type`: Moving average type for smoothing gains and losses (default: `:SMMA`).
  Options: `:SMMA` (Wilder's original), `:EMA`, `:SMA`.

## Returns
Vector of RSI values (0-100 scale). The first value is `0.0` (undefined).
Requires input length > `n + 1`.

## Formula
```math
RS_t = \\frac{MA(\\text{gains}, n)_t}{MA(\\text{losses}, n)_t}, \\quad
RSI_t = 100 - \\frac{100}{1 + RS_t}
```

Where gains and losses are separated from price changes: `delta_t = P_t - P_{t-1}`.

## Interpretation
- Oscillates between 0 and 100.
- Overbought: RSI >= 70 (potential reversal downward or strong uptrend).
- Oversold: RSI <= 30 (potential reversal upward or strong downtrend).
- Centerline (50) crossover can confirm trend direction.
- Divergence between RSI and price often signals a pending reversal.
- Created by: J. Welles Wilder Jr. (1978).

## Example
```julia
prices = [100.0, 102.0, 101.0, 103.0, 102.0, 103.0]
rsi = RSI(prices)                         # Default: n=14, ma_type=:SMMA
rsi = RSI(prices; n=10, ma_type=:EMA)     # Custom parameters
```

## See Also
[`StochRSI`](@ref), [`SMMA`](@ref), [`MACD`](@ref)
"""
@inline Base.@propagate_inbounds function RSI(prices::Vector{Float64}; n::Int=14, ma_type::Symbol=:SMMA)
    period = n
    period < 1 && throw(ArgumentError("period must be positive"))

    n = length(prices)
    n < period + 1 && throw(ArgumentError("price series length must be greater than period + 1"))

    # Calculate price changes
    changes = diff(prices)
    gains = zeros(n-1)
    losses = zeros(n-1)

    @inbounds for i in 1:length(changes)
        if changes[i] > 0
            gains[i] = changes[i]
        else
            losses[i] = abs(changes[i])
        end
    end

    # Calculate RS (Relative Strength)
    gains = apply_ma(gains, ma_type; n=period)
    losses = apply_ma(losses, ma_type; n=period)

    rs = gains ./ losses

    # Calculate RSI
    rsi = zeros(n)
    rsi[1] = 0  # First value is undefined

    @inbounds for i in 2:n
        rsi[i] = 100.0 - (100.0 / (1.0 + rs[i-1]))
    end

    return rsi
end

@prep_siso RSI n=14 ma_type=SMMA