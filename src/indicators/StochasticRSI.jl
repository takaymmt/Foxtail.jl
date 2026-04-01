"""
    StochRSI(prices::Vector{Float64}; n::Int=14, k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA) -> Matrix{Float64}

Calculate Stochastic RSI — applies the Stochastic oscillator formula to RSI values instead of raw prices.

## Parameters
- `prices`: Input price vector (`Float64`).
- `n`: Period for both the RSI calculation and the stochastic lookback window (default: 14). Valid range: `n >= 1`.
- `k_smooth`: Smoothing period for %K line (default: 3). Valid range: `k_smooth >= 1`.
- `d_smooth`: Smoothing period for %D signal line (default: 3). Valid range: `d_smooth >= 1`.
- `ma_type`: Moving average type for smoothing (default: `:SMA`).
  Options: `:SMA`, `:EMA`, `:SMMA`/`:RMA`, `:WMA`.

## Returns
Matrix of size `(length(prices), 2)`:
- Column 1: StochRSI %K line (smoothed)
- Column 2: StochRSI %D line (signal)

Requires input length >= `2n`.

## Formula
```math
RSI_t = \\text{RSI}(P, n)_t, \\quad
StochRSI_t = 100 \\times \\frac{RSI_t - \\min(RSI, n)}{\\max(RSI, n) - \\min(RSI, n)}
```

%K and %D are then obtained by smoothing StochRSI with the specified moving average.

## Interpretation
- Combines the momentum measurement of RSI with the sensitivity of the Stochastic oscillator.
- More sensitive and volatile than standard RSI; generates signals more frequently.
- Oscillates between 0 and 100.
- Overbought: >= 80; Oversold: <= 20.
- %K/%D crossovers provide entry/exit signals similar to standard Stochastic.
- Created by: Tushar Chande and Stanley Kroll (1994).

## Example
```julia
prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0]
result = StochRSI(prices; n=4, k_smooth=2, d_smooth=2)
# result[:,1] = %K, result[:,2] = %D
```

## See Also
[`RSI`](@ref), [`Stoch`](@ref)
"""
@inline Base.@propagate_inbounds function StochRSI(prices::Vector{Float64}; n::Int=14, k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA)
    period = n
    if period < 1 || k_smooth < 1 || d_smooth < 1
        throw(ArgumentError("periods must be positive"))
    end

    len = length(prices)
    if len < period * 2  # Need extra data for both RSI and Stochastic calculation
        throw(ArgumentError("price series length must be greater than period * 2"))
    end

    # Calculate RSI first
    rsi = RSI(prices; n=period, ma_type=ma_type)

    raw_k = zeros(len)
    stoch_k = zeros(len)
    stoch_d = zeros(len)

    mmq = MinMaxQueue{Float64}(period+1)

    @inbounds for i in 1:period
        update!(mmq, rsi[i], rsi[i], i)

		w_max = get_max(mmq)
		w_min = get_min(mmq)

		denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (rsi[i] - w_min) / denominator
		end
	end

    @inbounds for i in (period+1):len
		remove_old!(mmq, i - period)
		update!(mmq, rsi[i], rsi[i], i)

		w_max = get_max(mmq)
		w_min = get_min(mmq)

		denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (rsi[i] - w_min) / denominator
		end
	end

    # Apply smoothing to get Stochastic %K
    stoch_k = apply_ma(raw_k, ma_type; n=k_smooth)

    # Calculate %D by smoothing %K
    stoch_d = apply_ma(stoch_k, ma_type; n=d_smooth)

    return hcat(stoch_k, stoch_d)
end

@prep_simo StochRSI [K, D] n=14 ma_type=SMA k_smooth=3 d_smooth=3