# Baselet: `Base` API optimized for tuples

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
accumulate argmin     findfirst  flatten    intersect  minimum    union
all        extrema    findlast   foreach    isdisjoint setdiff    unique
any        filter     findmax    getindex   issubset   sort       zip
argmax     findall    findmin    in         maximum    symdiff
```
