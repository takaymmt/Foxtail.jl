"""
    ALMA(prices::Vector; n::Int=10, offset::Float64=0.85, sigma::Float64=6.0) -> Vector{Float64}

Arnaud Legoux Moving Average (ALMA) - A weighted moving average that reduces lag while maintaining smoothness.

# Arguments
- `prices::Vector`: Input price series
- `n::Int=10`: Window size/period length
- `offset::Float64=0.85`: Controls weight distribution (0 to 1). Higher values emphasize recent prices
- `sigma::Float64=6.0`: Controls Gaussian curve width. Lower values create sharper curves

# Returns
- `Vector{Float64}`: ALMA values for the input series

# Details
ALMA uses Gaussian-weighted coefficients to calculate a moving average with reduced lag.
The weights follow a bell curve distribution shaped by the offset and sigma parameters.

# Formula
```math
ALMA_t = \\sum_{i=0}^{n-1} w_i \\cdot P_{t-i}
```
where:
- ``w_i`` are normalized Gaussian weights
- ``P_{t-i}`` is the price i periods ago
- ``n`` is the window size

# Weight Calculation
1. ``w_i = exp(-(i - m)^2 / (2s^2))``
   - ``m = offset \\cdot (n-1)``
   - ``s = n/sigma``
2. Weights are normalized: ``w_i = w_i / \\sum w_j``

# Parameter Guidelines
- Short-term:  n=9,  offset=0.85, sigma=6
- Medium-term: n=21, offset=0.85, sigma=6
- Long-term:   n=50, offset=0.85, sigma=6

## Parameters Details
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
"""

@inline Base.@propagate_inbounds function ALMA(prices::Vector; n::Int=10, offset::Float64=0.85, sigma::Float64=6.0)
	period = n
	len = length(prices)
	result = Vector{Float64}(undef, len)
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
	@inbounds for i in (period+1):len
		result[i] = dot(view(prices, (i-period+1):i), weights)
	end
	return result
end

@prep_siso ALMA n=10 (offset=0.85, sigma=6.0)