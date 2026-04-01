"""
    DMI(prices::Matrix{Float64}; n::Int=14) -> Matrix{Float64}

Calculate Directional Movement Index (DMI) / ADX — a trend strength and direction indicator.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: Smoothing period for DI and ADX calculations (default: 14). Valid range: `n >= 1`.

## Returns
Matrix of size `(rows, 3)`:
- Column 1: +DI (Positive Directional Indicator), range [0, 100].
- Column 2: -DI (Negative Directional Indicator), range [0, 100].
- Column 3: ADX (Average Directional Index), range [0, 100].

## Formula
```math
+DM_t = \\begin{cases} H_t - H_{t-1} & \\text{if } H_t - H_{t-1} > L_{t-1} - L_t \\text{ and } H_t > H_{t-1} \\\\ 0 & \\text{otherwise} \\end{cases}
```
```math
-DM_t = \\begin{cases} L_{t-1} - L_t & \\text{if } L_{t-1} - L_t > H_t - H_{t-1} \\text{ and } L_t < L_{t-1} \\\\ 0 & \\text{otherwise} \\end{cases}
```
```math
+DI_t = 100 \\times \\frac{SMMA_n(+DM)_t}{SMMA_n(TR)_t}, \\quad
-DI_t = 100 \\times \\frac{SMMA_n(-DM)_t}{SMMA_n(TR)_t}
```
```math
DX_t = 100 \\times \\frac{|+DI_t - -DI_t|}{+DI_t + -DI_t}, \\quad
ADX_t = SMMA_n(DX)_t
```

## Interpretation
- ADX > 25: strong trend (regardless of direction).
- ADX < 20: weak trend or range-bound market.
- +DI > -DI: bullish pressure dominates.
- -DI > +DI: bearish pressure dominates.
- +DI crossing above -DI: buy signal.
- -DI crossing above +DI: sell signal.
- Created by: J. Welles Wilder Jr. (1978).

## Example
```julia
# prices: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 104.0 99.0 100.0]
result = DMI(prices; n=14)
# result[:,1] = +DI, result[:,2] = -DI, result[:,3] = ADX
```

## See Also
[`ATR`](@ref), [`SMMA`](@ref), [`Supertrend`](@ref)
"""
@inline Base.@propagate_inbounds function DMI(prices::Matrix{Float64}; n::Int=14)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end

    if n < 1
        throw(ArgumentError("period must be positive"))
    end

    len = size(prices, 1)

    highs = @view prices[:, 1]
    lows = @view prices[:, 2]

    # Compute True Range using the existing TR function
    tr_vals = TR(prices)

    # Compute directional movement
    dm_plus = zeros(len)
    dm_minus = zeros(len)

    # i=1: no previous bar, DM = 0 (already initialized to zero)
    @inbounds for i in 2:len
        up_move = highs[i] - highs[i-1]
        down_move = lows[i-1] - lows[i]

        if up_move > down_move && up_move > 0.0
            dm_plus[i] = up_move
        end

        if down_move > up_move && down_move > 0.0
            dm_minus[i] = down_move
        end
    end

    # Smooth using Wilder's smoothing (SMMA/RMA)
    atr_smooth = apply_ma(tr_vals, :SMMA; n=n)
    dm_plus_smooth = apply_ma(dm_plus, :SMMA; n=n)
    dm_minus_smooth = apply_ma(dm_minus, :SMMA; n=n)

    # Calculate DI+ and DI-
    di_plus = zeros(len)
    di_minus = zeros(len)
    dx = zeros(len)

    @inbounds for i in 1:len
        if atr_smooth[i] > 0.0
            di_plus[i] = 100.0 * dm_plus_smooth[i] / atr_smooth[i]
            di_minus[i] = 100.0 * dm_minus_smooth[i] / atr_smooth[i]
        else
            di_plus[i] = 0.0
            di_minus[i] = 0.0
        end

        di_sum = di_plus[i] + di_minus[i]
        if di_sum > 0.0
            dx[i] = 100.0 * abs(di_plus[i] - di_minus[i]) / di_sum
        else
            dx[i] = 0.0
        end
    end

    # Smooth DX to get ADX
    adx = apply_ma(dx, :SMMA; n=n)

    return hcat(di_plus, di_minus, adx)
end

@prep_mimo DMI [High, Low, Close] [DIPlus, DIMinus, ADX] n=14
