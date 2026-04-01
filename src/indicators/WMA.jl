"""
    WMA(data::Vector{T}; n::Int=10) where T -> Vector{T}

Calculate Weighted Moving Average (WMA) — a linearly weighted moving average giving more weight to recent prices.

## Parameters
- `data`: Input price vector of any numeric type.
- `n`: Length of the moving window (default: 10). Valid range: `n >= 1`.

## Returns
Vector of WMA values. During initialization (first `n` elements), weights scale from 1 to `i`.

## Formula
```math
WMA_t = \\frac{\\sum_{i=0}^{n-1} (n - i) \\cdot P_{t-i}}{\\sum_{i=0}^{n-1} (n - i)}
= \\frac{n \\cdot P_t + (n-1) \\cdot P_{t-1} + \\cdots + 1 \\cdot P_{t-n+1}}{n(n+1)/2}
```

## Interpretation
- Assigns linearly increasing weights to more recent prices (the most recent price gets weight `n`).
- More responsive than SMA but less responsive than EMA for the same period.
- Useful when a linear emphasis on recency is desired without exponential decay.
- Forms a key building block of the Hull Moving Average (HMA).

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0]
wma = WMA(prices; n=3)
```

## See Also
[`SMA`](@ref), [`EMA`](@ref), [`HMA`](@ref)
"""
@inline Base.@propagate_inbounds function WMA(data::Vector{T}; n::Int=10) where T
    # See https://en.wikipedia.org/wiki/Moving_average#Weighted_moving_average
    period = n
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    numerator = 0.0
    total = 0.0
    denominator = 0.0

    @inbounds for (i, price) in enumerate(data)
        if i > period
            numerator += period * price - total
            total += price - first(buf)
            push!(buf, price)
        else
            push!(buf, price)
            denominator = i * (i+1) / 2
            numerator += i * price
            total += price
        end
        results[i] = numerator / denominator
    end
    return results
end

@prep_siso WMA n=10