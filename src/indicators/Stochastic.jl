"""
    Stoch(prices::Matrix{Float64}; n::Int=14, k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA) -> Matrix{Float64}

Calculate Stochastic Oscillator — a momentum indicator comparing closing price to the high-low range.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: Lookback period for raw %K calculation (default: 14). Valid range: `n >= 1`.
- `k_smooth`: Smoothing period for %K line (default: 3). Valid range: `k_smooth >= 1`.
- `d_smooth`: Smoothing period for %D signal line (default: 3). Valid range: `d_smooth >= 1`.
- `ma_type`: Moving average type for smoothing (default: `:SMA`).
  Options: `:SMA`, `:EMA`, `:SMMA`/`:RMA`.

## Returns
Matrix of size `(rows, 2)`:
- Column 1: %K line (smoothed stochastic)
- Column 2: %D line (signal line, smoothed %K)

## Formula
```math
\\%K_{raw} = 100 \\times \\frac{C_t - LL_n}{HH_n - LL_n}, \\quad
\\%K = MA_{k}(\\%K_{raw}), \\quad
\\%D = MA_{d}(\\%K)
```

Where `HH_n` = highest high and `LL_n` = lowest low over the last `n` periods.

## Interpretation
- Oscillates between 0 and 100.
- Overbought: %K >= 80 (potential reversal downward).
- Oversold: %K <= 20 (potential reversal upward).
- %K crossing above %D: bullish signal.
- %K crossing below %D: bearish signal.
- Created by: George Lane (1950s).

## Example
```julia
# prices: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 107.0 102.0 105.0]
result = Stoch(prices; n=2, k_smooth=1, d_smooth=1)
# result[:,1] = %K, result[:,2] = %D
```

## See Also
[`StochRSI`](@ref), [`WR`](@ref), [`RSI`](@ref)
"""
@inline Base.@propagate_inbounds function Stoch(prices::Matrix{Float64}; n::Int = 14, k_smooth::Int = 3, d_smooth::Int = 3, ma_type::Symbol = :SMA)
	period = n
	if size(prices, 2) != 3
		throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
	end

	if period < 1 || k_smooth < 1 || d_smooth < 1
		throw(ArgumentError("periods must be positive"))
	end

	len = size(prices, 1)
	if len < period
		throw(ArgumentError("price series length must be greater than period"))
	end

	# Extract price data
	highs = @view prices[:, 1]
	lows = @view prices[:, 2]
	closes = @view prices[:, 3]

	# Pre-allocate arrays
	raw_k = zeros(len)
	slow_k = zeros(len)
	slow_d = zeros(len)

	mmq = MinMaxQueue{Float64}(period+1)

	@inbounds for i in 1:period
		update!(mmq, highs[i], lows[i], i)

		w_max = get_max(mmq)
		w_min = get_min(mmq)

		denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (closes[i] - w_min) / denominator
		end
	end

	@inbounds for i in (period+1):len
		remove_old!(mmq, i - period)
		update!(mmq, highs[i], lows[i], i)

		w_max = get_max(mmq)
		w_min = get_min(mmq)

		denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (closes[i] - w_min) / denominator
		end
	end

	# Apply first smoothing to get Slow %K
	slow_k = apply_ma(raw_k, ma_type; n=k_smooth)

	# Calculate %D by smoothing Slow %K
	slow_d = apply_ma(slow_k, ma_type; n=d_smooth)

	return hcat(slow_k, slow_d)
end

@prep_mimo Stoch [High, Low, Close] [K, D] n=14 k_smooth=3 d_smooth=3 ma_type=SMA