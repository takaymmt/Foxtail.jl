"""
    ADL(prices::Matrix{T}) where T <: AbstractFloat -> Vector{T}

Calculate Accumulation/Distribution Line (ADL) — a cumulative volume-weighted indicator measuring money flow.

## Parameters
- `prices`: Price/volume matrix with 4 columns `[High, Low, Close, Volume]`.

## Returns
Vector of ADL values. The first period's ADL starts from `0.0 + MFV_1`.
Returns `0.0` contribution for periods where `High == Low` or `Volume == 0`.

## Formula
```math
CLV_t = \\frac{2C_t - L_t - H_t}{H_t - L_t}, \\quad
MFV_t = CLV_t \\times V_t, \\quad
ADL_t = ADL_{t-1} + MFV_t
```

Where CLV is the Close Location Value (ranges from -1 to +1).

## Interpretation
- Rising ADL indicates accumulation (buying pressure exceeds selling).
- Falling ADL indicates distribution (selling pressure exceeds buying).
- ADL divergence from price is a key signal: rising price with falling ADL warns of potential reversal.
- Unlike OBV, ADL weights volume by the close's position within the high-low range, not just direction.
- Forms the basis for the Chaikin Oscillator.
- Created by: Marc Chaikin.

## Example
```julia
# prices: [High Low Close Volume]
prices = [105.0 100.0 103.0 1000.0; 106.0 101.0 105.0 1200.0]
result = ADL(prices)
```

## See Also
[`OBV`](@ref), [`ChaikinOsc`](@ref)
"""
@inline Base.@propagate_inbounds function ADL(prices::Matrix{T}) where T <: AbstractFloat
    n = size(prices, 1)

    # Extract price data
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]
    volumes = @view prices[:, 4]

    # Pre-allocate arrays
    adl = zeros(T,n)

    @inbounds for i in 1:n
        if (highs[i] - lows[i]) == 0 || volumes[i] == 0
            mfv = 0.0
        else
            clv = (2 * closes[i] - lows[i] - highs[i]) / (highs[i] - lows[i])
            mfv = clv * volumes[i]
        end

        # Calculate ADL
        adl[i] = (i > 1 ? adl[i-1] : 0.0) + mfv
    end

    return adl
end

@prep_miso ADL [High, Low, Close, Volume]
