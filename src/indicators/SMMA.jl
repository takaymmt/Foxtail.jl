"""
    SMMA(data::Vector{T}; n::Int=14) where T -> Vector{T}

Calculate Smoothed Moving Average (SMMA), also known as RMA (Running Moving Average) or Wilder's Smoothing.

## Parameters
- `data`: Input price vector of any numeric type.
- `n`: Smoothing period (default: 14). Valid range: `n >= 1`.

## Returns
Vector of SMMA values. The first value equals the first input price.

## Formula
```math
SMMA_t = P_t \\times \\alpha + SMMA_{t-1} \\times (1 - \\alpha), \\quad \\alpha = \\frac{1}{n}
```

During initialization (`i <= n`), a dynamic smoothing factor `alpha = 1/i` is used.

## Interpretation
- Equivalent to an EMA with `alpha = 1/n` instead of `2/(n+1)`, resulting in heavier smoothing.
- Originally introduced by J. Welles Wilder Jr. for use in RSI and ATR calculations.
- Slower to react to price changes than EMA with the same period.
- Also available as `RMA` (alias for TSFrame input).

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0]
result = SMMA(prices; n=3)
```

## See Also
[`EMA`](@ref), [`SMA`](@ref), [`RSI`](@ref)
"""
@inline Base.@propagate_inbounds function SMMA(data::Vector{T}; n::Int=14) where T
    period = n
    results = zeros(T, length(data))
    alpha = 0.0

    @inbounds results[1] = data[1]

    # Calculate alpha for period > 1
    @inbounds for i in 2:period
        alpha = 1/ i
        results[i] = data[i] * alpha + results[i-1] * (1 - alpha)
    end

    # Fixed alpha for remaining values
    alpha = 1 / period
    @inbounds for i in (period+1):length(data)
        results[i] = data[i] * alpha + results[i-1] * (1 - alpha)
    end
    return results
end

@prep_siso SMMA n=10

RMA(ts::TSFrame; n::Int=14, field::Symbol = :Close) = SMMA(ts; n=n, field=field)
export RMA

@inline Base.@propagate_inbounds function SMMA_stats(data::Vector{T}; n::Int=14) where T
    period = n
    results = zeros(T, length(data), 2)
    alpha = 0.0

    # Initialize with first value
    @inbounds results[1, 1] = data[1]  # mean
    @inbounds results[1, 2] = zero(T)  # std

    # Previous values for recursive calculation
    prev_mean = data[1]
    prev_variance = zero(T)

    @inbounds for i in 2:length(data)
        # Set appropriate alpha based on position
        if i > period
            alpha = 1 / period
        else
            alpha = 1 / i
        end

        # Calculate difference from previous mean
        diff = data[i] - prev_mean

        # Update mean
        incr = alpha * diff
        new_mean = prev_mean + incr

        # Update variance using the recursive formula
        new_variance = (1 - alpha) * (prev_variance + diff * incr)

        # Store results
        results[i, 1] = new_mean
        results[i, 2] = sqrt(max(zero(T), new_variance))

        # Update previous values for next iteration
        prev_mean = new_mean
        prev_variance = new_variance
    end

    return results
end