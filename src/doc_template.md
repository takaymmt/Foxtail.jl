# Templates to create documents by AI

## 1. Indicators

Write the general documentation in English for this indicators (not the function) according to the following template.

Follow the documentation guidline of julia.
[Documentation Guideline](https://docs.julialang.org/en/v1/manual/documentation/)

````
"""
    Indicator Name

One sentence description of what this indicator measures or represents.

## Basic Concept
- Brief explanation of how the indicator works
- Core principles behind the calculation
- Any unique characteristics or features
- Historical context if relevant

## Interpretation / Trading Signals
- What the indicator values typically indicate
- Common signal patterns and their meanings
- How to interpret different values or crossovers
- Any notable limitations or market conditions where the indicator performs best/worst

## Core Formula
[Show the mathematical formula using LaTeX or clear mathematical notation]

```math
Formula
```

Key components:
- Definition of each variable
- Explanation of any special calculations
- Step-by-step breakdown if the formula is complex

## Parameters
Each parameter should include:
- Description of what it controls
- Common values and their use cases
- Impact on the indicator's behavior
- Recommended ranges
- Trade-offs when adjusting values

Example format:
- `period`: (Default: 14)
  - Controls the lookback period
  - Shorter periods (5-10): More sensitive, good for short-term trading
  - Longer periods (20-30): Smoother, better for trend following
  - Impact: Larger values reduce noise but increase lag

## References
- Original publication or creator
- Related indicators
- Recommended reading
- Dependencies on other indicators
"""
````

## 2. Functions

Write the doc of this function in English according to the following template.

Follow the documentation guidline of julia.
[Documentation Guideline](https://docs.julialang.org/en/v1/manual/documentation/)

````
"""
    function_name(arg1::Type1, arg2::Type2, ...) -> ReturnType

One sentence description of what the function does and its primary purpose.

## Examples
```julia
# Basic usage
result = function_name(input1, input2)

# Edge cases
result = function_name(special_input)  # Show behavior with special values
```

## Arguments
- `arg1::Type1`: Description of first argument
  - Valid range/constraints if any
  - Default value if applicable
  - Special values handling

- `arg2::Type2`: Description of second argument
  ...

## Returns
- `ReturnType`: Description of return value
  - Format and structure of output
  - Special values (NaN, missing, etc.) and when they occur
  - Vector/Matrix dimensions if applicable

## Implementation Details
Algorithm overview:
- Key steps in the calculation process
- Any optimizations or special techniques used
- Important implementation notes

Performance characteristics:
- Time complexity: O(n)
- Space complexity: O(1)
- Any performance considerations or trade-offs

## Related Components
Dependencies:
- Required functions or indicators
- Optional dependencies
- Version requirements if any

Used by:
- List of indicators or functions that use this function
- Common combinations with other functions

Notes:
- Any limitations or constraints
- Numerical stability considerations
- Threading safety information if relevant
"""
````

## United template for indicator and its function

-   Write the general documentation in English for this indicators, and its function (which receive the TSFrame argument) according to the following template.
-   Follow the documentation guidline of julia.
    -   [Documentation Guideline](https://docs.julialang.org/en/v1/manual/documentation/)

````
"""
    Indicator name
    function_name(arg1::Type1, arg2::Type2, ...) -> ReturnType

One sentence description of what this indicator measures or represents.

## Basic Concept
- Brief explanation of how the indicator works
- Core principles behind the calculation
- Any unique characteristics or features
- Historical context if relevant

## Interpretation / Trading Signals
- What the indicator values typically indicate
- Common signal patterns and their meanings
- How to interpret different values or crossovers
- Any notable limitations or market conditions where the indicator performs best/worst

## Usage Examples
```julia
# Basic usage
result = indicator_name(input1, input2)

# Edge cases
result = indicator_name(special_input)  # Show behavior with special values
```

## Core Formula
[Show the mathematical formula using LaTeX or clear mathematical notation]

```math
Formula
```

Key components:
- Definition of each variable
- Explanation of any special calculations
- Step-by-step breakdown if the formula is complex

## Parameters and Arguments
Each parameter should include:
- Description and purpose
- Type specification and constraints
- Default values if applicable
- Common values and their use cases
- Impact on the indicator's behavior
- Recommended ranges
- Special values handling

Example format:
- `period::Int`: (Default: 14)
  - Controls the lookback period
  - Valid range: > 0
  - Shorter periods (5-10): More sensitive, good for short-term trading
  - Longer periods (20-30): Smoother, better for trend following
  - Impact: Larger values reduce noise but increase lag

## Returns
- `ReturnType`: Description of return value
  - Format and structure of output
  - Special values (NaN, missing, etc.) and when they occur
  - Vector/Matrix dimensions if applicable

## Implementation Details
Algorithm overview:
- Key steps in the calculation process
- Any optimizations or special techniques used
- Important implementation notes

Performance characteristics:
- Time complexity: O(n)
- Space complexity: O(1)
- Any performance considerations or trade-offs
"""
````
