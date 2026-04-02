"""
    NVI(data::Matrix{Float64}) -> Vector{Float64}

Calculate Negative Volume Index (NVI) — a cumulative indicator that tracks price changes on days when volume decreases.

## Parameters
- `data`: Price/volume matrix with 2 columns `[Close, Volume]` (`Float64`).

## Returns
Vector of NVI values. The first value is `1000.0` (conventional starting value).

## Formula
```math
NVI_1 = 1000 \\\\
NVI_t = \\begin{cases}
NVI_{t-1} \\times \\left(1 + \\frac{C_t - C_{t-1}}{C_{t-1}}\\right) & \\text{if } V_t < V_{t-1} \\\\
NVI_{t-1} & \\text{otherwise}
\\end{cases}
```

## Interpretation
- NVI focuses on days when volume decreases, assumed to reflect "smart money" activity.
- Rising NVI suggests smart money is buying — a bullish signal.
- Falling NVI suggests smart money is selling — a bearish signal.
- NVI is often used with a long-term moving average (e.g., 255-day EMA) for signal generation.
- When NVI is above its moving average, the market is considered bullish.
- Created by: Paul Dysart (1930s), popularized by Norman Fosback.

## Example
```julia
# data: [Close Volume]
data = [100.0 2000.0; 110.0 1500.0; 105.0 1800.0; 115.0 1200.0]
result = NVI(data)
```

## See Also
[`PVI`](@ref), [`OBV`](@ref)
"""
@inline Base.@propagate_inbounds function NVI(data::Matrix{Float64})
    if size(data, 2) != 2
        throw(ArgumentError("data matrix must have 2 columns [close volume]"))
    end

    n = size(data, 1)
    results = zeros(n)

    # Extract price and volume data
    closes = @view data[:, 1]
    volumes = @view data[:, 2]

    # Initialize first value with conventional starting value
    @inbounds results[1] = 1000.0

    # Calculate NVI
    @inbounds for i in 2:n
        if volumes[i] < volumes[i-1]
            results[i] = iszero(closes[i-1]) ? results[i-1] : results[i-1] * (1.0 + (closes[i] - closes[i-1]) / closes[i-1])
        else
            results[i] = results[i-1]
        end
    end

    return results
end

@prep_miso NVI [Close, Volume]
