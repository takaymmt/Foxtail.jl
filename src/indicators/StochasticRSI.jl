"""
    StochRSI(prices::Vector{Float64}; n::Int=14, k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA)

Calculates the Stochastic RSI (StochRSI) indicator, which combines the Relative Strength Index (RSI) with the Stochastic oscillator.

# Arguments
- `prices::Vector{Float64}`: Vector of price data
- `n::Int=14`: Period for RSI calculation and stochastic window
- `k_smooth::Int=3`: Smoothing period for %K line
- `d_smooth::Int=3`: Smoothing period for %D line (signal line)
- `ma_type::Symbol=:SMA`: Type of moving average to use. Options: `:SMA`, `:EMA`, `:SMMA`/`:RMA`, `:WMA`

# Returns
- `Matrix{Float64}`: A matrix with two columns:
  - Column 1: Stochastic RSI %K line (smoothed)
  - Column 2: Stochastic RSI %D line (signal line)

# Notes
- The StochRSI applies the stochastic formula to RSI values instead of price data
- Values are normalized between 0 and 100
- Default to 50 when the RSI range is zero to avoid division by zero
- Requires at least `2n` data points due to both RSI and Stochastic calculations

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = StochRSI(prices)
result = StochRSI(prices; n=4, k_smooth=2, d_smooth=2, ma_type=:SMA)
# result[:,1] contains StochRSI %K line
# result[:,2] contains StochRSI %D line
```
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
    if ma_type == :SMA
        stoch_k = SMA(raw_k; n=k_smooth)
    elseif ma_type == :EMA
        stoch_k = EMA(raw_k; n=k_smooth)
    elseif ma_type == :SMMA || ma_type == :RMA
        stoch_k = SMMA(raw_k; n=k_smooth)
    elseif ma_type == :WMA
        stoch_k = WMA(raw_k; n=k_smooth)
    else
        throw(ArgumentError("ma_type must be one of: :SMA, :EMA, :SMMA, :WMA"))
    end

    # Calculate %D by smoothing %K
    if ma_type == :SMA
        stoch_d = SMA(stoch_k; n=d_smooth)
    elseif ma_type == :EMA
        stoch_d = EMA(stoch_k; n=d_smooth)
    elseif ma_type == :SMMA || ma_type == :RMA
        stoch_d = SMMA(stoch_k; n=d_smooth)
    elseif ma_type == :WMA
        stoch_d = WMA(stoch_k; n=d_smooth)
    else
        throw(ArgumentError("ma_type must be one of: :SMA, :EMA, :SMMA, :WMA"))
    end

    return hcat(stoch_k, stoch_d)
end

@prep_simo StochRSI [K, D] n=14 ma_type=SMA k_smooth=3 d_smooth=3