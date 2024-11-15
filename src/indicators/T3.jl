"""
    T3(data::Vector{T}, period::Int; a::Float64 = 0.7) where T

Calculate T3 Moving Average for a given time series data.

T3 Moving Average, developed by Tim Tillson, is a sophisticated moving average that
uses multiple EMAs and a volume factor to create a highly smooth, low-lag indicator.
It can be used as an alternative to traditional EMAs, offering better smoothness
with comparable lag characteristics.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period for EMA calculations
- `a::Float64`: Volume factor (default: 0.7) controlling smoothness and responsiveness

# Returns
- `Vector{T}`: Vector containing T3 values for each point in the input data

# Implementation Details
The function performs a two-phase calculation process:
1. Calculates six successive EMAs with the specified period:
   EMA1 = EMA(price)
   EMA2 = EMA(EMA1)
   ...up to EMA6

2. Computes final T3 using the weighted combination formula:
   T3 = c1*EMA6 + c2*EMA5 + c3*EMA4 + c4*EMA3
   where coefficients are derived from volume factor a:
   - c1 = -a³
   - c2 = 3a² + 3a³
   - c3 = -6a² - 3a - 3a³
   - c4 = 1 + 3a + a³ + 3a²

Common configurations:
- T3(8, 0.1) provides a smoother alternative to EMA(20)
- T3(13, 0.08) provides a smoother alternative to EMA(40)

Key characteristics:
- Multiple EMA smoothing provides superior noise reduction
- Volume factor allows fine-tuning of smoothness vs. responsiveness
- Minimal lag despite high degree of smoothing
- More sophisticated than standard triple EMAs
- Particularly effective in volatile markets

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = T3(prices; n=4, a=0.7)  # Returns ultra-smooth trend values
```

See also: [`EMA`](@ref), [`TEMA`](@ref)
"""
@inline Base.@propagate_inbounds function T3(prices::Vector{T}; n::Int=10, a::Float64 = 0.7) where T
    EMA1 = EMA(prices; n=n)
	EMA2 = EMA(EMA1; n=n)
	EMA3 = EMA(EMA2; n=n)
	EMA4 = EMA(EMA3; n=n)
	EMA5 = EMA(EMA4; n=n)
	EMA6 = EMA(EMA5; n=n)

	c1 = -a^3
	c2 = 3a^2 + 3a^3
	c3 = -6a^2 - 3a - 3a^3
	c4 = 1 + 3a + a^3 + 3a^2

	return c1 * EMA6 + c2 * EMA5 + c3 * EMA4 + c4 * EMA3
end

@prep_siso T3 n=10 (a=0.7)