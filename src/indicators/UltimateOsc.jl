"""
    UltimateOsc(prices::Matrix{Float64}; fast::Int=7, medium::Int=14, slow::Int=28) -> Vector{Float64}

Calculate Ultimate Oscillator (UO) — a multi-timeframe momentum oscillator that combines buying pressure over three different periods to reduce false signals.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `fast`: Short period (default: 7). Valid range: `fast >= 1`.
- `medium`: Medium period (default: 14). Valid range: `medium >= 1`.
- `slow`: Long period (default: 28). Valid range: `slow >= 1`.

## Returns
Vector of Ultimate Oscillator values (0-100 scale) with the same length as the number of input rows.

## Formula
```math
\\text{TL}_t = \\min(L_t, C_{t-1}), \\quad
\\text{BP}_t = C_t - \\text{TL}_t, \\quad
\\text{TR}_t = \\max(H_t, C_{t-1}) - \\text{TL}_t
```
```math
\\text{avg}_{\\text{fast}} = \\frac{\\sum \\text{BP}_{\\text{fast}}}{\\sum \\text{TR}_{\\text{fast}}}, \\quad
\\text{avg}_{\\text{med}} = \\frac{\\sum \\text{BP}_{\\text{med}}}{\\sum \\text{TR}_{\\text{med}}}, \\quad
\\text{avg}_{\\text{slow}} = \\frac{\\sum \\text{BP}_{\\text{slow}}}{\\sum \\text{TR}_{\\text{slow}}}
```
```math
\\text{UO}_t = 100 \\times \\frac{4 \\times \\text{avg}_{\\text{fast}} + 2 \\times \\text{avg}_{\\text{med}} + \\text{avg}_{\\text{slow}}}{7}
```

## Interpretation
- Oscillates between 0 and 100.
- Overbought: UO > 70 (potential selling pressure).
- Oversold: UO < 30 (potential buying pressure).
- Combines three timeframes to reduce false divergence signals common in single-period oscillators.
- Created by: Larry Williams (1976).

## Example
```julia
# prices matrix: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 104.0 99.0 100.0]
result = UltimateOsc(prices; fast=2, medium=3, slow=3)
```

## See Also
[`RSI`](@ref), [`ATR`](@ref)
"""
@inline Base.@propagate_inbounds function UltimateOsc(prices::Matrix{Float64}; fast::Int=7, medium::Int=14, slow::Int=28)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High Low Close]"))
    end

    if fast < 1
        throw(ArgumentError("fast period must be positive"))
    end

    if medium < 1
        throw(ArgumentError("medium period must be positive"))
    end

    if slow < 1
        throw(ArgumentError("slow period must be positive"))
    end

    nrows = size(prices, 1)
    results = zeros(nrows)

    highs  = @view prices[:, 1]
    lows   = @view prices[:, 2]
    closes = @view prices[:, 3]

    # Compute True Range using existing TR function
    tr_vals = TR(prices)

    # Compute Buying Pressure
    bp = zeros(nrows)
    @inbounds for i in 2:nrows
        true_low = min(lows[i], closes[i-1])
        bp[i] = closes[i] - true_low
    end
    # Bar 1: bp[1] = 0.0 (no previous close)

    # 6 CircBuffs for rolling sums with O(1) running sums: bp and tr for each period
    bp_fast_cb   = CircBuff{Float64}(fast)
    bp_medium_cb = CircBuff{Float64}(medium)
    bp_slow_cb   = CircBuff{Float64}(slow)
    tr_fast_cb   = CircBuff{Float64}(fast)
    tr_medium_cb = CircBuff{Float64}(medium)
    tr_slow_cb   = CircBuff{Float64}(slow)

    sum_bp_fast   = 0.0
    sum_bp_medium = 0.0
    sum_bp_slow   = 0.0
    sum_tr_fast   = 0.0
    sum_tr_medium = 0.0
    sum_tr_slow   = 0.0

    @inbounds for i in 1:nrows
        # Remove oldest elements if buffers are full
        if isfull(bp_fast_cb)
            sum_bp_fast -= first(bp_fast_cb)
            sum_tr_fast -= first(tr_fast_cb)
        end
        if isfull(bp_medium_cb)
            sum_bp_medium -= first(bp_medium_cb)
            sum_tr_medium -= first(tr_medium_cb)
        end
        if isfull(bp_slow_cb)
            sum_bp_slow -= first(bp_slow_cb)
            sum_tr_slow -= first(tr_slow_cb)
        end

        # Push new values
        push!(bp_fast_cb, bp[i])
        push!(bp_medium_cb, bp[i])
        push!(bp_slow_cb, bp[i])
        push!(tr_fast_cb, tr_vals[i])
        push!(tr_medium_cb, tr_vals[i])
        push!(tr_slow_cb, tr_vals[i])

        # Update running sums
        sum_bp_fast   += bp[i]
        sum_bp_medium += bp[i]
        sum_bp_slow   += bp[i]
        sum_tr_fast   += tr_vals[i]
        sum_tr_medium += tr_vals[i]
        sum_tr_slow   += tr_vals[i]

        # Compute averages with division-by-zero guard
        avg_fast   = sum_tr_fast   == 0.0 ? 0.0 : sum_bp_fast   / sum_tr_fast
        avg_medium = sum_tr_medium == 0.0 ? 0.0 : sum_bp_medium / sum_tr_medium
        avg_slow   = sum_tr_slow   == 0.0 ? 0.0 : sum_bp_slow   / sum_tr_slow

        # Weighted combination
        results[i] = 100.0 * (4.0 * avg_fast + 2.0 * avg_medium + 1.0 * avg_slow) / 7.0
    end

    return results
end

@prep_miso UltimateOsc [High, Low, Close] fast=7 medium=14 slow=28
