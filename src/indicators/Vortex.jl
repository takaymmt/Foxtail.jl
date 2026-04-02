"""
    Vortex(prices::Matrix{Float64}; n::Int=14) -> Matrix{Float64}

Calculate Vortex Indicator — identifies trend direction and strength using positive and negative vortex movement.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: Lookback period for summing vortex movement and true range (default: 14). Valid range: `n >= 1`.

## Returns
Matrix of size `(rows, 2)`:
- Column 1: VI+ (Positive Vortex Indicator)
- Column 2: VI- (Negative Vortex Indicator)

## Formula
```math
VM^+_i = |H_i - L_{i-1}|, \\quad VM^-_i = |L_i - H_{i-1}|
```
```math
VI^+_i = \\frac{\\sum_{j=i-n+1}^{i} VM^+_j}{\\sum_{j=i-n+1}^{i} TR_j}, \\quad
VI^-_i = \\frac{\\sum_{j=i-n+1}^{i} VM^-_j}{\\sum_{j=i-n+1}^{i} TR_j}
```

## Interpretation
- VI+ > VI-: uptrend.
- VI- > VI+: downtrend.
- VI+ crossing above VI-: bullish signal.
- VI- crossing above VI+: bearish signal.
- Values typically oscillate around 1.0 (range roughly 0.5 to 2.0).
- Created by: Etienne Botes and Douglas Siepman (2010).

## Example
```julia
# prices: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 104.0 99.0 100.0]
result = Vortex(prices; n=2)
# result[:,1] = VI+, result[:,2] = VI-
```

## See Also
[`DMI`](@ref), [`ATR`](@ref), [`Aroon`](@ref)
"""
@inline Base.@propagate_inbounds function Vortex(prices::Matrix{Float64}; n::Int=14)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end

    if n < 1
        throw(ArgumentError("period n must be positive"))
    end

    nrows = size(prices, 1)

    highs  = @view prices[:, 1]
    lows   = @view prices[:, 2]
    closes = @view prices[:, 3]

    vi_plus  = zeros(nrows)
    vi_minus = zeros(nrows)

    cb_vm_plus  = CircBuff{Float64}(n)
    cb_vm_minus = CircBuff{Float64}(n)
    cb_tr       = CircBuff{Float64}(n)

    sum_vm_plus  = 0.0
    sum_vm_minus = 0.0
    sum_tr       = 0.0

    @inbounds for i in 1:nrows
        if i == 1
            # Bar 1: no previous bar, VM = 0.0
            vm_plus_i  = 0.0
            vm_minus_i = 0.0
            tr_i = highs[1] - lows[1]
        else
            vm_plus_i  = abs(highs[i] - lows[i-1])
            vm_minus_i = abs(lows[i] - highs[i-1])
            tr_i = max(highs[i] - lows[i], abs(highs[i] - closes[i-1]), abs(lows[i] - closes[i-1]))
        end

        if isfull(cb_vm_plus)
            sum_vm_plus  -= first(cb_vm_plus)
            sum_vm_minus -= first(cb_vm_minus)
            sum_tr       -= first(cb_tr)
        end

        push!(cb_vm_plus, vm_plus_i)
        push!(cb_vm_minus, vm_minus_i)
        push!(cb_tr, tr_i)

        sum_vm_plus  += vm_plus_i
        sum_vm_minus += vm_minus_i
        sum_tr       += tr_i

        if sum_tr > 0.0
            vi_plus[i]  = sum_vm_plus / sum_tr
            vi_minus[i] = sum_vm_minus / sum_tr
        end
    end

    return hcat(vi_plus, vi_minus)
end

@prep_mimo Vortex [High, Low, Close] [VIPlus, VIMinus] n=14
