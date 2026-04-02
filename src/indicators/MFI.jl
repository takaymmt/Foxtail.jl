"""
    MFI(prices::Matrix{Float64}; n::Int=14) -> Vector{Float64}

Calculate Money Flow Index (MFI) — a volume-weighted momentum oscillator measuring buying and selling pressure.

## Parameters
- `prices`: Price/volume matrix with 4 columns `[High, Low, Close, Volume]` (`Float64`).
- `n`: Lookback period for the rolling money flow sum (default: 14). Valid range: `n >= 1`.

## Returns
Vector of MFI values (0-100 scale) with the same length as the number of input rows.

## Formula
```math
TP_t = \\frac{H_t + L_t + C_t}{3}, \\quad
MF_t = TP_t \\times V_t
```
```math
\\text{Positive MF: } MF_t \\text{ when } TP_t > TP_{t-1}, \\quad
\\text{Negative MF: } MF_t \\text{ when } TP_t < TP_{t-1}
```
```math
MFR_t = \\frac{\\sum \\text{Positive MF over } n}{\\sum \\text{Negative MF over } n}, \\quad
MFI_t = 100 - \\frac{100}{1 + MFR_t}
```

Edge cases: when Negative MF sum is 0, MFI = 100; when Positive MF sum is 0, MFI = 0.

## Interpretation
- Oscillates between 0 and 100.
- Overbought: MFI >= 80 (potential selling pressure building).
- Oversold: MFI <= 20 (potential buying pressure building).
- MFI is often called "volume-weighted RSI" as it incorporates volume into the RSI framework.
- Divergence between MFI and price can signal reversals.
- Created by: Gene Quong and Avrum Soudack.

## Example
```julia
# prices matrix: [High Low Close Volume]
prices = [105.0 100.0 103.0 1000.0; 106.0 101.0 104.0 1200.0; 104.0 99.0 100.0 800.0]
result = MFI(prices; n=2)
```

## See Also
[`RSI`](@ref), [`OBV`](@ref), [`ADL`](@ref)
"""
@inline Base.@propagate_inbounds function MFI(prices::Matrix{Float64}; n::Int=14)
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

    # Pre-compute typical price and money flow
    tp = Vector{Float64}(undef, nrows)
    mf = Vector{Float64}(undef, nrows)

    @inbounds for i in 1:nrows
        tp[i] = (highs[i] + lows[i] + closes[i]) / 3.0
        mf[i] = tp[i] * volumes[i]
    end

    # Pre-classify each bar's money flow as positive or negative
    pos_mf = zeros(nrows)
    neg_mf = zeros(nrows)

    @inbounds for j in 2:nrows
        if tp[j] > tp[j-1]
            pos_mf[j] = mf[j]
        elseif tp[j] < tp[j-1]
            neg_mf[j] = mf[j]
        end
        # tp[j] == tp[j-1]: both remain 0.0 (neutral)
        # Note: j == 1 is not reached here; pos_mf[1]/neg_mf[1] stay 0.0 from initialization
    end

    pos_flow = 0.0
    neg_flow = 0.0

    @inbounds for i in 1:nrows
        # Add the new element entering the window
        pos_flow += pos_mf[i]
        neg_flow += neg_mf[i]

        # Subtract the element leaving the window
        if i > n
            pos_flow -= pos_mf[i - n]
            neg_flow -= neg_mf[i - n]
        end

        # Clamp to zero: FP drift from repeated add/subtract can yield tiny negatives
        pos_flow = max(0.0, pos_flow)
        neg_flow = max(0.0, neg_flow)

        if neg_flow == 0.0 && pos_flow == 0.0
            results[i] = 100.0  # No flow at all (e.g., first bar only)
        elseif neg_flow == 0.0
            results[i] = 100.0
        elseif pos_flow == 0.0
            results[i] = 0.0
        else
            results[i] = 100.0 - 100.0 / (1.0 + pos_flow / neg_flow)
        end
    end

    return results
end

@prep_miso MFI [High, Low, Close, Volume] n=14
