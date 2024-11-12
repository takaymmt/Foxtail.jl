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

macro prep_SISO(name, args...)
    params = Dict{Any,Any}()
    kw_args = Expr[]
    call_args = Expr[]

    if isempty(args)
        params[:field] = :Close
    else
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
        get!(params, :field, :Close)
        for (key, val) in params
            key == :field && continue
            typ = typeof(val)
            push!(kw_args, Expr(:kw, Expr(:(::), esc(key), typ), val))
            push!(call_args, Expr(:kw, esc(key), esc(key)))
        end
    end

    fld = params[:field]

    if isempty(args)
        quote
            function $(esc(name))(ts::TSFrame, period::Int=10; field::Symbol=$(QuoteNode(fld)))
                prices = ts[:, field]
                results = $(esc(name))(prices, period)
                col_name = Symbol($name, :_, period)
                return TSFrame(results, index(ts), colnames=[col_name])
            end
            export $(esc(name))
        end
    else
        quote
            function $(esc(name))(ts::TSFrame, period::Int=10; field::Symbol=$(QuoteNode(fld)), $(kw_args...))
                prices = ts[:, field]
                results = $(esc(name))(prices, period; $(call_args...))
                col_name = Symbol($name, :_, period)
                return TSFrame(results, index(ts), colnames=[col_name])
            end
            export $(esc(name))
        end
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