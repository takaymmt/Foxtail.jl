"""
    ForceIndex(data::Matrix{Float64}; n::Int=13) -> Vector{Float64}

Calculate Force Index — a volume-weighted momentum indicator that measures the force behind price movements.

## Parameters
- `data`: Price/volume matrix with 2 columns `[Close, Volume]` (`Float64`).
- `n`: EMA smoothing period (default: 13). Valid range: `n >= 1`.

## Returns
Vector of Force Index values smoothed by EMA.

## Formula
```math
\\begin{aligned}
RawForce_1 &= 0 \\\\
RawForce_t &= (Close_t - Close_{t-1}) \\times Volume_t \\quad (t \\geq 2) \\\\
ForceIndex_t &= EMA_n(RawForce)_t
\\end{aligned}
```

## Interpretation
- Positive Force Index: buyers are in control (price rising with volume).
- Negative Force Index: sellers are in control (price falling with volume).
- Force Index crossing zero: potential trend change.
- Short-period (n=2): identifies short-term buying/selling pressure for entry timing.
- Long-period (n=13): confirms broader trend direction.
- Divergence between Force Index and price signals potential reversals.
- Created by: Alexander Elder.

## Example
```julia
# data: [Close Volume]
data = [100.0 1000.0; 102.0 1200.0; 101.0 800.0; 103.0 1500.0]
result = ForceIndex(data; n=13)
```

## See Also
[`OBV`](@ref), [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function ForceIndex(data::Matrix{Float64}; n::Int = 13)
    if size(data, 2) != 2
        throw(ArgumentError("data matrix must have 2 columns [Close, Volume]"))
    end

    len = size(data, 1)
    raw_force = zeros(len)

    # Extract close and volume
    closes = @view data[:, 1]
    volumes = @view data[:, 2]

    # Calculate raw force
    # RawForce[1] = 0 (no previous close)
    @inbounds for i in 2:len
        raw_force[i] = (closes[i] - closes[i-1]) * volumes[i]
    end

    # Smooth with EMA
    return EMA(raw_force; n=n)
end

@prep_miso ForceIndex [Close, Volume] n=13
