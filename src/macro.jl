"""
    apply_ma(data::Vector{Float64}, ma_type::Symbol; n::Int) -> Vector{Float64}

Apply a moving average of the specified type to `data`.

Supported `ma_type` values:
- `:SMA`  — Simple Moving Average
- `:EMA`  — Exponential Moving Average
- `:SMMA` or `:RMA` — Smoothed Moving Average (Wilder's)
- `:WMA`  — Weighted Moving Average

Throws `ArgumentError` for unrecognized types.
"""
function apply_ma(data::Vector{Float64}, ma_type::Symbol; n::Int)::Vector{Float64}
    if ma_type == :SMA
        return SMA(data; n=n)
    elseif ma_type == :EMA
        return EMA(data; n=n)
    elseif ma_type == :SMMA || ma_type == :RMA
        return SMMA(data; n=n)
    elseif ma_type == :WMA
        return WMA(data; n=n)
    else
        throw(ArgumentError("Unknown ma_type: $ma_type. Valid options: :SMA, :EMA, :SMMA, :RMA, :WMA"))
    end
end

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

    # kw_args  : keyword args for the wrapper signature  e.g. f(ts; n::Int=10, field::Symbol=:Close)
    # call_args: keyword args forwarded to the core function  e.g. indicator(prices; n=n)
    #            `field` is consumed by the wrapper (column selection) and never forwarded.
    kw_args = Expr[]
    call_args = Expr[]

    # --- Argument Parsing ---
    # Accept two input styles and normalise both into the `params` dict:
    #   Direct: @prep_siso RSI n=14 field=:Close   |  Tuple: @prep_siso RSI (n=14, field=:Close)
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

    # --- Generate keyword / call args ---
    for (key, val) in params
        typ = typeof(val)

        # Produces:  key::Type = default_value  (for the generated function signature)
        # Symbol values need QuoteNode wrapping so they appear as :Foo, not Foo.
        if typ == Symbol
            push!(kw_args, Expr(:kw, Expr(:(::), esc(key), typ), QuoteNode(val)))
        else
            push!(kw_args, Expr(:kw, Expr(:(::), esc(key), typ), val))
        end

        # Produces:  key = key  (forwarded as keyword arg to the core function)
        # `field` is consumed by the wrapper, so it is NOT forwarded.
        if key != :field
            push!(call_args, Expr(:kw, esc(key), esc(key)))
        end
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

    # Default `field` kwarg when the user didn't specify one
    haskey(params, :field) || push!(kw_args, Expr(:kw, Expr(:(::), esc(:field), Symbol), :(:Close)))

    # Column name: "EMA_10" when `n` is present, otherwise just "EMA"
    colex = haskey(params, :n) ? Expr(:call, :Symbol, QuoteNode(name), QuoteNode(:_), :n) : QuoteNode(name)

    # Generated code example (@prep_siso EMA n=10):
    #   function EMA(ts::TSFrame; n::Int=10, field::Symbol=:Close)
    #       prices = ts[:, field]
    #       results = EMA(prices; n=n)
    #       return TSFrame(results, index(ts), colnames=[:EMA_10])
    #   end
    #   export EMA
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

    # Convert [:High, :Low, :Close] literal into a quoted Symbol vector expression
    fields = if in.head == :vect
        Expr(:vect, [QuoteNode(x) for x in in.args]...)
    else
        error("Second argument must be a vector of field names")
    end

    params, kw_args, call_args = process_args(args)
    haskey(params, :fields) && error("fields keyword is not allowed")

    # Add `fields` kwarg so the user can override which columns to read
    push!(kw_args, Expr(:kw, Expr(:(::), esc(:fields), Vector{Symbol}), fields))

    # Column name: "ATR_14" when `n` is present, otherwise just "ATR"
    colex = haskey(params, :n) ? Expr(:call, :Symbol, QuoteNode(name), QuoteNode(:_), :n) : QuoteNode(name)

    # Generated code example (@prep_miso ATR [:High, :Low, :Close] n=14):
    #   function ATR(ts::TSFrame; n::Int=14, fields::Vector{Symbol}=[:High, :Low, :Close])
    #       prices = ts[:, fields] |> Matrix
    #       results = ATR(prices; n=n)
    #       return TSFrame(results, index(ts), colnames=[:ATR_14])
    #   end
    #   export ATR
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

    # Build output column names: [:BB_Upper, :BB_Middle, :BB_Lower]
    colvec = if out.head == :vect
        Expr(:vect, [QuoteNode(Symbol(name, :_, x)) for x in out.args]...)
    else
        error("Second argument must be a vector of output suffixes")
    end

    params, kw_args, call_args = process_args(args)

    # Default `field` kwarg when the user didn't specify one
    haskey(params, :field) || push!(kw_args, Expr(:kw, Expr(:(::), esc(:field), Symbol), :(:Close)))

    # Generated code example (@prep_simo BB [:Upper, :Middle, :Lower] n=20):
    #   function BB(ts::TSFrame; n::Int=20, field::Symbol=:Close)
    #       prices = ts[:, field]
    #       results = BB(prices; n=n)
    #       return TSFrame(results, index(ts), colnames=[:BB_Upper, :BB_Middle, :BB_Lower])
    #   end
    #   export BB
    return quote
        function $(esc(name))(ts::TSFrame; $(kw_args...))
            prices = ts[:, field]
            results = $(esc(name))(prices; $(call_args...))
            return TSFrame(results, index(ts), colnames=$colvec)
        end
        export $(esc(name))
    end
end

"""
    @prep_mimo(indicator, input_fields, output_suffixes[, params...])

Automatically generates a wrapper function for Multiple Input Multiple Output (MIMO) technical indicators.

# Arguments
- `indicator`: Name of the technical indicator function (Symbol)
- `input_fields`: Vector of field names to use as input (e.g., `[:High, :Low, :Close]`)
- `output_suffixes`: Vector of suffixes for output column names (e.g., `[:Upper, :Lower]`)
- `params`: Optional parameters (in keyword argument format)

# Generated Function Signature
```julia
function indicator(ts::TSFrame; fields::Vector{Symbol}=input_fields, params...)
    prices = ts[:, fields] |> Matrix
    results = indicator(prices; params...)
    return TSFrame(results, index(ts), colnames=[Symbol(indicator, "_", suffix) for suffix in output_suffixes])
end
```

# Parameter Specification
- `fields`: Vector of column names to use as input data (specified in input_fields)
- Output column names are automatically generated as `Symbol(indicator, "_", suffix)`
- All other parameters are passed directly to the indicator function

# Examples
```julia
# Basic usage with multiple inputs and outputs
@prep_mimo Stochastic [:High, :Low, :Close] [:K, :D] (n=14, k=3, d=3)

# Complex indicator with multiple parameters
@prep_mimo CustomIndicator [:Open, :High, :Low, :Close] [:Signal1, :Signal2] (fast=12, slow=26)
```

# Notes
- Generated functions are automatically exported
- The indicator function must take a matrix of time series as input and return multiple output series
- Output column names are automatically prefixed with the indicator name
- Results must match the number of specified output suffixes

# Features
- Handles multiple input fields with matrix conversion
- Automatic column naming for multiple outputs
- Consistent interface for complex indicators
- Type checking for input parameters

# See Also
- [`@prep_siso`](@ref): For Single Input Single Output indicators
- [`@prep_miso`](@ref): For Multiple Input Single Output indicators
- [`@prep_simo`](@ref): For Single Input Multiple Output indicators
"""
macro prep_mimo(name, in, out, args...)
    typeof(name) == Symbol || error("First argument must be a function name")

    # Convert [:High, :Low, :Close] literal into a quoted Symbol vector expression
    fields = if in.head == :vect
        Expr(:vect, [QuoteNode(x) for x in in.args]...)
    else
        error("Second argument must be a vector of field names")
    end

    # Build output column names: [:Stochastic_K, :Stochastic_D]
    colvec = if out.head == :vect
        Expr(:vect, [QuoteNode(Symbol(name, :_, x)) for x in out.args]...)
    else
        error("Third argument must be a vector of output suffixes")
    end

    params, kw_args, call_args = process_args(args)
    (haskey(params, :fields) || haskey(params, :field)) && error("'field' or 'fields' keyword is not allowed")

    # Add `fields` kwarg so the user can override which columns to read
    push!(kw_args, Expr(:kw, Expr(:(::), esc(:fields), Vector{Symbol}), fields))

    # Generated code example (@prep_mimo Stochastic [:High, :Low, :Close] [:K, :D] n=14):
    #   function Stochastic(ts::TSFrame; n::Int=14, fields::Vector{Symbol}=[:High, :Low, :Close])
    #       prices = ts[:, fields] |> Matrix
    #       results = Stochastic(prices; n=n)
    #       return TSFrame(results, index(ts), colnames=[:Stochastic_K, :Stochastic_D])
    #   end
    #   export Stochastic
    return quote
        function $(esc(name))(ts::TSFrame; $(kw_args...))
            prices = ts[:, fields] |> Matrix
            results = $(esc(name))(prices; $(call_args...))
            return TSFrame(results, index(ts), colnames=$colvec)
        end
        export $(esc(name))
    end
end