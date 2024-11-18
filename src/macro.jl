"""
    process_args(args)

Process macro arguments to generate keyword and call arguments for technical indicator wrapper functions.

# Arguments
- `args`: Tuple of expressions representing macro arguments, accepting both direct assignments and named tuples

# Returns
A tuple of three elements:
- `params`: Dictionary mapping parameter names to their values
- `kw_args`: Vector of expressions for keyword arguments with type annotations
- `call_args`: Vector of expressions for function call arguments

# Input Formats
1. Direct assignment:
```julia
@prep_siso RSI n=14 field=:Close
```

2. Named tuple format:
```julia
@prep_siso RSI (n=14, field=:Close)
```

# Implementation Details
1. Parses arguments into a parameter dictionary:
   - Handles direct assignments (key=value)
   - Processes tuple-formatted parameters ((key1=value1, key2=value2))

2. Generates two types of argument expressions:
   - Keyword arguments with type annotations for function signatures
   - Call arguments for passing parameters to the underlying function

# Special Handling
- Symbol values are wrapped in QuoteNode
- The 'field' parameter is excluded from call arguments
- All parameters are properly escaped for macro hygiene

# Examples
```julia
# Input (Direct): n=20, field=:Close
# Input (Tuple): (n=20, field=:Close)
# Output for both:
# params: Dict(:n => 20, :field => :Close)
# kw_args: [:(n::Int = 20), :(field::Symbol = :Close)]
# call_args: [:(n = n)]
```

# Notes
- Used internally by technical indicator wrapper macros
- Ensures consistent parameter handling across different indicator types
- Maintains proper type information in generated functions
- Handles macro hygiene requirements
"""
function process_args(args)
    params = Dict{Any,Any}()
    kw_args = Expr[]
    call_args = Expr[]

    # Parse arguments into params dictionary
    for arg in args
        if arg isa Expr && arg.head == :(=)
            params[arg.args[1]] = arg.args[2]
        elseif arg isa Expr && arg.head == :tuple
            for pa in arg.args
                params[pa.args[1]] = pa.args[2]
            end
        else
            error("Expected named parameters")
        end
    end

    # Build keyword and call arguments
    for (key, val) in params
        typ = typeof(val)
        if typ == Symbol
            push!(kw_args, Expr(:kw, Expr(:(::), esc(key), typ), QuoteNode(val)))
        else
            push!(kw_args, Expr(:kw, Expr(:(::), esc(key), typ), val))
        end
        key == :field ||push!(call_args, Expr(:kw, esc(key), esc(key)))
    end

    return params, kw_args, call_args
end

"""
    @prep_siso(indicator[, params...])

Automatically generates a wrapper function for Single Input Single Output (SISO) technical indicators.

# Arguments
- `indicator`: Name of the technical indicator function (Symbol)
- `params`: Optional parameters (in keyword argument format)

# Generated Function Signature
```julia
function indicator(ts::TSFrame; field::Symbol=:Close, params...)
    prices = ts[:, field]
    results = indicator(prices; params...)
    return TSFrame(results, index(ts), colnames=[indicator])
end
```

# Parameter Specification
- `field`: Column name to use as input data (default: `:Close`)
- `n`: Period parameter (when specified, column name becomes `Symbol(indicator, "_", n)`)
- All other parameters are passed directly to the indicator function

# Examples
```julia
# Basic usage
@prep_siso RSI

# With period parameter
@prep_siso EMA (n=20)

# Specifying input field and parameter
@prep_siso SMA (field=:Volume, n=10)

# Multiple parameters
@prep_siso KAMA (n=10, fast=2, slow=30)
```

# Notes
- Generated functions are automatically exported
- The indicator function must take a single time series as input and return a single time series
- Parameters must be specified in tuple format: `(param1=value1, param2=value2)`
- The macro handles TSFrame data extraction and result wrapping

# Features
- Automatic type checking for parameters
- Consistent interface across different indicators
- Proper column naming for output results
- Automatic data extraction from TSFrame objects

# See Also
- [`@prep_miso`](@ref): For Multiple Input Single Output indicators
- [`@prep_simo`](@ref): For Single Input Multiple Output indicators
- [`@prep_mimo`](@ref): For Multiple Input Multiple Output indicators
"""
macro prep_siso(name, args...)
    typeof(name) == Symbol || error("First argument must be a function name")

    params, kw_args, call_args = process_args(args)
    haskey(params, :field) || push!(kw_args, Expr(:kw, Expr(:(::), esc(:field), Symbol), :(:Close)))
    colex = haskey(params, :n) ? Expr(:call, :Symbol, QuoteNode(name), QuoteNode(:_), :n) : QuoteNode(name)

    return quote
        function $(esc(name))(ts::TSFrame; $(kw_args...))
            prices = ts[:, field]
            results = $(esc(name))(prices; $(call_args...))
            col_name = $colex
            return TSFrame(results, index(ts), colnames=[col_name])
        end
        export $(esc(name))
    end
end

"""
    @prep_miso(indicator, input_fields[, params...])

Automatically generates a wrapper function for Multiple Input Single Output (MISO) technical indicators.

# Arguments
- `indicator`: Name of the technical indicator function (Symbol)
- `input_fields`: Vector of field names to use as input (e.g., `[:High, :Low, :Close]`)
- `params`: Optional parameters (in keyword argument format)

# Generated Function Signature
```julia
function indicator(ts::TSFrame; fields::Vector{Symbol}=input_fields, params...)
    prices = ts[:, fields] |> Matrix
    results = indicator(prices; params...)
    return TSFrame(results, index(ts), colnames=[indicator])
end
```

# Parameter Specification
- `fields`: Vector of column names to use as input data (specified in input_fields)
- `n`: Period parameter (when specified, column name becomes `Symbol(indicator, "_", n)`)
- All other parameters are passed directly to the indicator function

# Examples
```julia
# Basic usage with required fields
@prep_miso ATR [:High, :Low, :Close]

# With period parameter
@prep_miso ATR [:High, :Low, :Close] (n=14)

# With additional parameters
@prep_miso ChaikinOsc [:High, :Low, :Close, :Volume] (fast=3, slow=10)
```

# Notes
- Generated functions are automatically exported
- The indicator function must take a matrix of time series as input and return a single time series
- Parameters must be specified in tuple format: `(param1=value1, param2=value2)`
- Input fields are converted to a matrix before being passed to the indicator function

# Features
- Automatic matrix conversion of input data
- Consistent interface for multi-input indicators
- Proper column naming for output results
- Type checking for input parameters

# See Also
- [`@prep_siso`](@ref): For Single Input Single Output indicators
- [`@prep_simo`](@ref): For Single Input Multiple Output indicators
- [`@prep_mimo`](@ref): For Multiple Input Multiple Output indicators
"""
macro prep_miso(name, in, args...)
    typeof(name) == Symbol || error("First argument must be a function name")

    fields = if in.head == :vect
        Expr(:vect, [QuoteNode(x) for x in in.args]...)
    else
        error("Second argument must be a vector of field names")
    end

    params, kw_args, call_args = process_args(args)
    haskey(params, :fields) && error("fields keyword is not allowed")
    push!(kw_args, Expr(:kw, Expr(:(::), esc(:fields), Vector{Symbol}), fields))
    colex = haskey(params, :n) ? Expr(:call, :Symbol, QuoteNode(name), QuoteNode(:_), :n) : QuoteNode(name)

    return quote
        function $(esc(name))(ts::TSFrame; $(kw_args...))
            prices = ts[:, fields] |> Matrix
            results = $(esc(name))(prices; $(call_args...))
            col_name = $colex
            return TSFrame(results, index(ts), colnames=[col_name])
        end
        export $(esc(name))
    end
end

"""
    @prep_simo(indicator, output_suffixes[, params...])

Automatically generates a wrapper function for Single Input Multiple Output (SIMO) technical indicators.

# Arguments
- `indicator`: Name of the technical indicator function (Symbol)
- `output_suffixes`: Vector of suffixes for output column names (e.g., `[:Upper, :Lower, :Middle]`)
- `params`: Optional parameters (in keyword argument format)

# Generated Function Signature
```julia
function indicator(ts::TSFrame; field::Symbol=:Close, params...)
    prices = ts[:, field]
    results = indicator(prices; params...)
    return TSFrame(results, index(ts), colnames=[Symbol(indicator, "_", suffix) for suffix in output_suffixes])
end
```

# Parameter Specification
- `field`: Column name to use as input data (default: `:Close`)
- Output column names are automatically generated as `Symbol(indicator, "_", suffix)`
- All other parameters are passed directly to the indicator function

# Examples
```julia
# Basic usage for Bollinger Bands
@prep_simo BB [:Upper, :Middle, :Lower] (n=20)

# MACD with custom parameters
@prep_simo MACD [:Line, :Signal, :Histogram] (fast=12, slow=26, signal=9)

# StochRSI with default parameters
@prep_simo StochRSI [:K, :D]
```

# Notes
- Generated functions are automatically exported
- The indicator function must take a single time series as input and return multiple output series
- Output column names are automatically prefixed with the indicator name
- Results must match the number of specified output suffixes

# Features
- Automatic column naming with indicator prefix
- Consistent interface for multi-output indicators
- Single input field handling
- Type checking for parameters

# See Also
- [`@prep_siso`](@ref): For Single Input Single Output indicators
- [`@prep_miso`](@ref): For Multiple Input Single Output indicators
- [`@prep_mimo`](@ref): For Multiple Input Multiple Output indicators
"""
macro prep_simo(name, out, args...)
    typeof(name) == Symbol || error("First argument must be a function name")

    colvec = if out.head == :vect
        Expr(:vect, [QuoteNode(Symbol(name, :_, x)) for x in out.args]...)
    else
        error("Second argument must be a vector of output suffixes")
    end

    params, kw_args, call_args = process_args(args)
    haskey(params, :field) || push!(kw_args, Expr(:kw, Expr(:(::), esc(:field), Symbol), :(:Close)))


    return quote
        function $(esc(name))(ts::TSFrame; $(kw_args...))
            prices = ts[:, field]
            results = $(esc(name))(prices; $(call_args...))
            return TSFrame(results, index(ts), colnames=$colvec)
        end
        export $(esc(name))
    end
end

macro prep_mimo(name, in, out, args...)
    typeof(name) == Symbol || error("First argument must be a function name")

    fields = if in.head == :vect
        Expr(:vect, [QuoteNode(x) for x in in.args]...)
    else
        error("Second argument must be a vector of field names")
    end

    colvec = if out.head == :vect
        Expr(:vect, [QuoteNode(Symbol(name, :_, x)) for x in out.args]...)
    else
        error("Third argument must be a vector of output suffixes")
    end

    params, kw_args, call_args = process_args(args)
    haskey(params, :fields) || haskey(params, :field) && error("'field' or 'fields' keyword is not allowed")
    push!(kw_args, Expr(:kw, Expr(:(::), esc(:fields), Vector{Symbol}), fields))


    return quote
        function $(esc(name))(ts::TSFrame; $(kw_args...))
            prices = ts[:, fields] |> Matrix
            results = $(esc(name))(prices; $(call_args...))
            return TSFrame(results, index(ts), colnames=$colvec)
        end
        export $(esc(name))
    end
end


"""
# SIMO ------------------------------------------------------------------------

function BB(ts::TSFrame, period::Int = 14; field::Symbol = :Close, num_std = 2, ma_type::Symbol = :SMA)
	prices = ts[:, field]
    results = BB(prices, period; num_std = num_std, ma_type = ma_type)
	colnames = [:BB_Center, :BB_Upper, :BB_Lower]
	return TSFrame(results, index(ts), colnames = colnames)
end

function MACD(ts::TSFrame; field::Symbol = :Close, fast::Int = 12, slow::Int = 26, signal::Int = 9)
	prices = ts[:, field]
	results = MACD(prices, fast, slow, signal)
	colnames = [:MACD_Line, :MACD_Signal, :MACD_Histogram]
	return TSFrame(results, index(ts), colnames = colnames)
end

function StochRSI(ts::TSFrame, period::Int=14; field::Symbol=:Close, ma_type::Symbol=:SMA)
    prices = ts[:,field]
    results = StochRSI(prices, period; ma_type=ma_type)
    colnames = [:StochRSI_K, :StochRSI_D]
    return TSFrame(results, index(ts), colnames=colnames)
end

# MISO ------------------------------------------------------------------------

function ADL(ts::TSFrame; field::Vector{Symbol} = [:High, :Low, :Close, :Volume])
	prices = ts[:, field] |> Matrix
	results = ADL(prices)
	colnames = [:ADL]
	return TSFrame(results, index(ts), colnames = colnames)
end

function ATR(ts::TSFrame, period::Int=14; field::Vector{Symbol}=[:High, :Low, :Close], ma_type::Symbol=:EMA)
    prices = ts[:,field] |> Matrix
    results = ATR(prices; period=period, ma_type=ma_type)
    col_name = :ATR
    return TSFrame(results, index(ts), colnames=[col_name])
end

function ChaikinOsc(ts::TSFrame; field::Vector{Symbol} = [:High, :Low, :Close, :Volume], fast::Int = 3, slow::Int = 10)
	prices = ts[:, field] |> Matrix
	results = ChaikinOsc(prices; fast = fast, slow = slow)
	colnames = [:ChaikinOsc]
	return TSFrame(results, index(ts), colnames = colnames)
end

# MIMO ------------------------------------------------------------------------

function Stoch(ts::TSFrame, period::Int = 14; field::Vector{Symbol} = [:High, :Low, :Close], ma_type::Symbol = :SMA)
	prices = ts[:, field] |> Matrix
	results = Stoch(prices, period; ma_type = ma_type)
	colnames = [:Stoch_K, :Stoch_D]
	return TSFrame(results, index(ts), colnames = colnames)
end

function WR(ts::TSFrame, period::Int=14; field::Vector{Symbol} = [:High, :Low, :Close])
	prices = ts[:, field] |> Matrix
	results = WR(prices, period)
	colnames = [:WR, :WR_EMA]
	return TSFrame(results, index(ts), colnames = colnames)
end
"""