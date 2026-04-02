"""
    VWAP(data::Matrix{Float64}) -> Vector{Float64}

Calculate Volume Weighted Average Price (VWAP) — a cumulative indicator that weights price by volume.

## Parameters
- `data`: Price/volume matrix with 4 columns `[High, Low, Close, Volume]` (`Float64`).

## Returns
Vector of VWAP values. Each value is the cumulative volume-weighted average of the Typical Price.

## Formula
```math
TP_t = \\frac{H_t + L_t + C_t}{3}, \\quad
VWAP_t = \\frac{\\sum_{i=1}^{t} TP_i \\cdot V_i}{\\sum_{i=1}^{t} V_i}
```

## Interpretation
- VWAP represents the true average price paid, weighted by volume.
- Price above VWAP suggests bullish sentiment; below VWAP suggests bearish sentiment.
- Commonly used by institutional traders for execution benchmarking.
- Most meaningful within a single trading session (intraday); cumulative across sessions in this implementation.
- Created by: Widely adopted by institutional traders since the 1980s.

## Example
```julia
# data: [High Low Close Volume]
data = [105.0 100.0 103.0 1000.0; 106.0 101.0 104.0 1200.0; 104.0 99.0 100.0 800.0]
result = VWAP(data)
```

## See Also
[`OBV`](@ref), [`ADL`](@ref)
"""
# Shared helper: cumulative VWAP from row `from` onward, writing into pre-allocated `results`.
# Pre-`from` entries in `results` are left untouched (caller sets them to zeros or NaN).
@inline function _cumulative_vwap!(results::Vector{Float64}, data::Matrix{Float64}, from::Int)
    highs   = @view data[:, 1]
    lows    = @view data[:, 2]
    closes  = @view data[:, 3]
    volumes = @view data[:, 4]
    cum_tpv = 0.0
    cum_v   = 0.0
    @inbounds for i in from:length(results)
        tp = (highs[i] + lows[i] + closes[i]) / 3.0
        cum_tpv += tp * volumes[i]
        cum_v   += volumes[i]
        results[i] = iszero(cum_v) ? 0.0 : cum_tpv / cum_v
    end
end

@inline Base.@propagate_inbounds function VWAP(data::Matrix{Float64})
    if size(data, 2) != 4
        throw(ArgumentError("data matrix must have 4 columns [High Low Close Volume]"))
    end

    n = size(data, 1)
    results = zeros(n)
    _cumulative_vwap!(results, data, 1)
    return results
end

@prep_miso VWAP [High, Low, Close, Volume]
