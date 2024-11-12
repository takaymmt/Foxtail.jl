function MACD3(ts::TSFrame; field::Symbol = :Close, fast::Int = 5, middle::Int = 20, slow::Int = 40, ma_type::Symbol = :EMA)
	prices = ts[:, field]
	results = MACD3(prices, fast, middle, slow, ma_type)
	colnames = [:MACD3_Fast, :MACD3_Middle, :MACD3_Slow]
	return TSFrame(results, index(ts), colnames = colnames)
end
export MACD3

function MACD3(prices::Vector{Float64}, fast::Int = 5, middle::Int = 20, slow::Int = 40, ma_type::Symbol = :EMA)
    n = length(prices)
    if n < slow
        throw(ArgumentError("price series length must be greater than slow period"))
    end

    # Calculate MAs
    if ma_type == :Custom1 || ma_type == :HAJ
        fast_ma = HMA(prices, fast)
        mddl_ma = ALMA(prices, middle)
        slow_ma = JMA(prices, slow)
    elseif ma_type == :Custom2 || ma_type == :KAMA
        fast_ma = KAMA(prices, fast)
        mddl_ma = KAMA(prices, middle)
        slow_ma = KAMA(prices, slow)
    elseif ma_type == :Custom3 || ma_type == :ALMA
        fast_ma = ALMA(prices, fast)
        mddl_ma = ALMA(prices, middle)
        slow_ma = ALMA(prices, slow)
    else
        fast_ma = EMA(prices, fast)
        mddl_ma = EMA(prices, middle)
        slow_ma = EMA(prices, slow)
    end

    # Calculate MACD line
    fast_line = fast_ma - mddl_ma
    mddl_line = fast_ma - slow_ma
    slow_line = mddl_ma - slow_ma

    # Combine results
    results = zeros(n, 3)
    results[:, 1] = ALMA(fast_line,4; offset=0.9)
    results[:, 2] = ALMA(mddl_line,4; offset=0.9)
    results[:, 3] = ALMA(slow_line,4; offset=0.9)

    return results
end