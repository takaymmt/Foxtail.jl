function StochRSI(ts::TSFrame, period::Int=14; field::Vector{Symbol}=:Close, ma_type::Symbol=:SMA)
    prices = ts[:,field]
    results = StochRSI(prices, period; ma_type=ma_type)
    colnames = [:Stoch_K, :Stoch_D]
    return TSFrame(results, index(ts), colnames=colnames)
end

@inline Base.@propagate_inbounds function StochRSI(prices::Vector{Float64}, period::Int=14; k_smooth::Int=3, d_smooth::Int=3, ma_type::Symbol=:SMA)

    if period < 1 || k_smooth < 1 || d_smooth < 1
        throw(ArgumentError("periods must be positive"))
    end

    n = length(prices)
    if n < period * 2  # Need extra data for both RSI and Stochastic calculation
        throw(ArgumentError("price series length must be greater than period * 2"))
    end

    # Calculate RSI first
    rsi_values = RSI(prices, period; smoothing=ma_type)

    # Pre-allocate arrays
    # raw_k = fill(NaN, n)
    # stoch_k = fill(NaN, n)
    # stoch_d = fill(NaN, n)
    raw_k = zeros(n)
    stoch_k = zeros(n)
    stoch_d = zeros(n)

    # Calculate Raw Stochastic %K based on RSI values
    # Start after the RSI values become valid (period + 1)
    @inbounds for i in (period+period):n
        # Check if we have valid RSI values in the window
        window = @view rsi_values[i-period+1:i]
        if !any(isnan, window)
            window_high = maximum(window)
            window_low = minimum(window)
            
            denominator = window_high - window_low
            
            if denominator ≈ 0.0
                raw_k[i] = 50.0  # Default to middle value when RSI range is zero
            else
                raw_k[i] = 100.0 * (rsi_values[i] - window_low) / denominator
            end
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

    # # Handle initial NaN values
    # @inbounds for i in 1:(period*2-1)  # Account for both RSI and Stochastic periods
    #     stoch_k[i] = NaN
    #     stoch_d[i] = NaN
    # end

    # Return matrix with K and D values
    return hcat(stoch_k, stoch_d)
end

export StochRSI