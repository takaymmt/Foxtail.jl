function MACD(ts::TSFrame; field::Symbol = :Close, fast::Int = 12, slow::Int = 26, signal::Int = 9)
	prices = ts[:, field]
	results = MACD(prices, fast, slow, signal)
	colnames = [:MACD_Line, :MACD_Signal, :MACD_Histogram]
	return TSFrame(results, index(ts), colnames = colnames)
end
export MACD

function MACD(prices::Vector{Float64}, fast::Int = 12, slow::Int = 26, signal::Int = 9)
    n = length(prices)
    if n < slow
        throw(ArgumentError("price series length must be greater than slow period"))
    end

    # Calculate EMAs
    fast_ema = EMA(prices, fast)
    slow_ema = EMA(prices, slow)

    # Calculate MACD line
    macd_line = fast_ema - slow_ema

    # Calculate signal line
    signal_line = EMA(macd_line, signal)

    # Calculate histogram
    histogram = macd_line - signal_line

    # Combine results
    results = zeros(n, 3)
    results[:, 1] = macd_line
    results[:, 2] = signal_line
    results[:, 3] = histogram

    return results
end