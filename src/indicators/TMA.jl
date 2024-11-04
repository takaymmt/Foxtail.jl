"""
    TMA(data::Vector{T}, period::Int) where T
    TRIMA(data::Vector{T}, period::Int) where T

Calculate Triangular Moving Average (TMA) for a given time series data.
Also known as TRIMA (TRIangular Moving Average).

Triangular Moving Average is a double-smoothed indicator calculated by taking a
Simple Moving Average (SMA) of another SMA. This creates a smoother moving average
with weights that increase linearly towards the middle of the period and then
decrease linearly.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the moving window for average calculation

# Returns
- `Vector{T}`: Vector containing TMA values for each point in the input data

# Implementation Details
The function performs a two-step smoothing process:
1. Calculates initial SMA with the specified period
2. Takes another SMA of the result with period (n+1)/2, where n is the original period

The weighting pattern follows a triangular distribution:
- Weights increase linearly to the middle period
- Weights decrease linearly from the middle to the end
- Results in a smoother line compared to simple SMA

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = TMA(prices, period)  # Returns: [1.0, 1.25, 1.75, 2.25, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
```

See also: [`SMA`](@ref)
"""
@inline Base.@propagate_inbounds function TMA(prices::Vector{T}, period::Int) where T
    SMA1 = SMA(prices, period)
    return SMA(SMA1, div(period+1, 2))
end

@prep_SISO TMA

TRIMA(ts::TSFrame, period::Int; field::Symbol = :Close) = TMA(ts, period; field)
export TRIMA