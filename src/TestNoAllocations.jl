module TestNoAllocations
using Profile

include("allocation_macros.jl")
include("alloc_profile.jl")
end
