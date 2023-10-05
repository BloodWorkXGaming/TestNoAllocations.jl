using TestNoAllocations
using Test

@testset "TestNoAllocations.jl" begin
    # Write your tests here.
    @testnoallocations 1
    @test_throws "Test Failed" (@testnoallocations [1, 2, 3])
end
