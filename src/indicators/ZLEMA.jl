"""
    ZLEMA(data::Vector{T}; n::Int=10) where T -> Vector{T}

Calculate Zero-Lag Exponential Moving Average (ZLEMA) — an EMA variant that compensates for lag using a de-lagged price input.

## Parameters
- `data`: Input price vector of any numeric type.
- `n`: Smoothing period (default: 10). Valid range: `n >= 1`.

## Returns
Vector of ZLEMA values. The first value equals the first input price.

## Formula
```math
P'_t = 2 \\cdot P_t - P_{t - \\lfloor(n-1)/2\\rfloor}, \\quad
ZLEMA_t = \\alpha \\cdot P'_t + (1 - \\alpha) \\cdot ZLEMA_{t-1}, \\quad
\\alpha = \\frac{2}{n + 1}
```

By using a modified price series (`P'`) that subtracts the lagged price, ZLEMA compensates
for the inherent delay in exponential smoothing.

## Interpretation
- Reduces lag compared to standard EMA by incorporating a look-back correction.
- More responsive to recent price changes while maintaining EMA-like smoothness.
- Useful for short-to-medium term trend following where lag reduction is important.
- May produce more false signals than EMA in choppy markets due to the de-lagging.

## Example
```julia
prices = [100.0, 101.0, 102.0, 103.0, 104.0]
zlema = ZLEMA(prices; n=3)
```

## See Also
[`EMA`](@ref), [`DEMA`](@ref), [`TEMA`](@ref)
"""
@inline Base.@propagate_inbounds function ZLEMA(data::Vector{T}; n::Int=10) where T
    period = n
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    lag = 0
    alpha = 0.0
    emadata = 0.0

    @inbounds results[1] = data[1]
    push!(buf, data[1])

    @inbounds for i in 2:period
        price = data[i]
        push!(buf, price)
        lag = -round(Int, (i-1) / 2)
        alpha = 2 / (1+i)
        emadata = 2 * price - buf[lag]
        results[i] = emadata * alpha + results[i-1] * (1-alpha)
    end

    @inbounds for i in (period+1):length(data)
        price = data[i]
        push!(buf, price)
        emadata = 2 * price - buf[lag]
        results[i] = emadata * alpha + results[i-1] * (1-alpha)
    end
    return results
end

@prep_siso ZLEMA n=10