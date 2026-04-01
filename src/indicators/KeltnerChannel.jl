@inline Base.@propagate_inbounds function KeltnerChannel(prices::Matrix{Float64}; n::Int=20, mult::Float64=2.0, ma_type::Symbol=:EMA)
    period = n
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end

    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    len = size(prices, 1)

    # Middle line: EMA (or other MA) of Close
    closes = prices[:, 3]
    middle = apply_ma(closes, ma_type; n=period)

    # ATR for band width
    atr = ATR(prices; n=period)

    # Upper and Lower bands
    upper = middle .+ mult .* atr
    lower = middle .- mult .* atr

    return hcat(middle, upper, lower)
end

@prep_mimo KeltnerChannel [High, Low, Close] [Middle, Upper, Lower] n=20 mult=2.0 ma_type=EMA
