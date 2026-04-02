"""
    MassIndex(prices::Matrix{Float64}; n::Int=25, ema_period::Int=9) -> Vector{Float64}

Calculate Mass Index — a volatility indicator that detects trend reversals by measuring the narrowing and widening of the range between high and low prices.

## Parameters
- `prices`: Price matrix with 2 columns `[High, Low]` (`Float64`).
- `n`: Summation period for the EMA ratio rolling sum (default: 25). Valid range: `n >= 1`.
- `ema_period`: EMA smoothing period for the high-low range (default: 9). Valid range: `ema_period >= 1`.

## Returns
Vector of Mass Index values with the same length as the number of input rows.

## Formula
```math
\\text{range}_t = H_t - L_t
```
```math
\\text{single\\_ema}_t = \\text{EMA}(\\text{range}, \\text{ema\\_period})_t, \\quad
\\text{double\\_ema}_t = \\text{EMA}(\\text{single\\_ema}, \\text{ema\\_period})_t
```
```math
\\text{ratio}_t = \\frac{\\text{single\\_ema}_t}{\\text{double\\_ema}_t}, \\quad
\\text{MI}_t = \\sum_{i=t-n+1}^{t} \\text{ratio}_i
```

## Interpretation
- Mass Index typically oscillates around 25 (since it sums ~25 ratios near 1.0).
- A "reversal bulge" occurs when MI rises above 27 then drops below 26.5, signaling a probable trend reversal.
- Direction of reversal is determined by other indicators (e.g., moving average crossover).
- Created by: Donald Dorsey (1992).

## Example
```julia
# prices matrix: [High Low]
prices = [105.0 100.0; 106.0 101.0; 104.0 99.0; 107.0 102.0; 108.0 103.0]
result = MassIndex(prices; n=3, ema_period=2)
```

## See Also
[`ATR`](@ref), [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function MassIndex(prices::Matrix{Float64}; n::Int=25, ema_period::Int=9)
    if size(prices, 2) != 2
        throw(ArgumentError("prices matrix must have 2 columns [High Low]"))
    end

    if n < 1
        throw(ArgumentError("n must be positive"))
    end

    if ema_period < 1
        throw(ArgumentError("ema_period must be positive"))
    end

    nrows = size(prices, 1)
    results = zeros(nrows)

    highs = @view prices[:, 1]
    lows  = @view prices[:, 2]

    range_vec = Vector{Float64}(undef, nrows)
    @inbounds for i in 1:nrows
        range_vec[i] = highs[i] - lows[i]
    end

    single_ema = EMA(range_vec; n=ema_period)
    double_ema = EMA(single_ema; n=ema_period)

    # O(1) running sum
    cb = CircBuff{Float64}(n)
    running_sum = 0.0
    @inbounds for i in 1:nrows
        ratio_i = double_ema[i] == 0.0 ? 0.0 : single_ema[i] / double_ema[i]
        if isfull(cb)
            running_sum -= first(cb)
        end
        push!(cb, ratio_i)
        running_sum += ratio_i
        results[i] = running_sum
    end

    return results
end

@prep_miso MassIndex [High, Low] n=25 ema_period=9
