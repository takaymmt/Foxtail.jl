# TSFrames.jl Fork Migration Plan

> Date: 2026-04-01
> Status: Design Complete

## 1. Current State

### Dependencies
- **TSFrames v0.2.2** from Julia General registry
- UUID: `9f90e835-9451-4aaa-bcb1-743a1b8d2f84`
- Manifest pinned to git-tree-sha1 `4db6e77d1e4b85699846080491bc162b4f6df328`

### Source Files Using TSFrames (runtime)
| File | Usage | Notes |
|------|-------|-------|
| `src/Foxtail.jl:3` | `using TSFrames, LinearAlgebra` | Module-level import; provides `TSFrame`, `index()` to all indicators |
| `src/macro.jl` | `TSFrame` constructor, `index()` | Used in macro-generated wrapper functions (all 4 macros) |
| `test/runtests.jl:2` | `using Test, CSV, TSFrames` | Test-level import |
| `src/indicators/JMA.jl:92` | `using TSFrames` | **Inside docstring only** -- not executable |

### TSFrames API Surface Used
- `TSFrame(data, index; colnames=[...])` -- constructor
- `ts[:, field]` -- column access (single)
- `ts[:, fields] |> Matrix` -- multi-column access
- `index(ts)` -- get time index

### Fork Details
- URL: `https://github.com/takaymmt/TSFrames.jl`
- Branch: `main`
- **Same UUID** as upstream: `9f90e835-9451-4aaa-bcb1-743a1b8d2f84`
- **Same version**: `0.2.2`
- **Julia compat**: `1.12` (upstream was `1.9`)
- Dependencies identical to upstream

## 2. Approach Decision

### Recommendation: Approach A -- `Pkg.add(url=..., rev="main")`

| Criterion | A: `Pkg.add(url=...)` | B: `Pkg.develop(url=...)` |
|-----------|----------------------|--------------------------|
| Reproducibility | Pins to specific commit SHA in Manifest.toml | Tracks local clone, not pinned |
| CI/CD friendliness | Works everywhere via Manifest.toml | Requires extra setup |
| Collaboration | Others can `instantiate` cleanly | Others need the same local path |
| Fork updates | Explicit `Pkg.update("TSFrames")` to pull new commits | Auto-tracks HEAD (may break) |
| Active development | Need `Pkg.update` to get changes | Immediate -- great for co-development |

**Justification**: Foxtail.jl is a library, not a monorepo where TSFrames is actively co-developed. `Pkg.add(url=...)` gives:
- Deterministic builds via Manifest.toml commit pinning
- Clean CI without local path dependencies
- Explicit update control

If the user later needs to actively develop TSFrames alongside Foxtail, they can switch to `Pkg.develop` locally without affecting the committed Project.toml.

## 3. Implementation Plan

### Step 1: Remove compat entry for TSFrames

The `[compat]` section currently has `TSFrames = "0.2.2"`. When using a git URL source, Julia's Pkg manager still checks compat. Since the fork is version `0.2.2` (same as upstream), the compat entry **can remain as-is**. However, if the fork's version ever changes (e.g., `0.3.0`), the compat must be updated.

**Decision**: Keep `TSFrames = "0.2.2"` in compat for now. It matches the fork's declared version.

### Step 2: Switch the package source

Run in Julia REPL from the project directory:

```julia
using Pkg
Pkg.activate(".")
Pkg.rm("TSFrames")
Pkg.add(url="https://github.com/takaymmt/TSFrames.jl", rev="main")
```

This will:
1. Remove the registry-based TSFrames entry from Project.toml and Manifest.toml
2. Re-add TSFrames from the git fork
3. Pin Manifest.toml to a specific commit SHA on `main`

**Important**: `Pkg.add(url=...)` with same UUID replaces the source cleanly. The `[deps]` section UUID stays the same. No source code changes needed.

### Step 3: Verify Project.toml changes

After running the commands, Project.toml should look like:

```toml
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
TSFrames = "9f90e835-9451-4aaa-bcb1-743a1b8d2f84"

[compat]
CSV = "0.10.15"
LinearAlgebra = "1.11.0"
TSFrames = "0.2.2"
julia = "1.11"
```

UUID stays the same. Compat stays the same. No changes to `[deps]`.

Manifest.toml `[[deps.TSFrames]]` section should change to include `repo-url` and `repo-rev` fields:

```toml
[[deps.TSFrames]]
deps = [...]
git-tree-sha1 = "<new-commit-sha>"
repo-rev = "main"
repo-url = "https://github.com/takaymmt/TSFrames.jl"
uuid = "9f90e835-9451-4aaa-bcb1-743a1b8d2f84"
version = "0.2.2"
```

### Step 4: Verify the switch worked

```julia
# 1. Check package status
Pkg.status("TSFrames")
# Should show: TSFrames v0.2.2 `https://github.com/takaymmt/TSFrames.jl#main`

# 2. Precompile
Pkg.precompile()

# 3. Load the module
using Foxtail

# 4. Run tests
Pkg.test("Foxtail")
```

### Step 5: Commit changes

Only two files change:
- `Manifest.toml` -- updated TSFrames source
- `Project.toml` -- **may** not change at all (UUID is same, compat is same)

## 4. Source Code Changes Required

**None.** Zero source code changes needed because:
- The fork has the same UUID (`9f90e835-...`)
- The fork has the same version (`0.2.2`)
- The fork exports the same API surface
- All `using TSFrames` statements resolve the same UUID

## 5. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Fork diverges from upstream breaking API | Low (owner controls fork) | High | Pin to specific commit; test before updating |
| Fork's julia compat (`1.12`) conflicts with Foxtail's (`1.11`) | Medium | Medium | If Foxtail needs Julia 1.11, fork's compat may need adjustment |
| Collaborators can't resolve fork URL | Low | Medium | Manifest.toml includes full URL; `Pkg.instantiate()` handles it |
| Fork version stays `0.2.2` but adds breaking changes | Low | High | Semantic versioning discipline; test suite catches regressions |

### Julia Compat Note
The fork declares `julia = "1.12"` while Foxtail declares `julia = "1.11"`. This **may** cause a resolver conflict if anyone tries to use Foxtail on Julia 1.11. If Julia 1.11 support is needed, the fork's `Project.toml` should be updated to `julia = "1.11"` or lower.

## 6. Rollback Strategy

To revert to upstream registry version:

```julia
using Pkg
Pkg.activate(".")
Pkg.rm("TSFrames")
Pkg.add("TSFrames")
```

Or simply:
```bash
git checkout -- Project.toml Manifest.toml
```

## 7. Future Considerations

- **Version bumping**: When the fork adds features beyond upstream `0.2.2`, bump the version (e.g., `0.3.0-dev`) and update Foxtail's compat accordingly
- **Switching to `Pkg.develop`**: If active co-development is needed, run `Pkg.develop(url="https://github.com/takaymmt/TSFrames.jl")` locally -- this does not need to be committed
- **Pinning to a tag**: Instead of `rev="main"`, consider creating releases/tags on the fork and pinning to those for even more stability
