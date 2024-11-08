"""
    DEMA(data::Vector{T}, period::Int) where T

Calculate Double Exponential Moving Average (DEMA) for a given time series data.

Double Exponential Moving Average, developed by Patrick Mulloy, aims to reduce the
inherent lag of traditional moving averages. It uses a combination of two EMAs to
decrease the lag while maintaining smoothness, making it more responsive to price
changes than a standard EMA.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period for EMA calculations

# Returns
- `Vector{T}`: Vector containing DEMA values for each point in the input data

# Implementation Details
The function performs a three-step calculation process:
1. Calculates initial EMA with the specified period
2. Calculates second EMA of the first EMA using the same period
3. Computes final DEMA using the formula:
   DEMA = 2 * EMA(price) - EMA(EMA(price))

Key characteristics:
- Double smoothing reduces noise while maintaining responsiveness
- Multiplier of 2 and subtraction of double-smoothed EMA reduces lag
- More responsive to price changes than standard EMA
- Provides better trend following capabilities with less delay

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = DEMA(prices, period)  # Returns: [1.0, 1.89, 2.78, 3.67, 4.68, 5.74, 6.80, 7.85, 8.90, 9.92]
```

See also: [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function DEMA(prices::Vector{T}, period::Int) where T
    EMA1 = EMA(prices, period)
	EMA2 = EMA(EMA1, period)
	return EMA1 * 2 - EMA2
end

@prep_SISO DEMA