"""
    VPT(data::Matrix{Float64}) -> Vector{Float64}

Calculate Volume Price Trend (VPT) — a cumulative volume-based indicator that relates volume to price change.

## Parameters
- `data`: Price/volume matrix with 2 columns `[Close, Volume]` (`Float64`).

## Returns
Vector of VPT values. The first value is `0.0`.

## Formula
```math
VPT_1 = 0 \\\\
VPT_t = VPT_{t-1} + V_t \\times \\frac{C_t - C_{t-1}}{C_{t-1}}
```

## Interpretation
- Rising VPT indicates volume is flowing in on up-moves, supporting the trend.
- Falling VPT indicates volume is flowing in on down-moves, suggesting distribution.
- VPT divergences from price can signal trend reversals.
- Unlike OBV, VPT weighs volume by the magnitude of price change, making it more proportional.

## Example
```julia
# data: [Close Volume]
data = [100.0 1000.0; 110.0 1500.0; 105.0 1200.0; 115.0 2000.0]
result = VPT(data)
```

## See Also
[`OBV`](@ref), [`ADL`](@ref)
"""
@inline Base.@propagate_inbounds function VPT(data::Matrix{Float64})
    if size(data, 2) != 2
        throw(ArgumentError("data matrix must have 2 columns [close volume]"))
    end

    n = size(data, 1)
    results = zeros(n)

    # Extract price and volume data
    closes = @view data[:, 1]
    volumes = @view data[:, 2]

    # Initialize first value
    @inbounds results[1] = 0.0

    # Calculate VPT
    @inbounds for i in 2:n
        results[i] = results[i-1] + volumes[i] * (closes[i] - closes[i-1]) / closes[i-1]
    end

    return results
end

@prep_miso VPT [Close, Volume]
