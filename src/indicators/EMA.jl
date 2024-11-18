"""
    EMA(data::Vector{T}; n::Int=10) where T

Calculate Exponential Moving Average (EMA) for a given time series data.

Exponential Moving Average applies more weight to recent prices while still considering
historical data, with weights decreasing exponentially. This implementation uses a
dynamic smoothing factor for the initial period and a fixed smoothing factor afterwards.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `n::Int=10`: Length of the initialization period and smoothing factor calculation (default: 10)

# Returns
- `Vector{T}`: Vector containing EMA values for each point in the input data

# Implementation Details
The function uses different smoothing approaches based on the position in the series:
- First point: Uses the actual price as initial EMA
- During initialization (i ≤ n): Uses dynamic smoothing factor α = 2/(1+i)
- After initialization (i > n): Uses fixed smoothing factor α = 2/(1+n)

The EMA is calculated using the formula:
    EMA_t = Price_t * α + EMA_(t-1) * (1-α)
where α is the smoothing factor

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = EMA(prices, n=4)  # Returns: [1.0, 1.67, 2.33, 3.0, 3.8, 4.68, 5.6, 6.57, 7.54, 8.52]
```
"""
@inline Base.@propagate_inbounds function EMA(data::Vector{T}; n::Int=10) where T
    period = n
    results = zeros(T, length(data))
    alpha = 0.0

    # First value initialization
    @inbounds results[1] = data[1]

    # Calculate alpha for period > 1
    @inbounds for i in 2:period
        alpha = 2 / (1 + i)
        results[i] = data[i] * alpha + results[i-1] * (1 - alpha)
    end

    # Fixed alpha for remaining values
    alpha = 2 / (1 + period)
    @inbounds for i in (period+1):length(data)
        results[i] = data[i] * alpha + results[i-1] * (1 - alpha)
    end
    return results
end

@prep_siso EMA n=10

"""
    EMA_stats(data::Vector{T}; n::Int=10) where T

Calculate Exponential Moving Average (EMA) and its standard deviation using the recursive method
described in "Incremental calculation of weighted mean and variance" (Tony Finch, 2009).

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `n::Int=10`: Length for calculating the smoothing factor (default: 10)

# Returns
- `Matrix{T}`: A matrix where:
  - First column contains EMA values
  - Second column contains standard deviations

# Implementation Details
Uses different smoothing factors based on the position:
- First point: Uses actual price as initial EMA
- During initialization (i ≤ n): Uses dynamic α = 2/(1+i)
- After initialization (i > n): Uses fixed α = 2/(1+n)

Variance is updated using the recursive formula:
var[t] = (1 - α) * (var[t-1] + α * (x[t] - mean[t-1])²)

# Reference
- "Incremental calculation of weighted mean and variance" written by Tony Finch, Feb 2009
"""
@inline Base.@propagate_inbounds function EMA_stats(data::Vector{T}; n::Int=10) where T
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
            alpha = 2 / (1 + period)
        else
            alpha = 2 / (1 + i)
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

# export EMA_stats