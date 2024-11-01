function Stoch(ts::TSFrame, period::Int=14; field::Vector{Symbol}=[:High, :Low, :Close], ma_type::Symbol=:SMA)
    prices = ts[:,field] |> Matrix
    results = Stoch(prices; period=period, ma_type=ma_type)
    colnames = [:Stoch_K, :Stoch_D]
    return TSFrame(results, index(ts), colnames=colnames)
end
export Stoch

@inline Base.@propagate_inbounds function Stoch(prices::Matrix{Float64}; 
    period::Int=14, 
    k_smooth::Int=3, 
    d_smooth::Int=3, 
    ma_type::Symbol=:SMA)

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

    # Calculate Raw %K
    @inbounds for i in period:n
        window_high = maximum(highs[i-period+1:i])
        window_low = minimum(lows[i-period+1:i])
        
        denominator = window_high - window_low
        
        if denominator ≈ 0.0
            raw_k[i] = 50.0  # Default to middle value when price range is zero
        else
            raw_k[i] = 100.0 * (closes[i] - window_low) / denominator
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

    # Handle initial NaN values
    @inbounds for i in 1:period-1
        slow_k[i] = NaN
        slow_d[i] = NaN
    end

    # Return matrix with Slow %K and %D
    return hcat(slow_k, slow_d)
end