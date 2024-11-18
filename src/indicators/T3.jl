"""
    T3(data::Vector{T}; n::Int=10, a::Float64=0.7) where T

Calculate T3 Moving Average (Tillson T3) for a given time series.

# Arguments
- `data::Vector{T}`: Input price vector
- `n::Int=10`: Period length for EMA calculations
- `a::Float64=0.7`: Volume factor controlling smoothness vs. responsiveness

# Returns
- `Vector{T}`: T3 moving average values

# Details
T3 is a sophisticated moving average developed by Tim Tillson that combines multiple
EMAs with a volume factor to produce a smooth, responsive indicator with minimal lag.

The calculation involves:
1. Six cascaded EMAs: EMA1 through EMA6
2. Weighted combination using coefficients derived from volume factor a:
   - c1 = -a³
   - c2 = 3a² + 3a³
   - c3 = -6a² - 3a - 3a³
   - c4 = 1 + 3a + a³ + 3a²

# Examples
```julia
prices = [100.0, 102.0, 104.0, 103.0, 102.0]
t3 = T3(prices)  # Using default n=10, a=0.7
t3_custom = T3(prices; n=8, a=0.618)  # Custom parameters
```

See also: [`EMA`](@ref)
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