using Test
using TestNoAllocations

function allocating(i)
    "test"^i
end

@warn_alloc 1 + 1
@warn_alloc BigInt(1) + 1
@warn_alloc allocating(2)


function test_no_allocs()
    @testset "testallocs" begin
        @testnoallocations 1 + 1
        @testnoallocations BigInt(1) + 1

    end
end

test_no_allocs()