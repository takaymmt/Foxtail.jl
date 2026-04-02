"""
    CMF(prices::Matrix{Float64}; n::Int=20) -> Vector{Float64}

Calculate Chaikin Money Flow (CMF) — a volume-weighted indicator measuring buying and selling pressure over a period.

## Parameters
- `prices`: Price/volume matrix with 4 columns `[High, Low, Close, Volume]` (`Float64`).
- `n`: Lookback period for the rolling sum (default: 20). Valid range: `n >= 1`.

## Returns
Vector of CMF values (range: -1 to +1) with the same length as the number of input rows.

## Formula
```math
CLV_t = \\frac{2C_t - H_t - L_t}{H_t - L_t}, \\quad
MFV_t = CLV_t \\times V_t
```
```math
CMF_t = \\frac{\\sum_{i=t-n+1}^{t} MFV_i}{\\sum_{i=t-n+1}^{t} V_i}
```

Edge cases: when `High == Low`, `CLV = 0`; when sum of Volume is 0, `CMF = 0`.

## Interpretation
- Oscillates between -1 and +1.
- CMF > 0 indicates buying pressure (accumulation).
- CMF < 0 indicates selling pressure (distribution).
- The magnitude indicates the strength of the money flow.
- Persistent positive CMF confirms an uptrend; persistent negative CMF confirms a downtrend.
- Based on the Accumulation/Distribution Line (ADL) concept.
- Created by: Marc Chaikin.

## Example
```julia
# prices matrix: [High Low Close Volume]
prices = [105.0 100.0 103.0 1000.0; 106.0 101.0 104.0 1200.0; 104.0 99.0 100.0 800.0]
result = CMF(prices; n=2)
```

## See Also
[`ADL`](@ref), [`ChaikinOsc`](@ref), [`OBV`](@ref)
"""
@inline Base.@propagate_inbounds function CMF(prices::Matrix{Float64}; n::Int=20)
    if size(prices, 2) != 4
        throw(ArgumentError("prices matrix must have 4 columns [High Low Close Volume]"))
    end

    if n < 1
        throw(ArgumentError("period must be positive"))
    end

    nrows = size(prices, 1)
    results = zeros(nrows)

    highs   = @view prices[:, 1]
    lows    = @view prices[:, 2]
    closes  = @view prices[:, 3]
    volumes = @view prices[:, 4]

    # Pre-compute CLV and Money Flow Volume
    mfv = Vector{Float64}(undef, nrows)

    @inbounds for i in 1:nrows
        hl_range = highs[i] - lows[i]
        if hl_range <= 0.0 || volumes[i] == 0.0
            mfv[i] = 0.0
        else
            clv = (2.0 * closes[i] - highs[i] - lows[i]) / hl_range
            clv = clamp(clv, -1.0, 1.0)
            mfv[i] = clv * volumes[i]
        end
    end

    sum_mfv = 0.0
    sum_vol = 0.0

    @inbounds for i in 1:nrows
        # Add the new element entering the window
        sum_mfv += mfv[i]
        sum_vol += volumes[i]

        # Subtract the element leaving the window
        if i > n
            sum_mfv -= mfv[i - n]
            sum_vol -= volumes[i - n]
        end

        # Clamp to zero: FP drift from repeated add/subtract can yield tiny negatives
        sum_vol = max(0.0, sum_vol)

        if iszero(sum_vol)
            results[i] = 0.0
        else
            results[i] = sum_mfv / sum_vol
        end
    end

    return results
end

@prep_miso CMF [High, Low, Close, Volume] n=20
