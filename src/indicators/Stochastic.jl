function Stoch(ts::TSFrame, period::Int = 14; field::Vector{Symbol} = [:High, :Low, :Close], ma_type::Symbol = :SMA)
	prices = ts[:, field] |> Matrix
	results = Stoch(prices; period = period, ma_type = ma_type)
	colnames = [:Stoch_K, :Stoch_D]
	return TSFrame(results, index(ts), colnames = colnames)
end
export Stoch

function Stoch(prices::Matrix{Float64};
	period::Int = 14,
	k_smooth::Int = 3,
	d_smooth::Int = 3,
	ma_type::Symbol = :SMA)

	if size(prices, 2) != 3
		throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
	end

	if period < 1 || k_smooth < 1 || d_smooth < 1
		throw(ArgumentError("periods must be positive"))
	end

	n = size(prices, 1)
	if n < period
		throw(ArgumentError("price series length must be greater than period"))
	end

	# Extract price data
	highs = @view prices[:, 1]
	lows = @view prices[:, 2]
	closes = @view prices[:, 3]

	# Pre-allocate arrays
	raw_k = zeros(n)
	slow_k = zeros(n)
	slow_d = zeros(n)

	max_q = MonotoneQueue{Float64}(period+1)
	min_q = MonotoneQueue{Float64}(period+1)

	@inbounds for i in 1:period
		push_back!(max_q, highs[i], i)
		push_back_min!(min_q, lows[i], i)

    w_max = get_extreme(max_q)
    w_min = get_extreme(min_q)

    denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (closes[i] - w_min) / denominator
		end
	end

	@inbounds for i in (period+1):n
		remove_old!(max_q, i - period)
		remove_old!(min_q, i - period)

		push_back!(max_q, highs[i], i)
		push_back_min!(min_q, lows[i], i)

		w_max = get_extreme(max_q)
    w_min = get_extreme(min_q)

    denominator = w_max - w_min

		if denominator ≈ 0.0
			raw_k[i] = 50.0  # Default to middle value when price range is zero
		else
			raw_k[i] = 100.0 * (closes[i] - w_min) / denominator
		end
	end

	# Apply first smoothing to get Slow %K
	if ma_type == :SMA
		slow_k = SMA(raw_k, k_smooth)
	elseif ma_type == :EMA
		slow_k = EMA(raw_k, k_smooth)
	elseif ma_type == :SMMA || ma_type == :RMA
		slow_k = SMMA(raw_k, k_smooth)
	else
		throw(ArgumentError("ma_type must be one of: :SMA, :EMA, :SMMA"))
	end

	# Calculate %D by smoothing Slow %K
	if ma_type == :SMA
		slow_d = SMA(slow_k, d_smooth)
	elseif ma_type == :EMA
		slow_d = EMA(slow_k, d_smooth)
	elseif ma_type == :SMMA || ma_type == :RMA
		slow_d = SMMA(slow_k, d_smooth)
	end

	return hcat(slow_k, slow_d)
end