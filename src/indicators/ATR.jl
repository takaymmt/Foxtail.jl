function ATR(ts::TSFrame, period::Int=14; field::Vector{Symbol}=[:High, :Low, :Close], ma_type::Symbol=:EMA)
    prices = ts[:,field] |> Matrix
    results = ATR(prices; period=period, ma_type=ma_type)
    col_name = :ATR
    return TSFrame(results, index(ts), colnames=[col_name])
end
export ATR

@inline Base.@propagate_inbounds function TR(prices::Matrix{Float64})
    n = size(prices, 1)
    result = zeros(n)

    result[1] = prices[1, 1] - prices[1, 2]

    @inbounds for i in 2:n
        high = prices[i, 1]
        low = prices[i, 2]
        prev_close = prices[i-1, 3]

        range1 = high - low
        range2 = abs(high - prev_close)
        range3 = abs(low - prev_close)

        result[i] = max(range1, range2, range3)
    end

    return result
end

@inline Base.@propagate_inbounds function _TR(prices::Matrix{Float64}; ma_type::Symbol=:EMA, period::Int=14)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
    end

    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    true_ranges = TR(prices)

    if ma_type == :SMA
        return SMA(true_ranges, period)
    elseif ma_type == :EMA
        return EMA(true_ranges, period)
    elseif ma_type == :SMMA || ma_type == :RMA
        return SMMA(true_ranges, period)
    else
        throw(ArgumentError("ma_type must be either :SMA or :EMA"))
    end
end
