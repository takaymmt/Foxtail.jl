"""
    WMA(data::Vector{T}, period::Int) where T

Calculate Weighted Moving Average (WMA) for a given time series data.

Weighted Moving Average assigns linearly increasing weights to more recent prices
while considering historical data. This implementation uses a circular buffer for
efficient memory management and optimizes calculations by maintaining running sums.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the moving window for weighted average calculation

# Returns
- `Vector{T}`: Vector containing WMA values for each point in the input data

# Implementation Details
The function uses different calculation approaches based on the buffer state:
- During initialization (i ≤ period):
  * Weight for position i is i
  * Denominator is calculated as i(i+1)/2
  * Maintains running sum of weighted prices
- After initialization (i > period):
  * Uses circular buffer to update running sums efficiently
  * Updates numerator by adding new weighted price and removing oldest values
  * Denominator remains constant at period(period+1)/2

The WMA is calculated using the formula:
    WMA = Σ(weight_i * price_i) / Σ(weight_i)
where weight_i increases linearly with recency

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = WMA(prices, period)  # Returns: [1.0, 1.67, 2.33, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
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