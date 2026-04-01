"""
    BB(prices::Vector{T}; n::Int=14, num_std::Float64=2.0, ma_type::Symbol=:SMA) where T -> Matrix{T}

Calculate Bollinger Bands (BB) — volatility bands placed above and below a moving average.

## Parameters
- `prices`: Input price vector (typically closing prices).
- `n`: Lookback period for the moving average and standard deviation (default: 14). Valid range: `n >= 1`.
  Common values: 20 (standard), 10 (short-term), 50 (long-term).
- `num_std`: Number of standard deviations for the band width (default: 2.0). Valid range: `> 0`.
  Common values: 1.0 (tight), 2.0 (standard), 3.0 (wide).
- `ma_type`: Type of moving average for the middle band (default: `:SMA`).
  Options: `:SMA`, `:EMA`, `:SMMA`.

## Returns
Matrix of size `(length(prices), 3)`:
- Column 1: Middle band (moving average)
- Column 2: Upper band (`middle + num_std * sigma`)
- Column 3: Lower band (`middle - num_std * sigma`)

## Formula
```math
\\begin{aligned}
\\text{Middle}_t &= MA_n(P)_t \\\\
\\text{Upper}_t &= \\text{Middle}_t + k \\cdot \\sigma_t \\\\
\\text{Lower}_t &= \\text{Middle}_t - k \\cdot \\sigma_t
\\end{aligned}
```

where `k = num_std` and `sigma` is the standard deviation over the period.

## Interpretation
- Bands widen during high volatility and narrow during low volatility ("squeeze").
- A Bollinger squeeze (narrow bands) often precedes a significant price move.
- Price touching the upper band may indicate overbought conditions; lower band may indicate oversold.
- Walking the band: in strong trends, price can ride along the upper or lower band.
- Best combined with other indicators (e.g., RSI) for confirmation.
- Created by: John Bollinger (1980s).

## Example
```julia
prices = [100.0, 101.0, 99.0, 102.0, 98.0, 103.0, 97.0]
bb = BB(prices; n=5, num_std=2.0, ma_type=:SMA)
# bb[:,1] = Middle, bb[:,2] = Upper, bb[:,3] = Lower
```

## See Also
[`SMA`](@ref), [`EMA`](@ref), [`ATR`](@ref)
"""
@inline Base.@propagate_inbounds function BB(prices::Vector{T}; n::Int = 14, num_std::Float64 = 2.0, ma_type::Symbol = :SMA) where T
    period = n
    results = zeros(T, (length(prices),3))
    masd = if ma_type == :SMMA
        SMMA_stats(prices; n=period)
    elseif ma_type == :EMA
        EMA_stats(prices; n=period)
    else
        SMA_stats(prices; n=period)
    end
    @inbounds for i in 1:length(prices)
        results[i,1] = masd[i,1]
        results[i,2] = masd[i,1] + num_std * masd[i,2]
        results[i,3] = masd[i,1] - num_std * masd[i,2]
    end
    return results
end

@prep_simo BB [Center, Upper, Lower] n=14 num_std=2.0 ma_type=SMA