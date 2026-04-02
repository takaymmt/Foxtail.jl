"""
    PVI(data::Matrix{Float64}) -> Vector{Float64}

Calculate Positive Volume Index (PVI) — a cumulative indicator that tracks price changes on days when volume increases.

## Parameters
- `data`: Price/volume matrix with 2 columns `[Close, Volume]` (`Float64`).

## Returns
Vector of PVI values. The first value is `1000.0` (conventional starting value).

## Formula
```math
PVI_1 = 1000 \\\\
PVI_t = \\begin{cases}
PVI_{t-1} \\times \\left(1 + \\frac{C_t - C_{t-1}}{C_{t-1}}\\right) & \\text{if } V_t > V_{t-1} \\\\
PVI_{t-1} & \\text{otherwise}
\\end{cases}
```

## Interpretation
- PVI focuses on days when volume increases, assumed to reflect the "crowd" or uninformed traders.
- Rising PVI on high volume suggests the crowd is buying — may indicate a trend nearing exhaustion.
- PVI is the complement of NVI; together they separate smart money from crowd behavior.
- When PVI is below its moving average (e.g., 255-day EMA), the market is considered bearish.
- Created by: Paul Dysart (1930s), popularized by Norman Fosback.

## Example
```julia
# data: [Close Volume]
data = [100.0 1000.0; 110.0 1500.0; 105.0 1200.0; 115.0 2000.0]
result = PVI(data)
```

## See Also
[`NVI`](@ref), [`OBV`](@ref)
"""
@inline Base.@propagate_inbounds function PVI(data::Matrix{Float64})
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

    # Calculate PVI
    @inbounds for i in 2:n
        if volumes[i] > volumes[i-1]
            results[i] = iszero(closes[i-1]) ? results[i-1] : results[i-1] * (1.0 + (closes[i] - closes[i-1]) / closes[i-1])
        else
            results[i] = results[i-1]
        end
    end

    return results
end

@prep_miso PVI [Close, Volume]
