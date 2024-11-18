"""
    WR(prices::Matrix{Float64}, period::Int=14)

Williams %R (Williams Percent Range) is a momentum indicator that measures overbought and oversold levels.

# Calculation
%R = (Highest High - Close)/(Highest High - Lowest Low) × -100

# Parameters
- `prices`: Price matrix with columns [high, low, close]
- `period`: Lookback period (default: 14)

# Returns
Matrix containing Williams %R values and its EMA

# Notes
- Oscillates between 0 and -100
- Traditional overbought level: -20
- Traditional oversold level: -80
"""
@inline Base.@propagate_inbounds function WR(prices::Matrix{Float64}; n::Int=14)
    period = n
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
    end

    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    len = size(prices, 1)
    if len < period
        throw(ArgumentError("price series length must be greater than period"))
    end

    # Extract price data
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]

    # Pre-allocate result array
    results = zeros(len)

    q = MinMaxQueue{Float64}(period+1)

    @inbounds for i in 1:period
        update!(q, highs[i], lows[i], i)

        w_max = get_max(q)
        w_min = get_min(q)

        denominator = w_max - w_min

        if denominator ≈ 0.0
            results[i] = -50.0  # Default to middle value when price range is zero
        else
            results[i] = -100.0 * (w_max - closes[i]) / denominator
        end
    end

    @inbounds for i in (period+1):len
        remove_old!(q, i - period)
        update!(q, highs[i], lows[i], i)

        w_max = get_max(q)
        w_min = get_min(q)

        denominator = w_max - w_min

        if denominator ≈ 0.0
            results[i] = -50.0  # Default to middle value when price range is zero
        else
            results[i] = -100.0 * (w_max - closes[i]) / denominator
        end
    end

    ema = EMA(results; n = period - 1)
    return hcat(results, ema)
end

@prep_mimo WR [High, Low, Close] [raw, EMA] n=14

# function WR(ts::TSFrame, period::Int=14; field::Vector{Symbol} = [:High, :Low, :Close])
# 	prices = ts[:, field] |> Matrix
# 	results = WR(prices, period)
# 	colnames = [:WR, :WR_EMA]
# 	return TSFrame(results, index(ts), colnames = colnames)
# end
# export WR