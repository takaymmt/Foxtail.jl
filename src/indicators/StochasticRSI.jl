function StochRSI(ts::TSFrame, period::Int=14; field::Symbol=:Close, ma_type::Symbol=:SMA)
    prices = ts[:,field]
    results = StochRSI(prices, period; ma_type=ma_type)
    colnames = [:StochRSI_K, :StochRSI_D]
    return TSFrame(results, index(ts), colnames=colnames)
end

@inline Base.@propagate_inbounds function StochRSI(prices::Vector{Float64}, period::Int=14;
    k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA)

    if period < 1 || k_smooth < 1 || d_smooth < 1
        throw(ArgumentError("periods must be positive"))
    end

    n = length(prices)
    if n < period * 2  # Need extra data for both RSI and Stochastic calculation
        throw(ArgumentError("price series length must be greater than period * 2"))
    end

    # Calculate RSI first
    rsi = RSI(prices, period; smoothing=ma_type)

    raw_k = zeros(n)
    stoch_k = zeros(n)
    stoch_d = zeros(n)

    max_q = MonotoneQueue{Float64}(period+1)
	min_q = MonotoneQueue{Float64}(period+1)

    @inbounds for i in 1:period
		push_back!(max_q, rsi[i], i)
		push_back_min!(min_q, rsi[i], i)

		w_max = get_extreme(max_q)
		w_min = get_extreme(min_q)

		denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (rsi[i] - w_min) / denominator
		end
	end

    @inbounds for i in (period+1):n
		remove_old!(max_q, i - period)
		remove_old!(min_q, i - period)

		push_back!(max_q, rsi[i], i)
		push_back_min!(min_q, rsi[i], i)

		w_max = get_extreme(max_q)
		w_min = get_extreme(min_q)

		denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (rsi[i] - w_min) / denominator
		end
	end

    # Apply smoothing to get Stochastic %K
    if ma_type == :SMA
        stoch_k = SMA(raw_k, k_smooth)
    elseif ma_type == :EMA
        stoch_k = EMA(raw_k, k_smooth)
    elseif ma_type == :SMMA || ma_type == :RMA
        stoch_k = SMMA(raw_k, k_smooth)
    else
        throw(ArgumentError("ma_type must be one of: :SMA, :EMA, :SMMA"))
    end

    # Calculate %D by smoothing %K
    if ma_type == :SMA
        stoch_d = SMA(stoch_k, d_smooth)
    elseif ma_type == :EMA
        stoch_d = EMA(stoch_k, d_smooth)
    elseif ma_type == :SMMA || ma_type == :RMA
        stoch_d = SMMA(stoch_k, d_smooth)
    end

    return hcat(stoch_k, stoch_d)
end

export StochRSI