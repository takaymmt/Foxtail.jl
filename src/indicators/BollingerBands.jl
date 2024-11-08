"""
Calculates Bollinger Bands for a given price series.

Bollinger Bands consist of:
- A middle band (moving average)
- An upper band (middle band + n standard deviations)
- A lower band (middle band - n standard deviations)

Implementation details:
- Uses circular buffer for efficient memory management
- Optimizes standard deviation calculation using the formula: Var(X) = E(X²) - (E(X))²
- Handles floating-point errors by ensuring non-negative variance

Parameters:
- `period`: Length of the moving average window (default: 14)
- `field`: Price field to use (default: :Close)
- `ma_type`: Type of moving average (default: :SMA)
- `num_std`: Number of standard deviations for bands (default: 2)

Returns a TSFrame with columns [:BB_Center, :BB_Upper, :BB_Lower]
"""
function BB(ts::TSFrame, period::Int = 14; field::Symbol = :Close, num_std = 2, ma_type::Symbol = :SMA)
	prices = ts[:, field]
    results = BB(prices, period; num_std = num_std, ma_type = ma_type)
	colnames = [:BB_Center, :BB_Upper, :BB_Lower]
	return TSFrame(results, index(ts), colnames = colnames)
end
export BB

function BB(prices::Vector{T}, period::Int = 14; num_std::Int = 2, ma_type::Symbol = :SMA) where T
    results = zeros(T, (length(prices),3))
    if ma_type == :SMMA
        masd = SMMA_stats(prices, period)
    elseif ma_type == :EMA
        masd = EMA_stats(prices, period)
    else
        masd = SMA_stats(prices, period)
    end
    @inbounds for (i, price) in enumerate(prices)
        results[i,1] = masd[i,1]
        results[i,2] = masd[i,1] + num_std * masd[i,2]
        results[i,3] = masd[i,1] - num_std * masd[i,2]
    end
    # @views @. begin　# exact same performance
    #     results[:,1] = masd[:,1]
    #     results[:,2] = masd[:,1] + num_std * masd[:,2]
    #     results[:,3] = masd[:,1] - num_std * masd[:,2]
    # end
    return results
end