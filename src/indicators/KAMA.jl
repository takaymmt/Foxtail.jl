"""
    KAMA(data::AbstractVector{T}; n::Int=10, fast::Int=2, slow::Int=30) where T <: AbstractFloat -> Vector{T}

Calculate Kaufman's Adaptive Moving Average (KAMA) — an adaptive MA that adjusts speed based on market efficiency.

## Parameters
- `data`: Input price series (must be `AbstractFloat` subtype).
- `n`: Lookback period for the Efficiency Ratio (default: 10). Valid range: `n >= 1`.
- `fast`: Fast EMA period used when the market is most efficient/trending (default: 2). Valid range: `fast >= 1`.
- `slow`: Slow EMA period used when the market is least efficient/noisy (default: 30). Valid range: `slow > fast`.

## Returns
Vector of KAMA values. The first value equals the first input price.

## Formula
```math
\\begin{aligned}
ER_t &= \\frac{|P_t - P_{t-n}|}{\\sum_{i=1}^{n} |P_{t-n+i} - P_{t-n+i-1}|} \\\\[4pt]
SC_t &= \\left[ER_t \\cdot \\left(\\frac{2}{\\text{fast}+1} - \\frac{2}{\\text{slow}+1}\\right) + \\frac{2}{\\text{slow}+1}\\right]^2 \\\\[4pt]
KAMA_t &= KAMA_{t-1} + SC_t \\cdot (P_t - KAMA_{t-1})
\\end{aligned}
```

## Interpretation
- Adapts its smoothing speed based on the Efficiency Ratio (ER): trending markets (high ER) produce fast tracking; choppy markets (low ER) produce heavy smoothing.
- Virtually eliminates whipsaws in sideways markets while staying responsive in trends.
- Developed by Perry Kaufman and described in "Smarter Trading" (1995).
- Created by: Perry Kaufman.

## Example
```julia
prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0]
result = KAMA(prices; n=10, fast=2, slow=30)
```

## See Also
[`EMA`](@ref), [`JMA`](@ref), [`ALMA`](@ref)
"""
@inline Base.@propagate_inbounds function KAMA(data::AbstractVector{T}; n::Int=10, fast::Int=2, slow::Int=30) where T <: AbstractFloat
    period = n
    len = length(data)
    kama = Vector{T}(undef, len)
    kama[1] = data[1]

    fast_sc = T(2) / (fast + T(1))
    slow_sc = T(2) / (slow + T(1))
    sc_diff = fast_sc - slow_sc

    @inbounds begin
        volatility = zero(T)

        for i in 2:period
            volatility += abs(data[i] - data[i-1])
            direction = abs(data[i] - data[1])
            er = volatility > zero(T) ? direction / volatility : zero(T)
            sc = (er * sc_diff + slow_sc)^2
            kama[i] = kama[i-1] + sc * (data[i] - kama[i-1])
        end

        last_change = zero(T)
        for i in period+1:len
            volatility += abs(data[i] - data[i-1]) - last_change
            direction = abs(data[i] - data[i-period+1])
            er = direction / volatility
            sc = (er * sc_diff + slow_sc)^2
            kama[i] = kama[i-1] + sc * (data[i] - kama[i-1])
            last_change = abs(data[i-period+1] - data[i-period])
        end
    end

    return kama
end

@prep_siso KAMA n=10 (fast=2, slow=30)