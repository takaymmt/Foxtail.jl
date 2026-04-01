"""
    TMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}

Calculate Triangular Moving Average (TMA) — a double-smoothed SMA that produces a triangular weight distribution.

## Parameters
- `prices`: Input price vector of any numeric type.
- `n`: Period for the first SMA stage (default: 10). Valid range: `n >= 1`.

## Returns
Vector of TMA values with the same length as the input.

## Formula
```math
TMA_t = SMA_{\\lfloor(n+1)/2\\rfloor}\\!\\big(SMA_n(P)\\big)_t
```

The double SMA application creates a triangular weight distribution where middle values
receive the highest weight and edge values taper off symmetrically.

## Interpretation
- Smoother than a single SMA due to the double-smoothing effect.
- Produces a symmetrical weight distribution centered on the middle of the window.
- More lag than SMA due to double application, but significantly less noise.
- Best used in ranging or moderately trending markets where smoothness is preferred.
- Also available as `TRIMA` (alias for TSFrame input).

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0]
result = TMA(prices; n=3)
```

## See Also
[`SMA`](@ref), [`DEMA`](@ref), [`TEMA`](@ref)
"""
@inline Base.@propagate_inbounds function TMA(prices::Vector{T}; n::Int=10) where T
    SMA1 = SMA(prices; n=n)
    return SMA(SMA1; n=div(n+1, 2))
end

@prep_siso TMA n=10

TRIMA(ts::TSFrame; n::Int=10, field::Symbol = :Close) = TMA(ts; n=n, field=field)
export TRIMA