# Helper functions for calculating max and min in sliding window
struct MonotoneQueue{T}
	data::CircDeque{Tuple{T, Int}}  # (value, index) pairs

	MonotoneQueue{T}(n::Int) where T = new(CircDeque{Tuple{T, Int}}(n))
end

@inline function push_back!(q::MonotoneQueue{T}, val::T, idx::Int) where T
	while !isempty(q.data) && last(q.data)[1] < val  # For max queue
		pop!(q.data)
	end
	push!(q.data, (val, idx))
end

@inline function push_back_min!(q::MonotoneQueue{T}, val::T, idx::Int) where T
	while !isempty(q.data) && last(q.data)[1] > val  # For min queue
		pop!(q.data)
	end
	push!(q.data, (val, idx))
end

@inline function remove_old!(q::MonotoneQueue, idx::Int)
	while !isempty(q.data) && first(q.data)[2] <= idx
		popfirst!(q.data)
	end
end

@inline function get_extreme(q::MonotoneQueue)
	return first(q.data)[1]
end