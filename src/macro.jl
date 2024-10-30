"""
    @prep_SISO(indicator, fields...)

Generate a type-safe implementation of a Single Input, Single Output (SISO) technical indicator,
including a calculation struct and interface functions.

# Arguments
- `indicator`: Symbol for the indicator name (e.g., SMA, EMA, WMA)
- `fields...`: List of fields in two possible formats:
    - Regular field: A simple Symbol (e.g., `result`, `numerator`)
      These are initialized to 0.0 and stored as Float64
    - Parameterized field: field_name(value::Type) format (e.g., `alpha(0.5::Float64)`)
      These become constructor parameters and function arguments with specified types and default values

# Generated Components

## 1. Mutable Struct (prefixed with 'i')
```julia
mutable struct i{indicator}{T} <: FTailStat
    cb::CircBuff
    _field1::Float64        # Regular fields are stored as Float64
    _field2::ParameterType  # Parameterized fields maintain their specified type
    # ...
end
```

## 2. Constructor
```julia
i{indicator}{T}(
    period::Int,
    param1::Type1=default1,  # Only parameterized fields appear here
    param2::Type2=default2,  # with their specified types and defaults
    # ...
)
```

## 3. Internal Function
```julia
_indicator(
    prices::Vector,
    period::Int;
    param1::Type1=default1,  # Parameterized fields become keyword arguments
    param2::Type2=default2,
    # ...
)
```

## 4. Public Interface
```julia
indicator(
    ts::TSFrame,
    period::Int;
    field::Symbol=:Close,
    param1::Type1=default1,  # Same keyword arguments as internal function
    param2::Type2=default2,
    # ...
)
```

# Examples

## Basic Usage (Regular Fields)
```julia
@prep_SISO SMA result
# Generates:
# - struct iSMA{T} with fields: cb::CircBuff, _result::Float64
# - SMA(ts::TSFrame, period::Int; field::Symbol=:Close)
```

## Advanced Usage (Mixed Fields)
```julia
@prep_SISO BMA result sigma(0.1::Float64) fast(0.5::Float64) slow(0.05::Float64)
# Generates:
# - struct iBMA{T} with fields:
#   * cb::CircBuff
#   * _result::Float64
#   * _sigma::Float64
#   * _fast::Float64
#   * _slow::Float64
# - Constructor: iBMA{T}(period::Int, sigma::Float64=0.1, fast::Float64=0.5, slow::Float64=0.05)
# - BMA(ts::TSFrame, period::Int; field::Symbol=:Close, sigma::Float64=0.1, fast::Float64=0.5, slow::Float64=0.05)
```

## Usage Example
```julia
# Create indicator with default parameters
result1 = AMA(df, 20)

# Customize parameters
result2 = BMA(df, 20, sigma=0.2, fast=0.6, slow=0.1)
```

# Notes
1. Regular fields are always of type Float64 and initialized to 0.0
2. Parameterized fields must include both type annotation and default value
3. The struct name is prefixed with 'i' to avoid naming conflicts
4. All internal field names are prefixed with '_'
5. The public interface function is automatically exported

See also: [`FTailStat`](@ref), [`TSFrame`](@ref), [`CircBuff`](@ref)
"""
macro prep_SISO(indicator, fields...)
    # Parse fields into regular and parameterized fields
    regular_fields = Symbol[]
    param_fields = Symbol[]
    param_types = Dict{Symbol, Any}()
    default_values = Dict{Symbol, Any}()

    for field in fields
        if field isa Symbol
            push!(regular_fields, field)
        elseif field.head == :call
            field_name = field.args[1]
            type_expr = field.args[2]

            if type_expr.head == :(::)
                push!(param_fields, field_name)
                param_types[field_name] = type_expr.args[2]
                default_values[field_name] = type_expr.args[1]
            else
                error("Parameterized fields must include type annotations: $field_name(value::Type)")
            end
        else
            error("Invalid field specification: $field")
        end
    end

    # Generate struct and function names
    struct_name = Symbol(:i, indicator)
    func_name = QuoteNode(indicator)
    internal_func_name = Symbol(:_, indicator)

    # Prepare field definitions for struct
    field_expressions = vcat(
        [:($(Symbol(:_, field))::Float64) for field in regular_fields],
        [:($(Symbol(:_, field))::$(param_types[field])) for field in param_fields]
    )

    # Prepare constructor initialization expressions
    init_expressions = vcat(
        [:(zero(Float64)) for _ in regular_fields],
        [Symbol(field) for field in param_fields]
    )

    # Prepare constructor parameters
    constructor_params = [:(period::Int)]
    if !isempty(param_fields)
        append!(constructor_params,
            [:($(field)::$(param_types[field])) for field in param_fields])
    end

    # Add documentation generation before the quote block
    struct_doc = """
        $(struct_name){T} <: FTailStat

    Internal calculation struct for the $(indicator) technical indicator.

    # Fields
    - `cb::CircBuff`: Circular buffer for storing input data
    $(join(["- `_$field::Float64`: Storage for $field calculation" for field in regular_fields], "\n"))
    $(join(["- `_$field::$(param_types[field])`: Parameter $field (default: $(default_values[field]))" for field in param_fields], "\n"))

    # Constructor
    ```julia
    $(struct_name){T}(period::Int$(isempty(param_fields) ? "" : ", " * join(["$field::$(param_types[field])=$(default_values[field])" for field in param_fields], ", ")))
    ```

    This struct implements the FTailStat interface for streaming calculations.
    """

    func_doc = """
        $(indicator)(ts::TSFrame, period::Int; field::Symbol=:Close$(isempty(param_fields) ? "" : ", " * join(["$field::$(param_types[field])=$(default_values[field])" for field in param_fields], ", ")))

    Calculate the $(indicator) technical indicator.

    # Arguments
    - `ts::TSFrame`: Input time series data
    - `period::Int`: Calculation period
    - `field::Symbol=:Close`: Column to use for calculation
    $(join(["- `$field::$(param_types[field])=$(default_values[field])`: Calculation parameter" for field in param_fields], "\n"))

    # Returns
    - `TSFrame`: Result of the calculation with column name `$(indicator)_period`

    # Example
    ```julia
    result = $(indicator)(ts, 20$(isempty(param_fields) ? "" : string(" # Default parameters\nresult = $(indicator)(ts, 20, ", join(["$field=$(default_values[field])" for field in param_fields], ", "), ") # Custom parameters")))
    ```
    """

    # Generate the complete macro expansion
    quote
        # Define calculation struct
        @doc $struct_doc
        mutable struct $(esc(struct_name)){T} <: FTailStat
            cb::CircBuff
            $(field_expressions...)

            function $(esc(struct_name)){T}($(constructor_params...)) where {T}
                new{T}(CircBuff{T}(period), $(init_expressions...))
            end
        end

        # Define internal calculation function
        function $(esc(internal_func_name))(prices::Vector, period::Int, $([:($field::$(param_types[field])) for field in param_fields]...))
            ind = $(esc(struct_name)){eltype(prices)}(period, $(param_fields...))
            return map(x -> fit!(ind, x), prices)
        end

        # Define and export public interface function
        @doc $func_doc
        function $(esc(indicator))(ts::TSFrame, period::Int; field::Symbol=:Close,
            $([Expr(:kw, Expr(:(::), field, param_types[field]), default_values[field]) for field in param_fields]...))

            prices = ts[:, field]
            results = $(esc(internal_func_name))(prices, period, $(param_fields...))
            col_name = Symbol($func_name, :_, period)
            return TSFrame(results, index(ts), colnames=[col_name])
        end

        export $(esc(indicator))
    end
end


# macro prep_SISO(indicator, fields...)
#     # Parse fields into regular and parameterized fields
#     regular_fields = Symbol[]
#     param_fields = Symbol[]
#     param_types = Dict{Symbol, Any}()
#     default_values = Dict{Symbol, Any}()

#     for field in fields
#         if field isa Symbol
#             push!(regular_fields, field)
#         elseif field.head == :call
#             field_name = field.args[1]
#             type_expr = field.args[2]

#             if type_expr.head == :(::)
#                 push!(param_fields, field_name)
#                 param_types[field_name] = type_expr.args[2]
#                 default_values[field_name] = type_expr.args[1]
#             else
#                 error("Parameterized fields must include type annotations: $field_name(value::Type)")
#             end
#         else
#             error("Invalid field specification: $field")
#         end
#     end

#     # Generate struct and function names
#     struct_name = Symbol(:i, indicator)
#     func_name = QuoteNode(indicator)
#     internal_func_name = Symbol(:_, indicator)

#     # Prepare field definitions
#     field_expressions = vcat(
#         [:($(Symbol(:_, field))::Float64) for field in regular_fields],
#         [:($(Symbol(:_, field))::$(param_types[field])) for field in param_fields]
#     )

#     # Prepare constructor initialization expressions
#     init_expressions = vcat(
#         [:(zero(Float64)) for _ in regular_fields],
#         [Symbol(field) for field in param_fields]
#     )

#     # Prepare constructor parameters
#     constructor_params = vcat(
#         [:(period::Int)],
#         [:($(field)::$(param_types[field])) for field in param_fields]
#     )

#     # # Prepare function parameters
#     # function_params = [:(ts::TSFrame), :(period::Int)]
#     # keyword_params = [
#     #     :(field::Symbol = :Close),
#     #     [:($(field)::$(param_types[field]) = $(default_values[field])) for field in param_fields]...
#     # ]

#     # internal_params = [:(prices::Vector), :(period::Int)]

#     # Add documentation for generated struct
#     struct_doc = """
#         $(struct_name){T} <: FTailStat

#     Calculation struct for the $(indicator) technical indicator.

#     # Fields
#     - `cb::CircBuff`: Circular buffer for storing input data
#     $(join(["- `_$field::Float64`: Storage for $field calculation" for field in regular_fields], "\n"))
#     $(join(["- `_$field::$(param_types[field])`: Parameter $field (default: $(default_values[field]))" for field in param_fields], "\n"))

#     # Constructor
#     ```julia
#     $(struct_name){T}(period::Int$(isempty(param_fields) ? "" : ", " * join(["$field::$(param_types[field])=$(default_values[field])" for field in param_fields], ", ")))
#     ```
#     """

#     # Add documentation for public function
#     func_doc = """
#         $(indicator)(ts::TSFrame, period::Int; field::Symbol=:Close$(isempty(param_fields) ? "" : ", " * join(["$field::$(param_types[field])=$(default_values[field])" for field in param_fields], ", ")))

#     Calculate the $(indicator) technical indicator.

#     # Arguments
#     - `ts::TSFrame`: Input time series data
#     - `period::Int`: Calculation period
#     - `field::Symbol=:Close`: Column to use for calculation
#     $(join(["- `$field::$(param_types[field])=$(default_values[field])`: $field parameter" for field in param_fields], "\n"))

#     # Returns
#     - `TSFrame`: Result of the calculation with column name `$(indicator)_period`
#     """

#     return quote
#         # Define calculation struct with documentation
#         @doc $struct_doc
#         mutable struct $(esc(struct_name)){T} <: FTailStat
#             cb::CircBuff
#             $(field_expressions...)
#             function $(esc(struct_name)){T}($(constructor_params...)) where {T}
#                 new{T}(CircBuff{T}(period), $(init_expressions...))
#             end
#         end

#         # Define internal calculation function
#         @inline function $(esc(internal_func_name))(prices::Vector, period::Int; $([:($field::$(esc(param_types[field]))) for field in param_fields]...)=$([:($default_values[field]) for field in param_fields]...))
#             ind = $(esc(struct_name)){eltype(prices)}(period, $(param_fields...))
#             return map(x -> fit!(ind, x), prices)
#         end

#         # Define and export public interface function with documentation
#         @doc $func_doc
#         function $(esc(indicator))(ts::TSFrame, period::Int; field::Symbol=:Close, $([:($field::$(esc(param_types[field]))) for field in param_fields]...)=$([:($default_values[field]) for field in param_fields]...))
#             prices = ts[:, field]
#             results = $(esc(internal_func_name))(prices, period; $([:($field=$field) for field in param_fields]...))
#             col_name = Symbol($func_name, :_, period)
#             return TSFrame(results, index(ts), colnames = [col_name])
#         end

#         export $(esc(indicator))
#     end
# end





"""
!!OBSOLETE!!
    @prep_SISO(indicator, fields...)

A macro that generates both a calculation struct and interface functions for Single Input,
Single Output (SISO) technical indicators.

# Arguments
- `indicator`: Symbol representing the indicator name (e.g., SMA, EMA, WMA)
- `fields...`: Variable number of field names for storing calculation results

# Generated Components
1. A mutable struct with type parameter T that inherits from FTailStat
    - Named with prefix 'i' (e.g., iSMA for SMA) to avoid naming conflicts
2. An internal calculation function
3. An exported interface function

# Example
    @prep_SISO SMA result
    # Generates:
    # - mutable struct iSMA{T}     # Note the 'i' prefix
    # - _SMA(prices::Vector, period::Int)
    # - SMA(ts::TSFrame, period::Int; field::Symbol=:Close)

# Naming Convention
- Struct: Prefixed with 'i' (e.g., iSMA, iEMA) to distinguish from function names
- Internal function: Prefixed with '_' (e.g., _SMA)
- Public function: Original indicator name (e.g., SMA)
"""
# macro prep_SISO(indicator, fields...)
#     # Generate names for struct and functions
#     struct_name = Symbol(:i, indicator) # Add 'i' prefix for struct name
#     func_name = QuoteNode(indicator)
#     internal_func_name = Symbol(:_, indicator)

#     # Prepare field definitions and their initializations
#     field_expressions = [:($(Symbol(:_, field))::Float64) for field in fields]
#     init_expressions = [:(zero(Float64)) for _ in fields]

#     return quote
#         # Define mutable struct for calculations
#         # Using 'i' prefix to avoid naming conflicts with function
#         mutable struct $(esc(struct_name)){T} <: FTailStat
#             cb::CircBuff  # Circular buffer for storing data
#             $(field_expressions...)  # Additional fields for calculations
#             function $(esc(struct_name)){T}(period::Int) where {T}
#                 new{T}(CircBuff{T}(period), $(init_expressions...))
#             end
#         end

#         # Define internal calculation function
#         @inline function $(esc(internal_func_name))(prices::Vector, period::Int)
#             ind = $(esc(struct_name)){eltype(prices)}(period)
#             return map(x -> fit!(ind, x), prices)
#         end

#         # Define and export public interface function
#         export $(esc(indicator))
#         function $(esc(indicator))(ts::TSFrame, period::Int; field::Symbol = :Close)
#             prices = ts[:, field]  # Extract price data
#             results = $(esc(internal_func_name))(prices, period)  # Calculate indicator
#             col_name = Symbol($func_name, :_, period)  # Generate column name (e.g., :SMA_20)
#             return TSFrame(results, index(ts), colnames = [col_name])
#         end
#     end
# end