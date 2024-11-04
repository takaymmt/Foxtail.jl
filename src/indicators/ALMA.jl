"""
Arnaud Legoux Moving Average (ALMA) Implementation

ALMA is an advanced moving average indicator that reduces signal lag while maintaining
smooth transitions between values. It uses Gaussian-weighted coefficients applied to price data.

Basic Concept:
-------------
ALMA is calculated as a weighted sum of price values, where the weights follow
a Gaussian (bell curve) distribution shape. The weights are positioned and scaled
within the window using the offset and sigma parameters.

Core Formula:
------------
ALMA_t = Σ(w_i * P_(t-i))  for i = 0 to (n-1)

where:
- w_i are the normalized Gaussian weights
- P_(t-i) is the price i periods ago
- n is the window size

Weight Calculation:
-----------------
1. Initial weight for position i:
   w_i = exp(-(i - m)^2 / (2 * s^2))
   where:
   - m = floor(offset * (n-1)) : controls the peak position
   - s = n/sigma : controls the curve width

2. Weights are then normalized by dividing each by their sum:
   final_w_i = w_i / Σ(w_j)  for j = 0 to (n-1)

Parameters:
----------
window (n): Integer, default=9
    - Number of periods to consider
    - Larger values capture longer trends but increase lag
    - Common values: 9 (short-term) to 50 (long-term)

offset: Float64, default=0.85
    - Controls the weight distribution's position (0 to 1)
    - Higher values (→1) emphasize recent prices
    - Lower values (→0) emphasize older prices
    - 0.85 is commonly used for balanced sensitivity

sigma: Float64, default=6.0
    - Controls the Gaussian curve's shape
    - Lower values (e.g., 2) create sharper curves = more responsive but noisier
    - Higher values (e.g., 6) create gentler curves = smoother but more lag
    - 6.0 provides good balance between smoothing and responsiveness

Effect of Parameters:
-------------------
Window Size Effect:
- Larger window → Smoother output, more lag, better for long-term trends
- Smaller window → More responsive, less lag, better for short-term signals

Offset Effect:
- Higher offset → More weight on recent prices, faster response to changes
- Lower offset → More weight on older prices, slower response to changes

Sigma Effect:
- Lower sigma → Sharper weight distribution, more emphasis on prices near peak
- Higher sigma → Broader weight distribution, more evenly distributed weights

Common Parameter Combinations:
---------------------------
Short-term trading:  window=9,  offset=0.85, sigma=6
Medium-term trading: window=21, offset=0.85, sigma=6
Long-term trading:   window=50, offset=0.85, sigma=6
"""
@inline Base.@propagate_inbounds function ALMA(prices::Vector, period::Int; offset::Float64=0.85, sigma::Float64=6.0)
	n = length(prices)
	result = Vector{Float64}(undef, n)
	result[1] = copy(prices[1])

	m = 0.0
	s = 0.0
	weights = zeros(eltype(prices), period)
	@inbounds for window in 2:period
		m = offset * (window - 1)
		s = window / sigma
		@inbounds for j in 0:(window-1)
			weights[j+1] = exp(-((j - m)^2) / (2 * s^2))
		end
		weights ./= sum(weights)
		result[window] = dot(view(prices, 1:window), view(weights,1:window))
	end
	@inbounds for i in (period+1):n
		result[i] = dot(view(prices, (i-period+1):i), weights)
	end
	return result
end

@prep_SISO ALMA (offset=0.85, sigma=6.0)