"""
    OBV(data::Matrix{Float64}) -> Vector{Float64}

Calculate On Balance Volume (OBV) — a cumulative volume-based indicator that measures buying and selling pressure.

## Parameters
- `data`: Price/volume matrix with 2 columns `[Close, Volume]` (`Float64`).

## Returns
Vector of OBV values. The first value equals the first period's volume.

## Formula
```math
OBV_t = \\begin{cases}
OBV_{t-1} + V_t & \\text{if } C_t > C_{t-1} \\\\
OBV_{t-1} - V_t & \\text{if } C_t < C_{t-1} \\\\
OBV_{t-1} & \\text{if } C_t = C_{t-1}
\\end{cases}
```

## Interpretation
- Rising OBV indicates buying pressure (accumulation), potentially preceding price increases.
- Falling OBV indicates selling pressure (distribution), potentially preceding price decreases.
- OBV divergence from price is a strong signal: if price makes new highs but OBV does not, distribution may be occurring.
- OBV is a leading indicator — volume changes often precede price changes.
- Most effective in trending markets; less meaningful during low-volume periods.
- Created by: Joe Granville (1963, "Granville's New Key to Stock Market Profits").

## Example
```julia
# data: [Close Volume]
data = [100.0 1000.0; 102.0 1200.0; 101.0 800.0; 103.0 1500.0]
result = OBV(data)
```

## See Also
[`ADL`](@ref), [`ChaikinOsc`](@ref)
"""
@inline Base.@propagate_inbounds function OBV(data::Matrix{Float64})
    if size(data, 2) != 2
        throw(ArgumentError("data matrix must have 2 columns [close volume]"))
    end

    n = size(data, 1)
    results = zeros(n)

    # Extract price and volume data
    closes = @view data[:, 1]
    volumes = @view data[:, 2]

    # Initialize first value with first volume
    @inbounds results[1] = volumes[1]

    # Calculate OBV
    @inbounds for i in 2:n
        if closes[i] > closes[i-1]
            results[i] = results[i-1] + volumes[i]
        elseif closes[i] < closes[i-1]
            results[i] = results[i-1] - volumes[i]
        else
            results[i] = results[i-1]
        end
    end

    return results
end

@prep_miso OBV [Close, Volume]