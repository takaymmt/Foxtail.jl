"""
    RSI(prices::Vector{Float64}; n::Int=14, ma_type::Symbol=:SMMA) -> Vector{Float64}

A momentum oscillator that measures the speed and magnitude of recent price changes to evaluate overbought or oversold conditions.

## Parameters
- `prices`: Vector of price values
- `n`: Period for calculation (default: 14)
- `ma_type`: Moving average type for smoothing (`:SMMA`, `:EMA`, or `:SMA`, default: `:SMMA`)

## Returns
- Vector of RSI values, where the first value is 0 (undefined)

## Implementation Details
1. Calculates price changes between consecutive periods
2. Separates gains (positive changes) and losses (negative changes)
3. Applies specified moving average to both gains and losses
4. Computes RS (Relative Strength) as ratio of smoothed gains to losses
5. Transforms RS into RSI using formula: RSI = 100 - (100 / (1 + RS))

## Example
```julia
prices = [100.0, 102.0, 101.0, 103.0, 102.0, 103.0]
rsi = RSI(prices)  # Uses default n=14, ma_type=:SMMA
rsi = RSI(prices; n=10, ma_type=:EMA)  # Custom parameters
```

## Notes
- Requires price series length > period + 1
- First value is set to 0 as it's undefined
- Supports three moving average types: SMMA (default), EMA, and SMA
- Traditional interpretation levels: ≥70 overbought, ≤30 oversold
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
    if ma_type == :SMMA
        gains = SMMA(gains; n=period)
        losses = SMMA(losses; n=period)
    elseif ma_type == :EMA
        gains = EMA(gains; n=period)
        losses = EMA(losses; n=period)
    else  # Simple moving average
        gains = SMA(gains; n=period)
        losses = SMA(losses; n=period)
    end

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