"""
    RSI (Relative Strength Index)
    RSI(ts::TSFrame, period::Int=14; field::Symbol=:Close) -> TSFrame

A momentum oscillator that measures the speed and magnitude of recent price changes to evaluate overbought or oversold conditions.

## Basic Concept
- Tracks momentum by comparing the magnitude of recent gains to recent losses
- Normalizes the calculation to a range between 0 and 100
- Uses a smoothing method (default: Smoothed Moving Average) to reduce noise
- Developed by J. Welles Wilder Jr. in 1978

## Interpretation / Trading Signals
- Traditional overbought level: ≥ 70
- Traditional oversold level: ≤ 30
- Centerline (50) crossovers can indicate trend changes
- Divergences between price and RSI can signal potential reversals
- Most effective in ranging markets; less reliable in strong trends
- Failure swings above 70/below 30 can indicate strong trend continuation

## Usage Examples
```julia
# Basic usage with default parameters
prices = TSFrame(...) # :Close => [100.0, 102.0, 101.0, 103.0, 102.0, 103.0]
rsi = RSI(prices)

# Custom period and smoothing method
rsi_custom = RSI(prices, 10; smoothing=:EMA)
```

## Core Formula
```math
RSI = 100 - \\frac{100}{1 + RS}
```
where:
```math
RS = \\frac{\\text{Average Gain}}{\\text{Average Loss}}
```

Key components:
- Average Gain: Smoothed average of positive price changes
- Average Loss: Smoothed average of negative price changes (absolute values)
- Initial averages are simple means of first n periods
- Subsequent values use smoothing formula based on selected method

## Implementation Details
Algorithm overview:
1. Calculate price changes between consecutive periods
2. Separate positive (gains) and negative (losses) price changes
3. Apply selected smoothing method to both gains and losses series
4. Calculate RS ratio for each point
5. Transform RS into RSI using the formula
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