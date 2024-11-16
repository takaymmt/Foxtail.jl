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

# function StochRSI(ts::TSFrame, period::Int=14; field::Symbol=:Close, ma_type::Symbol=:SMA)
#     prices = ts[:,field]
#     results = StochRSI(prices, period; ma_type=ma_type)
#     colnames = [:StochRSI_K, :StochRSI_D]
#     return TSFrame(results, index(ts), colnames=colnames)
# end
# export StochRSI