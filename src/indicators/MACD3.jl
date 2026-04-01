"""
    MACD3(prices::Vector{Float64}; fast::Int=5, middle::Int=20, slow::Int=40, ma_type::Symbol=:EMA) -> Matrix{Float64}

Calculate Triple MACD — a three-line MACD variant using fast, middle, and slow moving averages.

## Parameters
- `prices`: Input price vector (`Float64`).
- `fast`: Period for the fast moving average (default: 5). Valid range: `fast >= 1`.
- `middle`: Period for the middle moving average (default: 20). Valid range: `middle > fast`.
- `slow`: Period for the slow moving average (default: 40). Valid range: `slow > middle`.
- `ma_type`: Moving average type (default: `:EMA`).
  Options: `:EMA`, `:HAJ` (HMA/ALMA/JMA), `:JAK` (JMA/ALMA/KAMA), `:KAMA`, `:ALMA`.

## Returns
Matrix of size `(length(prices), 3)`:
- Column 1: Fast line (`ALMA(fast_ma - middle_ma, 4)`)
- Column 2: Middle line (`ALMA(fast_ma - slow_ma, 4)`)
- Column 3: Slow line (`ALMA(middle_ma - slow_ma, 4)`)

All output lines are smoothed with `ALMA(n=4, offset=0.9)`.

## Formula
```math
\\begin{aligned}
Fast_t &= ALMA_4(MA_{\\text{fast}}(P) - MA_{\\text{middle}}(P))_t \\\\
Middle_t &= ALMA_4(MA_{\\text{fast}}(P) - MA_{\\text{slow}}(P))_t \\\\
Slow_t &= ALMA_4(MA_{\\text{middle}}(P) - MA_{\\text{slow}}(P))_t
\\end{aligned}
```

## Interpretation
- Provides a multi-timeframe momentum view with three difference lines.
- When all three lines are positive and rising: strong bullish momentum.
- When all three lines are negative and falling: strong bearish momentum.
- Crossovers between the lines signal shifts in momentum across timeframes.
- Custom MA type combinations (HAJ, JAK, etc.) allow specialized smoothing strategies.

## Example
```julia
prices = rand(100) .* 10 .+ 100.0
result = MACD3(prices; fast=5, middle=20, slow=40, ma_type=:EMA)
```

## See Also
[`MACD`](@ref), [`EMA`](@ref), [`ALMA`](@ref), [`HMA`](@ref)
"""
function MACD3(prices::Vector{Float64}; fast::Int = 5, middle::Int = 20, slow::Int = 40, ma_type::Symbol = :EMA)
    # Calculate MAs
    if ma_type == :Custom1 || ma_type == :HAJ
        fast_ma = HMA(prices; n = fast)
        mddl_ma = ALMA(prices; n = middle)
        slow_ma = JMA(prices; n = slow)
    elseif ma_type == :Custom2 || ma_type == :JAK
        fast_ma = JMA(prices; n = fast)
        mddl_ma = ALMA(prices; n = middle)
        slow_ma = KAMA(prices; n = slow)
    elseif ma_type == :Custom2 || ma_type == :KAMA
        fast_ma = KAMA(prices; n = fast)
        mddl_ma = KAMA(prices; n = middle)
        slow_ma = KAMA(prices; n = slow)
    elseif ma_type == :Custom3 || ma_type == :ALMA
        fast_ma = ALMA(prices; n = fast)
        mddl_ma = ALMA(prices; n = middle)
        slow_ma = ALMA(prices; n = slow)
    else
        fast_ma = EMA(prices; n = fast)
        mddl_ma = EMA(prices; n = middle)
        slow_ma = EMA(prices; n = slow)
    end

    # Calculate MACD line
    fast_line = fast_ma - mddl_ma
    mddl_line = fast_ma - slow_ma
    slow_line = mddl_ma - slow_ma

    # Combine results
    results = zeros(length(prices), 3)
    results[:, 1] = ALMA(fast_line; n = 4, offset=0.9)
    results[:, 2] = ALMA(mddl_line; n = 4, offset=0.9)
    results[:, 3] = ALMA(slow_line; n = 4, offset=0.9)

    return results
end

@prep_simo MACD3 [Fast, Middle, Slow] fast=5 middle=20 slow=40 ma_type=EMA