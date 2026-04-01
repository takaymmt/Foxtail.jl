"""
    HMA(prices::Vector{T}; n::Int=10) where T -> Vector{T}

Calculate Hull Moving Average (HMA) — a fast, smooth moving average with minimal lag.

## Parameters
- `prices`: Input price vector of any numeric type.
- `n`: Primary smoothing period (default: 10). Valid range: `n >= 2`.

## Returns
Vector of HMA values with the same length as the input.

## Formula
```math
HMA_t = WMA_{\\lfloor\\sqrt{n}\\rfloor}\\!\\Big(2 \\cdot WMA_{\\lfloor n/2 \\rfloor}(P) - WMA_n(P)\\Big)
```

Three-step calculation:
1. Compute `WMA(n/2)` of prices
2. Compute `WMA(n)` of prices
3. Apply `WMA(sqrt(n))` to `2 * step1 - step2`

## Interpretation
- Developed by Alan Hull to virtually eliminate lag while improving smoothness.
- Significantly more responsive to price changes than SMA or EMA of equal period.
- Useful for identifying trend reversals quickly.
- May overshoot during sharp price movements due to the `2 * WMA(n/2) - WMA(n)` extrapolation.
- Created by: Alan Hull (2005).

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = HMA(prices; n=4)
```

## See Also
[`WMA`](@ref), [`EMA`](@ref), [`DEMA`](@ref)
"""
@inline Base.@propagate_inbounds function HMA(prices::Vector{T}; n::Int=10) where T
    WMA1 = WMA(prices; n = div(n, 2))
	WMA2 = WMA(prices; n = n)
	return WMA(WMA1 * 2 - WMA2; n = round(Int, sqrt(n)))
end

@prep_siso HMA n=10