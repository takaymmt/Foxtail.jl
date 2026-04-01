"""
    DPO(prices::Vector{Float64}; n::Int=20) -> Vector{Float64}

Calculate Detrended Price Oscillator (DPO) — removes the trend from prices to identify cycles.

## Parameters
- `prices`: Input price vector (`Float64`), typically closing prices.
- `n`: Period for the SMA (default: 20). Valid range: `n >= 1`.

## Returns
Vector of DPO values. During the startup period (first `shift` elements where
`shift = div(n, 2) + 1`), values are `0.0`.

## Formula
```math
\\begin{aligned}
shift &= \\lfloor n/2 \\rfloor + 1 \\\\
DPO_t &= P_t - SMA_n(P)_{t - shift} \\quad \\text{for } t > shift \\\\
DPO_t &= 0.0 \\quad \\text{for } t \\leq shift
\\end{aligned}
```

## Interpretation
- DPO removes the trend component to highlight price cycles.
- Positive values indicate price is above the lagged moving average.
- Negative values indicate price is below the lagged moving average.
- Useful for identifying overbought/oversold conditions within cycles.

## Example
```julia
prices = collect(1.0:50.0)
result = DPO(prices; n=20)
```

## See Also
[`SMA`](@ref), [`ROC`](@ref)
"""
@inline Base.@propagate_inbounds function DPO(prices::Vector{Float64}; n::Int=20)
    len = length(prices)
    shift = div(n, 2) + 1

    sma_values = apply_ma(prices, :SMA; n=n)

    result = zeros(len)

    @inbounds for i in (shift+1):len
        idx = i - shift
        if idx >= 1
            result[i] = prices[i] - sma_values[idx]
        end
    end

    return result
end

@prep_siso DPO n=20
