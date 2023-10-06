using TestNoAllocations
using Test

macro test_macro_globals(expressions...)
    _fail_if_non_const_globals_in_expressions(__module__, true, expressions...)
end

const r2 = 2.0
r = 2.0

@testset "TestNoAllocations.jl" begin

    # Write your tests here.
    @testnoallocations 1 + 1
    @test (!@is_called_from_function())

    @test !(@test_macro_globals r + 3)
    @test (@test_macro_globals r2 + 3)

    function inside_func()
        @test (@is_called_from_function())

        @test !(@test_macro_globals r + 3)
        @test (@test_macro_globals r2 + 3)

    end

    inside_func()
end
