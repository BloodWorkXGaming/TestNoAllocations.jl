module TestNoAllocations
using Profile


WARN_ALLOC_STACK_DEPTH::Int = 4

include("allocation_macros.jl")
include("alloc_profile.jl")
end
