"""
    @prep_SISO(indicator, params)

## Overview
The `@prep_SISO` macro is designed to automatically generate interface functions for technical analysis indicators that operate on time series data. It creates a wrapper function that handles data extraction from a TSFrame object and passes it to the actual computation function.

## Purpose
- Reduces boilerplate code when implementing technical indicators
- Provides a consistent interface for working with TSFrame objects
- Handles parameter passing and type checking
- Manages column naming for output results

## Usage
```julia
@prep_SISO IndicatorName [(parameter1=value1, parameter2=value2...)]
```

### Examples:
```julia
@prep_SISO Ind1                                 # Basic usage with defaults
@prep_SISO Ind2 (a=0.7)                         # Single parameter
@prep_SISO Ind3 (offset=0.85, sigma=6)          # Multiple parameters
@prep_SISO Ind4 (field=Volume)                  # Custom input field
@prep_SISO Ind5 (field=Volume, beta=5.0)        # Field and parameter
```

## Generated Function Structure
For each macro invocation, it generates a function with the following signature:
```julia
function IndicatorName(ts::TSFrame, period::Int=10; field::Symbol=:Close, ...additional_params)
    prices = ts[:, field]                    # Extract data from specified field
    results = IndicatorName(prices, period)  # Call actual computation function
    col_name = Symbol(IndicatorName, :_, period)
    return TSFrame(results, index(ts), colnames=[col_name])
end
```
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

macro prep_siso(name, args...)
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

# macro prep_SISO2(name, args...)
#     params, kw_args, call_args = process_args(args)

#     prd = get!(params, :period, 14)
#     fld = get!(params, :field, :Close)
#     delete!(params, :period)
#     delete!(params, :field)

#     if isempty(params)
#         if prd isa Int
#             quote
#                 function $(esc(name))(ts::TSFrame, period::Int=$prd; field::Symbol=$(QuoteNode(fld)))
#                     prices = ts[:, field]
#                     results = $(esc(name))(prices, period)
#                     col_name = Symbol($name, :_, period)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#                 export $(esc(name))
#             end
#         else
#             quote
#                 function $(esc(name))(ts::TSFrame; field::Symbol=$(QuoteNode(fld)))
#                     prices = ts[:, field]
#                     results = $(esc(name))(prices)
#                     col_name = Symbol($name)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#                 export $(esc(name))
#             end
#         end
#     else
#         if prd isa Int
#             quote
#                 function $(esc(name))(ts::TSFrame, period::Int=$prd; field::Symbol=$(QuoteNode(fld)), $(kw_args...))
#                     prices = ts[:, field]
#                     results = $(esc(name))(prices, period; $(call_args...))
#                     col_name = Symbol($name, :_, period)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#                 export $(esc(name))
#             end
#         else
#             quote
#                 function $(esc(name))(ts::TSFrame; field::Symbol=$(QuoteNode(fld)), $(kw_args...))
#                     prices = ts[:, field]
#                     results = $(esc(name))(prices; $(call_args...))
#                     col_name = Symbol($name)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#             end
#         end
#     end
# end

# macro a(args...)
#     for v in args
#         println(v)
#         println(v.head)
#         println(v.args)
#         println(v.args[1])
#         println(v.args[2])
#         println("---")
#     end
# end
# macro prep_MISO(name, in, args...)
#     fields = if in.head == :vect
#         [x for x in in.args]
#     else
#         error("Second argument must be a vector of field names")
#     end

#     params = Dict{Any,Any}()
#     kw_args = Expr[]
#     call_args = Expr[]

#     for arg in args
#         if arg isa Expr && arg.head == :(=)
#             params[arg.args[1]] = arg.args[2]
#         elseif arg isa Expr && arg.head == :tuple
#             for pa in arg.args
#                 params[pa.args[1]] = pa.args[2]
#             end
#         else
#             error("Expected named parameters")
#         end
#     end

#     for (key, val) in params
#         key == :field && continue
#         key == :period && (params[:period] = val; continue)
#         typ = typeof(val)
#         push!(kw_args, Expr(:kw, Expr(:(::), esc(key), typ), val))
#         push!(call_args, Expr(:kw, esc(key), esc(key)))
#     end

#     get!(params, :period, 14)
#     prd = params[:period]

#     if isempty(args)
#         if prd isa Int
#             func_args = :(ts::TSFrame, period::Int=$prd; field::Vector{Symbol}=$fields)
#             func_rslt = :(results = $(esc(name))(prices, period))
#             func_col  = :(Symbol($name, :_, period))
#         else
#             func_args = :(ts::TSFrame; field::Vector{Symbol}=$fields)
#             func_rslt = :(results = $(esc(name))(prices))
#             func_col  = :($name)
#         end
#     else
#         if prd isa Int
#             func_args = :(ts::TSFrame, period::Int=$prd; field::Vector{Symbol}=$fields, $(kw_args...))
#             func_rslt = :(results = $(esc(name))(prices, period; $(call_args...)))
#             func_col  = :(Symbol($name, :_, period))
#         else
#             func_args = :(ts::TSFrame; field::Vector{Symbol}=$fields, $(kw_args...))
#             func_rslt = :(results = $(esc(name))(prices; $(call_args...)))
#             func_col  = :($name)
#         end
#     end

#     quote
#         function $(esc(name))$(func_args)
#             prices = ts[:, field] |> Matrix
#             $(func_rslt)
#             return TSFrame(results, index(ts), colnames=[$(func_col)])
#         end
#         export $(esc(name))
#     end
# end

# macro prep_MISO(name, in, args...)
#     fields = if in.head == :vect
#         [x for x in in.args]
#     else
#         error("Second argument must be a vector of field names")
#     end

#     params, kw_args, call_args = process_args(args)

#     prd = get!(params, :period, 14)
#     delete!(params, :period)

#     if isempty(params)
#         if prd isa Int
#             quote
#                 function $(esc(name))(ts::TSFrame, period::Int=$prd; field::Vector{Symbol}=$fields)
#                     prices = ts[:, field] |> Matrix
#                     results = $(esc(name))(prices, period)
#                     col_name = Symbol($name, :_, period)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#                 export $(esc(name))
#             end
#         else
#             quote
#                 function $(esc(name))(ts::TSFrame; field::Vector{Symbol}=$fields)
#                     prices = ts[:, field] |> Matrix
#                     results = $(esc(name))(prices)
#                     col_name = Symbol($name)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#                 export $(esc(name))
#             end
#         end
#     else
#         if prd isa Int
#             quote
#                 function $(esc(name))(ts::TSFrame, period::Int=$prd; field::Vector{Symbol}=$fields, $(kw_args...))
#                     prices = ts[:, field] |> Matrix
#                     results = $(esc(name))(prices, period; $(call_args...))
#                     col_name = Symbol($name, :_, period)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#                 export $(esc(name))
#             end
#         else
#             quote
#                 function $(esc(name))(ts::TSFrame; field::Vector{Symbol}=$fields, $(kw_args...))
#                     prices = ts[:, field] |> Matrix
#                     results = $(esc(name))(prices, period; $(call_args...))
#                     col_name = Symbol($name)
#                     return TSFrame(results, index(ts), colnames=[col_name])
#                 end
#                 export $(esc(name))
#             end
#         end
#     end
# end


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