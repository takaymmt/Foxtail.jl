"""
    HMA(prices::Vector{T}; n::Int=10) where T

Calculate Hull Moving Average (HMA) for a given time series data.

Hull Moving Average, developed by Alan Hull, is designed to reduce lag in moving
averages while maintaining smoothness. It combines multiple Weighted Moving Averages
(WMA) with different periods and uses square root of the original period for final
smoothing, resulting in a more responsive indicator.

# Arguments
- `prices::Vector{T}`: Input price vector of any numeric type
- `n::Int=10`: Length of the primary moving window for average calculation (default: 10)

# Returns
- `Vector{T}`: Vector containing HMA values for each point in the input data

# Implementation Details
The function performs a three-step calculation process:
1. Calculates WMA with n/2
2. Calculates WMA with full n
3. Computes final HMA using the formula:
   WMA[sqrt(n)]( 2 * WMA[n/2] - WMA[n] )

Key characteristics:
- Uses half-length WMA to capture faster price movements
- Subtracts full-length WMA to reduce lag
- Final smoothing period of sqrt(n) balances responsiveness and smoothness
- Results in minimal lag while maintaining smooth transitions

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = HMA(prices; n=4)  # Returns HMA values with default window size
```

See also: [`WMA`](@ref)
"""
@inline Base.@propagate_inbounds function HMA(prices::Vector{T}; n::Int=10) where T
    WMA1 = WMA(prices; n = div(n, 2))
	WMA2 = WMA(prices; n = n)
	return WMA(WMA1 * 2 - WMA2; n = round(Int, sqrt(n)))
end

@prep_siso HMA n=10