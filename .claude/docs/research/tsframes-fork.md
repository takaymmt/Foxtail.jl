# TSFrames Fork Analysis: Switching to takaymmt/TSFrames.jl

**Date**: 2026-04-01
**Fork**: https://github.com/takaymmt/TSFrames.jl (main branch)
**Original**: https://github.com/xKDR/TSFrames.jl (main branch)

## 1. Fork Analysis

### UUID Comparison

| Property | Original (xKDR) | Fork (takaymmt) |
|----------|-----------------|------------------|
| UUID | `9f90e835-9451-4aaa-bcb1-743a1b8d2f84` | `9f90e835-9451-4aaa-bcb1-743a1b8d2f84` |
| Name | TSFrames | TSFrames |
| Version | 0.2.2 | 0.2.2 |

**UUIDs are identical.** This is expected for a fork and means Julia's package
manager will treat them as the same package. No changes to Foxtail.jl's
`[deps]` UUID are needed.

### Dependency Comparison

Both have the same dependencies:
- DataFrames, Dates, Random, RecipesBase, RollingFunctions,
  ShiftedArrays, Statistics, StatsBase, Tables, Artifacts

**No dependencies added or removed in the fork.**

### Compat Changes (Key Difference)

| Dependency | Original (xKDR) | Fork (takaymmt) |
|------------|-----------------|------------------|
| DataFrames | 1.3.2 | **1.8** |
| RecipesBase | 1.2.1 | **1.3** |
| RollingFunctions | 0.6.2, 0.7 | **0.8** |
| ShiftedArrays | 1.0.0, 2 | **2** |
| StatsBase | 0.33, 0.34 | **0.34** |
| Tables | 1 | 1 |
| Julia | 1.6-1.10 | **1.12** |

**The fork drops support for older versions and targets Julia 1.12+**, which
aligns with Foxtail.jl's current environment (Julia 1.12.5).

### API / Exports

The fork exports **54 symbols** including:
- Core type: `TSFrame`, `DataFrame`, `Date`
- Join types: `JoinBoth`, `JoinAll`, `JoinInner`, `JoinOuter`, `JoinLeft`, `JoinRight`
- Functions: `apply`, `cbind`, `describe`, `diff`, `endpoints`, `head`, `index`,
  `join`, `lag`, `lead`, `names`, `pctchange`, `plot`, `rbind`, `rollapply`,
  `subset`, `tail`, `vcat`, etc.
- Time conversion: `to_period`, `to_yearly`, `to_quarterly`, `to_monthly`,
  `to_weekly`, `to_daily`, `to_hourly`, `to_minutes`, `to_seconds`,
  `to_milliseconds`, `to_microseconds`, `to_nanoseconds`

The fork includes 19 source files (vs the original's similar structure).
The commit message mentions "bug fixes, algorithm improvements using binary
search instead of linear scans, and code deduplication."

### Latest Commit

- **SHA**: `de5b489943841f501792a3e07af8e861811bd57d`
- **Date**: 2026-04-01T08:51:49Z
- **Status**: All 1,727 tests pass

## 2. Julia Git Dependency Mechanism

### Method 1: `[sources]` section in Project.toml (Recommended)

Available in Julia 1.11+. Add a `[sources]` section to Project.toml:

```toml
[sources]
TSFrames = {url = "https://github.com/takaymmt/TSFrames.jl", rev = "main"}
```

This tells Julia's package manager to resolve TSFrames from the fork URL
instead of the General registry. The `[deps]` and `[compat]` sections remain
unchanged.

**Pros:**
- Declarative, version-controlled in Project.toml
- Reproducible (anyone cloning gets the fork automatically)
- Works with `Pkg.instantiate()`

**Cons:**
- `[sources]` is only active when this environment is the active project
  (not when Foxtail.jl is used as a dependency of another package)

### Method 2: `Pkg.add(url=...)` from REPL

```julia
using Pkg
Pkg.add(url="https://github.com/takaymmt/TSFrames.jl", rev="main")
```

This updates Manifest.toml with:
```toml
[[deps.TSFrames]]
deps = [...]
repo-rev = "main"
repo-url = "https://github.com/takaymmt/TSFrames.jl.git"
git-tree-sha1 = "..."
uuid = "9f90e835-9451-4aaa-bcb1-743a1b8d2f84"
version = "0.2.2"
```

**Pros:**
- Simple one-command switch
- Manifest captures exact commit hash for reproducibility

**Cons:**
- Intent not visible in Project.toml (only in Manifest.toml)
- Less declarative

### Method 3: `Pkg.develop(url=...)` for active development

```julia
Pkg.develop(url="https://github.com/takaymmt/TSFrames.jl")
```

Clones to `~/.julia/dev/TSFrames/`. Tracks local filesystem path.

**Pros:**
- Best for active development (instant local changes)

**Cons:**
- Not reproducible (path-based, tied to local machine)
- Not suitable for CI or sharing

### UUID Implications

Since the fork retains the **same UUID** as the original, Julia treats them
as the same package. This means:
- No changes to `[deps]` section needed
- The `[compat]` version constraint (`"0.2.2"`) will match (fork is also 0.2.2)
- All `using TSFrames` and `TSFrame` type references continue to work

## 3. Compatibility Assessment

### Is code change needed?

**No.** Reasoning:

1. **Same UUID**: Julia sees the fork as the same package.
2. **Same version**: Both are 0.2.2, satisfying Foxtail.jl's compat constraint.
3. **Same API surface**: The fork's exports are a superset of what Foxtail.jl uses
   (TSFrame type, index(), column access, constructor).
4. **Same dependencies**: No new deps that could cause conflicts.
5. **Forward-compatible compat**: The fork targets newer package versions that
   Foxtail.jl's Julia 1.12.5 environment already has.

### What needs to change

Only **Project.toml** (and consequently Manifest.toml will be regenerated):

```toml
# Add this section to Project.toml:
[sources]
TSFrames = {url = "https://github.com/takaymmt/TSFrames.jl", rev = "main"}
```

Or run from Julia REPL:
```julia
] add https://github.com/takaymmt/TSFrames.jl#main
```

### Risk Assessment

- **Low risk**: API is backward-compatible, same UUID, same version
- **Benefit**: Updated compat bounds enable latest DataFrames 1.8, Julia 1.12
- **Benefit**: Bug fixes and performance improvements (binary search)
- **Verify**: Run `] test Foxtail` after switching to confirm all tests pass

## 4. Recommended Approach

**Use `[sources]` in Project.toml** (Method 1) for the cleanest solution:

1. Add `[sources]` section to `/Users/taka/proj/Foxtail.jl/Project.toml`
2. Update `[compat]` julia version from `"1.11"` to `"1.12"` to match the fork
3. Run `] resolve` or `] instantiate` to update Manifest.toml
4. Run `] test` to verify

## References

- [Pkg.jl: Project.toml and Manifest.toml](https://pkgdocs.julialang.org/v1/toml-files/)
- [Pkg.jl: Managing Packages](https://julialang.github.io/Pkg.jl/v1/managing-packages/)
- [Julia Pkg.jl source code - toml-files.md](https://github.com/JuliaLang/Pkg.jl/blob/master/docs/src/toml-files.md)
- [Pkg.jl [sources] Issue #4086](https://github.com/JuliaLang/Pkg.jl/issues/4086)
