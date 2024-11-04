"""
    EMA(data::Vector{T}, period::Int) where T

Calculate Exponential Moving Average (EMA) for a given time series data.

Exponential Moving Average applies more weight to recent prices while still considering
historical data, with weights decreasing exponentially. This implementation uses a
dynamic smoothing factor for the initial period and a fixed smoothing factor afterwards.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period and smoothing factor calculation

# Returns
- `Vector{T}`: Vector containing EMA values for each point in the input data

# Implementation Details
The function uses different smoothing approaches based on the position in the series:
- First point: Uses the actual price as initial EMA
- During initialization (i ≤ period): Uses dynamic smoothing factor α = 2/(1+i)
- After initialization (i > period): Uses fixed smoothing factor α = 2/(1+period)

The EMA is calculated using the formula:
    EMA_t = Price_t * α + EMA_(t-1) * (1-α)
where α is the smoothing factor

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = EMA(prices, period)  # Returns: [1.0, 1.67, 2.33, 3.0, 3.8, 4.68, 5.6, 6.57, 7.54, 8.52]
```
"""
@inline Base.@propagate_inbounds function EMA(data::Vector{T}, period::Int) where T
    results = zeros(T, length(data))
    alpha = 0.0

    @inbounds for (i, price) in enumerate(data)
        if i > period
            results[i] = price * alpha + results[i-1] * (1-alpha)
        elseif i == 1
            results[i] = price
        else
            alpha = 2 / (1+i)
            results[i] = price * alpha + results[i-1] * (1-alpha)
        end
    end
    return results
end

@prep_SISO EMA