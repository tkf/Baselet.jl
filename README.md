# Baselet: `Base` API optimized for tuples

[![GitHub Actions](https://github.com/tkf/Baselet.jl/workflows/Run%20tests/badge.svg)](https://github.com/tkf/Baselet.jl/actions?query=workflow%3A%22Run+tests%22)
[![Aqua QA](https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg)](https://github.com/tkf/Aqua.jl)

## API

* `Baselet.$f` provides a possibly-optimized version of `$f` exported
  from `Base` (e.g., `Baselet.sort(::Tuple)`).

* `Baselet.Specialized.$f` provides a function `$f` with a subset of
  API from `Base.$f` that is _guaranteed_ to have optimized
  specializations (e.g., `Baselet.Specialized.sort(::Tuple)`).

* `Baselet.$f` fallbacks to `Base.$f` if associated
  `Baselet.Specialized.$f` is not found.  For example,
  `Baselet.sort(::Vector)` just calls `Base.sort(::Vector)`.

The list of supported functions can be found by typing
`Baselet.Specialized.` + <kbd>TAB</kbd> in the REPL:

```julia
julia> using Baselet

julia> Baselet.Specialized.
accumulate   cumprod      findall      flatten      isdisjoint   sort
all          cumsum       findfirst    foreach      issubset     symdiff
any          enumerate    findlast     getindex     maximum      union
argmax       extrema      findmax      in           minimum      unique
argmin       filter       findmin      intersect    setdiff      zip
```
