function MACD3(prices::Vector{Float64}; fast::Int = 5, middle::Int = 20, slow::Int = 40, ma_type::Symbol = :EMA)
    # Calculate MAs
    if ma_type == :Custom1 || ma_type == :HAJ
        fast_ma = HMA(prices; n = fast)
        mddl_ma = ALMA(prices; n = middle)
        slow_ma = JMA(prices; n = slow)
    elseif ma_type == :Custom2 || ma_type == :JAK
        fast_ma = JMA(prices; n = fast)
        mddl_ma = ALMA(prices; n = middle)
        slow_ma = KAMA(prices; n = slow)
    elseif ma_type == :Custom2 || ma_type == :KAMA
        fast_ma = KAMA(prices; n = fast)
        mddl_ma = KAMA(prices; n = middle)
        slow_ma = KAMA(prices; n = slow)
    elseif ma_type == :Custom3 || ma_type == :ALMA
        fast_ma = ALMA(prices; n = fast)
        mddl_ma = ALMA(prices; n = middle)
        slow_ma = ALMA(prices; n = slow)
    else
        fast_ma = EMA(prices; n = fast)
        mddl_ma = EMA(prices; n = middle)
        slow_ma = EMA(prices; n = slow)
    end

    # Calculate MACD line
    fast_line = fast_ma - mddl_ma
    mddl_line = fast_ma - slow_ma
    slow_line = mddl_ma - slow_ma

    # Combine results
    results = zeros(length(prices), 3)
    results[:, 1] = ALMA(fast_line; n = 4, offset=0.9)
    results[:, 2] = ALMA(mddl_line; n = 4, offset=0.9)
    results[:, 3] = ALMA(slow_line; n = 4, offset=0.9)

    return results
end

@prep_simo MACD3 [Fast, Middle, Slow] fast=5 middle=20 slow=40 ma_type=EMA