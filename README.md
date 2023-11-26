# TestNoAllocations

[![Build Status](https://github.com/bloodworkxgaming/TestNoAllocations.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/bloodworkxgaming/TestNoAllocations.jl/actions/workflows/CI.yml?query=branch%3Amaster)

This Package adds simple Macro `@testnoallocations` which makes sure, that a tested implementation of a function is allocation free.
All credit goes to Daniel Pinyol for the post at [https://forem.julialang.org/dpinol/detecting-test-allocated-gotchas-34op](https://forem.julialang.org/dpinol/detecting-test-allocated-gotchas-34op). Read the post for background information.
To know where the allocations occur use `@warn_alloc`.

## Usage
The package provides two macros:
 - `@testnoallocations`
 - `@warn_alloc`

Use `@testnoallocations` in unittest, to fail incase of allocations.  
Use `@warn_alloc` to find the location of these allocations occurring.

### Allocation Tests: `@testnoallocations`
To use the macro `@testnoallocations`, include it and add it in front of a function call inside a `@testset`.
The package `using Test` has to be included as well.

```julia
using TestNoAllocations
using Test


function test_no_allocs()
    @testset "testallocs" begin
        @testnoallocations 1 + 1 # passes
        @testnoallocations BigInt(1) + 1 # fails
        # Expression: allocs === 0
        # Evaluated: 96 === 0
    end
end


test_no_allocs()

# Result
# Test Summary: | Pass  Fail  Total  Time
# testallocs    |    1     1      2  0.4s
```

#### Important Notes:
- Always call the tests in a function. Calling from the Main-Namespace often causes additional allocations.
- Don't use global variables, as these cause additional Allocations. 
  - If it can't be avoided, specify the type exactly
  - alternatively use `const`

### Finding Allocations: `@warn_alloc`
To use the macro `@warn_alloc`, include it and add it in front of a function call.

```julia
using TestNoAllocations

function allocating(i)
    "test"^i
end

@warn_alloc 1 + 1
# no allocations, nothing will be printed

@warn_alloc BigInt(1) + 1
# ┌ Warning: Detected 3 alocations (96 bytes) in +(...)
# │ ┌ Allocated Profile.Allocs.UnknownType (32 bytes) [1x]
# │ ├─ BigInt @ .\gmp.jl:323
# │ ├── BigInt @ .\gmp.jl:301
# │ ├─── set_si @ .\gmp.jl:212
# │ ├──── BigInt @ .\gmp.jl:63
# │ └───── _#1 @ .\gmp.jl:64
# │ ┌ Allocated Profile.Allocs.UnknownType (32 bytes) [1x]
# │ ├─ + @ .\int.jl:1040
# │ ├── rem @ .\gmp.jl:353
# │ ├─── BigInt @ .\gmp.jl:323
# │ ├──── BigInt @ .\gmp.jl:301
# │ └───── set_si @ .\gmp.jl:212
# │ ┌ Allocated Profile.Allocs.UnknownType (32 bytes) [1x]
# │ ├─ + @ .\int.jl:1042
# │ ├── + @ .\gmp.jl:490
# │ ├─── add @ .\gmp.jl:166
# │ ├──── BigInt @ .\gmp.jl:63
# │ └───── _#1 @ .\gmp.jl:64
# └ @ TestNoAllocations ***\TestNoAllocations.jl\src\alloc_profile.jl:66


@warn_alloc allocating(2)
# ┌ Warning: Detected 1 alocations (8 bytes) in allocating(...)
# │ ┌ Allocated String (8 bytes) [1x]
# │ ├─ allocating @ ***\TestNoAllocations.jl\examples\src\Example.jl:5
# │ ├── ^ @ .\strings\basic.jl:733
# │ ├─── repeat @ .\strings\substring.jl:256
# │ ├──── _string_n @ .\strings\string.jl:90
# │ └───── ijl_alloc_string @ C:/workdir/src\array.c:488
# └ @ TestNoAllocations ***\TestNoAllocations.jl\src\alloc_profile.jl:66
```