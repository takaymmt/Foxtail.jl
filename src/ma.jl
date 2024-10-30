# Simple Moving Average
@prep_SISO SMA result

function fit!(ind::iSMA{T}, price::T) where T
	if isfull(ind)
		ind._result -= (first(ind) - price) / capacity(ind)
		push!(ind, price)
	else
		push!(ind, price)
		data = value(ind)
		ind._result = sum(data) / length(data)
	end
	return ind._result
end

# Exponential Moving Average
@prep_SISO EMA result

function fit!(ind::iEMA{T}, price::T) where T
	if isfull(ind)
		alpha = 2 / (1 + capacity(ind))
		ind._result = price * alpha + ind._result * (1 - alpha)
		push!(ind, price)
	else
		push!(ind, price)
		alpha = 2 / (1 + length(ind))
		ind._result = price * alpha + ind._result * (1 - alpha)
	end
	return ind._result
end

# Weighted Moving Average
@prep_SISO WMA numerator total denominator

function fit!(ind::iWMA{T}, price::T) where T
	# See https://en.wikipedia.org/wiki/Moving_average#Weighted_moving_average
	if isfull(ind)
		losing = first(ind)
		push!(ind, price)
		n = length(ind)

		ind._numerator = ind._numerator + n * price - ind._total
		ind._total = ind._total + price - losing
	else
		push!(ind, price)
		n = length(ind)
		ind._denominator = n * (n + 1) / 2

		ind._numerator += n * price
		ind._total += price
	end

	return ind._numerator / ind._denominator
end

# Smoothed Moving Average / Running Moving Average
@prep_SISO SMMA result

function fit!(ind::iSMMA{T}, price::T) where T
	if isfull(ind)
		alpha = 1 / capacity(ind)
		ind._result = price * alpha + ind._result * (1 - alpha)
		push!(ind, price)
	else
		push!(ind, price)
		alpha = 1 / length(ind)
		ind._result = price * alpha + ind._result * (1 - alpha)
	end
	return ind._result
end
RMA(ts::TSFrame, period::Int; field::Symbol = :Close) = SMMA(ts, period; field)
export RMA

# Triangular Moving Average
function TMA(ts::TSFrame, period::Int; field::Symbol = :Close)
    prices = ts[:, field]
    SMA1 = _SMA(prices, period)
    results = _SMA(SMA1, div(period+1, 2))
    col_name = Symbol(:TMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
TRIMA(ts::TSFrame, period::Int; field::Symbol = :Close) = TMA(ts, period; field)
export TMA, TRIMA

# Hull Moving Average
function HMA(ts::TSFrame, period::Int; field::Symbol = :Close)
	prices = ts[:, field]
	WMA1 = _WMA(prices, div(period, 2))
	WMA2 = _WMA(prices, period)
	results = _WMA(WMA1 * 2 - WMA2, round(Int, sqrt(period)))
	col_name = Symbol(:HMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export HMA

# Double Exponential Moving Average
function DEMA(ts::TSFrame, period::Int; field::Symbol = :Close)
	prices = ts[:, field]
	EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	results = EMA1 * 2 - EMA2
	col_name = Symbol(:DEMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export DEMA

# Triple Exponential Moving Average
function TEMA(ts::TSFrame, period::Int; field::Symbol = :Close)
	prices = ts[:, field]
	EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	EMA3 = _EMA(EMA2, period)
	results = (EMA1 - EMA2) * 3 + EMA3
	col_name = Symbol(:TEMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export TEMA

# T3 Moving Average
# T3(8, 0.1) is an alternative of EMA(20), a bit smoother
# T3(13, 0.08) is an smoother alternative of EMA(40)
function T3(ts::TSFrame, period::Int; field::Symbol = :Close, a::Float64 = 0.7)
	prices = ts[:, field]

	EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	EMA3 = _EMA(EMA2, period)
	EMA4 = _EMA(EMA3, period)
	EMA5 = _EMA(EMA4, period)
	EMA6 = _EMA(EMA5, period)

	c1 = -a^3
	c2 = 3a^2 + 3a^3
	c3 = -6a^2 - 3a - 3a^3
	c4 = 1 + 3a + a^3 + 3a^2

	results = c1 * EMA6 + c2 * EMA5 + c3 * EMA4 + c4 * EMA3

	col_name = Symbol(:T3, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export T3

# @prep_SISO ALMA m s wtdsum cumwt offset(6.0::Float64) sigma(0.85::Float64)

# function fit!(ind::iALMA{T}, price::T) where T
# 	if isfull(ind)
#         len = capacity(ind)
#         ind._wtdsum = 0.0
#         ind._cumwt = 0.0

#         for i in 0:(len-1)
#             ind._wtd = exp( -( (i-ind._m)^2 / (2*ind._s^2) ) )
#             ind._wtdsum += ind._wtd * price * (len - i - i)
#             ind._cumwt += ind._wtd
#         end
#         push!(ind, price)
# 	else
# 		push!(ind, price)
#         len = length(ind)
#         ind._m = ind.offset * (len - 1)
#         ind._s = len / ind.sigma
#         ind._wtdsum = 0.0
#         ind._cumwt = 0.0

#         for i in 0:(len-1)
#             ind._wtd = exp( -( (i-ind._m)^2 / (2*ind._s^2) ) )
#             ind._wtdsum += ind._wtd * price * (len - i - i)
#             ind._cumwt += ind._wtd
#         end
# 	end
# 	return ind._wtdsum / ind._cumwt
# end

# Arnaud Legoux Moving Average
# formula: https://blog.xcaldata.com/unlocking-trading-insights-with-arnaud-legoux-moving-average-alma/
# pine script: https://www.tuned.com/blog/learning/strategy-creation/what-is-the-arnaud-legoux-moving-average-and-how-to-use-it-on-tuned/
# code: https://www.prorealcode.com/prorealtime-indicators/alma-arnaud-legoux-moving-average/