"""
    SMMA(data::Vector{T}, period::Int) where T
    RMA(data::Vector{T}, period::Int) where T

Calculate Smoothed Moving Average (SMMA) for a given time series data.
Also known as RMA (Running Moving Average) or Modified Moving Average (MMA).

Smoothed Moving Average is similar to EMA but uses a different smoothing approach,
applying a gentler smoothing factor that gives more weight to historical data. This
implementation uses a dynamic smoothing factor during initialization and a fixed
smoothing factor afterwards.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period and smoothing factor calculation

# Returns
- `Vector{T}`: Vector containing SMMA values for each point in the input data

# Implementation Details
The function uses different smoothing approaches based on the position in the series:
- First point: Uses the actual price as initial SMMA
- During initialization (i ≤ period): Uses dynamic smoothing factor α = 1/i
- After initialization (i > period): Uses fixed smoothing factor α = 1/period

The SMMA is calculated using the formula:
    SMMA_t = Price_t * α + SMMA_(t-1) * (1-α)
where α is the smoothing factor

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = SMMA(prices, period)  # Returns: [1.0, 1.5, 2.0, 2.5, 3.13, 3.84, 4.62, 5.47, 6.36, 7.27]
```
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