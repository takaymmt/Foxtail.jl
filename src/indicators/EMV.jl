"""
    EMV(prices::Matrix{Float64}; n::Int=14) -> Vector{Float64}

Calculate Ease of Movement (EMV) — a volume-weighted momentum indicator relating price change to volume.

## Parameters
- `prices`: Input matrix with columns `[High, Low, Volume]`.
- `n`: Smoothing period for the SMA (default: 14). Valid range: `n >= 1`.

## Returns
Vector of EMV values (SMA-smoothed raw EMV).

## Formula
```math
\\begin{aligned}
DM_t &= \\frac{H_t + L_t}{2} - \\frac{H_{t-1} + L_{t-1}}{2} \\\\
BR_t &= \\frac{V_t / 10^8}{H_t - L_t} \\\\
RawEMV_t &= \\begin{cases} DM_t / BR_t & \\text{if } H_t \\neq L_t \\\\ 0 & \\text{otherwise} \\end{cases} \\\\
EMV_t &= SMA_n(RawEMV)_t
\\end{aligned}
```

## Interpretation
- Positive EMV: price moving up on low volume (easy upward movement).
- Negative EMV: price moving down on low volume (easy downward movement).
- Values near zero: price not moving or heavy volume required.
- Created by: Richard W. Arms Jr.

## Example
```julia
# prices matrix: [High Low Volume]
prices = rand(100, 3) .* [100 100 1e6]
result = EMV(prices; n=14)
```

## See Also
[`OBV`](@ref), [`ADL`](@ref)
"""
@inline Base.@propagate_inbounds function EMV(prices::Matrix{Float64}; n::Int=14)
    len = size(prices, 1)

    high = @view prices[:, 1]
    low  = @view prices[:, 2]
    vol  = @view prices[:, 3]

    raw_emv = zeros(len)

    # First bar: no previous bar, raw_emv[1] = 0.0
    @inbounds for i in 2:len
        distance_moved = (high[i] + low[i]) / 2.0 - (high[i-1] + low[i-1]) / 2.0
        hl_diff = high[i] - low[i]

        if hl_diff == 0.0
            raw_emv[i] = 0.0
        else
            box_ratio = (vol[i] / 100_000_000.0) / hl_diff
            if box_ratio == 0.0
                raw_emv[i] = 0.0
            else
                raw_emv[i] = distance_moved / box_ratio
            end
        end
    end

    return apply_ma(raw_emv, :SMA; n=n)
end

@prep_miso EMV [High, Low, Volume] n=14
