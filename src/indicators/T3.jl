"""
    T3(data::Vector{T}; n::Int=10, a::Float64=0.7) where T -> Vector{T}

Calculate Tillson T3 Moving Average — a six-stage EMA combination producing an ultra-smooth, low-lag indicator.

## Parameters
- `data`: Input price vector of any numeric type.
- `n`: Period length for each of the six cascaded EMA stages (default: 10). Valid range: `n >= 1`.
- `a`: Volume factor controlling smoothness vs. responsiveness (default: 0.7). Valid range: `0.0` to `1.0`.
  Higher values produce smoother output; lower values increase responsiveness.

## Returns
Vector of T3 values with the same length as the input.

## Formula
```math
T3 = c_1 \\cdot EMA^6 + c_2 \\cdot EMA^5 + c_3 \\cdot EMA^4 + c_4 \\cdot EMA^3
```

where `EMA^k` denotes the k-th cascaded EMA, and the coefficients are:
```math
c_1 = -a^3, \\quad c_2 = 3a^2 + 3a^3, \\quad c_3 = -6a^2 - 3a - 3a^3, \\quad c_4 = 1 + 3a + a^3 + 3a^2
```

## Interpretation
- Produces an extremely smooth curve with very low lag for a given smoothing level.
- The volume factor `a` controls the trade-off: `a=0.7` (default) provides good balance.
- Better suited for trend identification than for generating precise entry/exit signals.
- Can overshoot in strongly trending markets due to the multi-EMA extrapolation.
- Created by: Tim Tillson (1998).

## Example
```julia
prices = [100.0, 102.0, 104.0, 103.0, 102.0, 105.0, 107.0]
t3 = T3(prices; n=5, a=0.7)
```

## See Also
[`EMA`](@ref), [`TEMA`](@ref), [`DEMA`](@ref)
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