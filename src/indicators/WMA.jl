"""
    WMA(data::Vector{T}; n::Int=10) where T

Calculate Weighted Moving Average (WMA) for a given time series data.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `n::Int=10`: Length of the moving window (default: 10)

# Returns
- `Vector{T}`: Vector containing WMA values for each point in the input data

# Algorithm
Uses a weighted sum where recent values have higher weights:
- For position i ≤ n: weights increase linearly from 1 to i
- For position i > n: weights increase linearly from 1 to n
- Denominator is calculated as n(n+1)/2 for full window
- Uses circular buffer for efficient memory management

# Formula
WMA = Σ(weight_i * price_i) / Σ(weight_i)
where weight_i increases linearly with recency

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0]
wma = WMA(prices, n=3)  # Returns weighted moving averages
```
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