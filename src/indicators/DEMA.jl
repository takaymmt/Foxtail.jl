"""
    DEMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}

Calculate Double Exponential Moving Average (DEMA) — an EMA variant that reduces lag by combining two EMAs.

## Parameters
- `prices`: Input price vector of any numeric type.
- `n`: Smoothing period for both EMA stages (default: 10). Valid range: `n >= 1`.

## Returns
Vector of DEMA values with the same length as the input.

## Formula
```math
DEMA_t = 2 \\cdot EMA_n(P)_t - EMA_n(EMA_n(P))_t
```

## Interpretation
- Developed by Patrick Mulloy (1994) to reduce the inherent lag of standard EMAs.
- More responsive to price changes than a single EMA of equal period.
- Useful for short-to-medium term trend following where reduced lag is critical.
- The `2 * EMA - EMA(EMA)` construction effectively cancels out much of the single-EMA lag.
- Created by: Patrick Mulloy.

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = DEMA(prices; n=4)
```

## See Also
[`EMA`](@ref), [`TEMA`](@ref), [`ZLEMA`](@ref)
"""
@inline Base.@propagate_inbounds function DEMA(prices::Vector{T}; n::Int=10) where T
    EMA1 = EMA(prices; n=n)
	EMA2 = EMA(EMA1; n=n)
	return EMA1 * 2 - EMA2
end

@prep_siso DEMA n=10