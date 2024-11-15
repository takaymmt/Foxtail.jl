# Chaikin Oscillator
# function ChaikinOsc(ts::TSFrame; field::Vector{Symbol} = [:High, :Low, :Close, :Volume], fast::Int = 3, slow::Int = 10)
# 	prices = ts[:, field] |> Matrix
# 	results = ChaikinOsc(prices; fast = fast, slow = slow)
# 	colnames = [:ChaikinOsc]
# 	return TSFrame(results, index(ts), colnames = colnames)
# end
# export ChaikinOsc

@inline Base.@propagate_inbounds function ChaikinOsc(prices::Matrix{Float64}; fast::Int = 3, slow::Int = 10)
    adl = ADL(prices)
    ema_fast = EMA(adl; n=fast)
    ema_slow = EMA(adl; n=slow)
    return ema_fast - ema_slow
end

@prep_miso ChaikinOsc [:High, :Low, :Close, :Volume] fast=3 slow=10