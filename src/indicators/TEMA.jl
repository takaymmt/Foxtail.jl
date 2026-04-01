"""
    TEMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}

Calculate Triple Exponential Moving Average (TEMA) — further reduces lag beyond DEMA by using three cascaded EMAs.

## Parameters
- `prices`: Input price vector of any numeric type.
- `n`: Smoothing period for all three EMA stages (default: 10). Valid range: `n >= 1`.

## Returns
Vector of TEMA values with the same length as the input.

## Formula
```math
TEMA_t = 3 \\cdot EMA_n(P)_t - 3 \\cdot EMA_n(EMA_n(P))_t + EMA_n(EMA_n(EMA_n(P)))_t
```

Equivalently: `TEMA = 3*(EMA1 - EMA2) + EMA3`

## Interpretation
- Developed by Patrick Mulloy (1994) as an extension of DEMA.
- Provides the least lag among EMA/DEMA/TEMA for the same period.
- Superior noise reduction through triple smoothing while maintaining responsiveness.
- Best suited for trending markets; may produce whipsaws in ranging conditions.
- Created by: Patrick Mulloy.

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = TEMA(prices; n=4)
```

## See Also
[`EMA`](@ref), [`DEMA`](@ref), [`T3`](@ref)
"""
@inline Base.@propagate_inbounds function TEMA(prices::Vector{T}; n::Int=10) where T
    EMA1 = EMA(prices; n=n)
	EMA2 = EMA(EMA1; n=n)
	EMA3 = EMA(EMA2; n=n)
	return (EMA1 - EMA2) * 3 + EMA3
end

@prep_siso TEMA n=10