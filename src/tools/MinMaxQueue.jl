"""
    MinimaxQueue{T}

A data structure that maintains both maximum and minimum values over a sliding window
efficiently using the monotonic queue (also known as monotone queue) algorithm.

This implementation uses two monotonic deques internally:
- A monotonically decreasing deque for tracking maximum values
- A monotonically increasing deque for tracking minimum values

# Type Parameters
- `T`: The type of elements stored in the queue

# Time Complexity
- Push operation: Amortized O(1)
- Pop operation: O(1)
- Query max/min: O(1)
- Space complexity: O(n) where n is the window size

# Algorithm Details
The monotonic queue algorithm maintains a deque of candidates that could become
the maximum/minimum value in the current window. Elements are stored as (value, index)
pairs to handle sliding window operations.

# Example
```julia
# Create a new MinimaxQueue for window size 3
q = MinimaxQueue{Float64}(3)
# Update with new values
update!(q, 10.0, 10.0, 1) # high and low values can be different
update!(q, 5.0, 5.0, 2)
update!(q, 8.0, 8.0, 3)
# Remove elements outside the window
remove_old!(q, 1) # Remove elements with index <= 1
# Query current max/min
max_val = get_max(q) # Returns the maximum value in current window
min_val = get_min(q) # Returns the minimum value in current window
```

# Applications
- Sliding window maximum/minimum problems
- Technical indicators in financial analysis (e.g., Stochastic, Williams %R, etc.)
- Signal processing
- Data stream processing

# References
- "Sliding Window Maximum (Maximum of all subarrays of size k)" algorithm
- Monotonic Queue data structure pattern
"""
struct MinimaxQueue{T}
    max_data::CircDeque{Tuple{T, Int}}  # (value, index) pairs
    min_data::CircDeque{Tuple{T, Int}}

    function MinimaxQueue{T}(n::Int) where T
        new(CircDeque{Tuple{T, Int}}(n), CircDeque{Tuple{T, Int}}(n))
    end
end

"""
    update!(q::MinimaxQueue{T}, high::T, low::T, idx::Int) where T

Update the MinimaxQueue with new high and low values at the given index.
Maintains monotonicity in both deques.

# Arguments
- `q`: The MinimaxQueue to update
- `high`: The high value to add
- `low`: The low value to add
- `idx`: The index associated with these values
"""
@inline function update!(q::MinimaxQueue{T}, high::T, low::T, idx::Int) where T
    while !isempty(q.max_data) && last(q.max_data)[1] < high
        pop!(q.max_data)
    end
    push!(q.max_data, (high, idx))

    while !isempty(q.min_data) && last(q.min_data)[1] > low
        pop!(q.min_data)
    end
    push!(q.min_data, (low, idx))
end

"""
    remove_old!(q::MinimaxQueue, idx::Int)

Remove all elements with indices less than or equal to the given index.
Used to maintain the sliding window by removing outdated values.

# Arguments
- `q`: The MinimaxQueue to update
- `idx`: Remove all elements with index <= idx
"""
@inline function remove_old!(q::MinimaxQueue, idx::Int)
    while !isempty(q.max_data) && first(q.max_data)[2] <= idx
        popfirst!(q.max_data)
    end
    while !isempty(q.min_data) && first(q.min_data)[2] <= idx
        popfirst!(q.min_data)
    end
end

"""
    get_max(q::MinimaxQueue)

Return the maximum value in the current window.

# Arguments
- `q`: The MinimaxQueue to query
"""
@inline function get_max(q::MinimaxQueue)
    return first(q.max_data)[1]
end

"""
    get_min(q::MinimaxQueue)

Return the minimum value in the current window.

# Arguments
- `q`: The MinimaxQueue to query
"""
@inline function get_min(q::MinimaxQueue)
    return first(q.min_data)[1]
end