"""
    TMA(prices::Vector{T}; n::Int=10) where T

Calculate Triangular Moving Average (TMA) for a given time series data.

A Triangular Moving Average is a double-smoothed indicator that applies two Simple Moving
Averages (SMA) in sequence. This results in a smoother trend-following indicator compared
to a standard SMA.

# Arguments
- `prices::Vector{T}`: Input price vector of any numeric type
- `n::Int=10`: Length of the moving window for average calculation (default: 10)

# Returns
- `Vector{T}`: Vector containing TMA values for each point in the input data

# Implementation Details
The calculation involves two steps:
1. First SMA with period `n`
2. Second SMA with period `(n+1)/2`

This creates a weighted moving average where:
- Middle values receive the highest weight
- Edge values receive progressively less weight
- Results in reduced lag compared to multiple SMAs

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0]
result = TMA(prices; n=3)
```

See also: [`SMA`](@ref), [`TRIMA`](@ref)
"""
@inline Base.@propagate_inbounds function TMA(prices::Vector{T}; n::Int=10) where T
    SMA1 = SMA(prices; n=n)
    return SMA(SMA1; n=div(n+1, 2))
end

@prep_siso TMA n=10

TRIMA(ts::TSFrame; n::Int=10, field::Symbol = :Close) = TMA(ts; n=n, field=field)
export TRIMA