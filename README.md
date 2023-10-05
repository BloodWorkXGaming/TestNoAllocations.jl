# TestNoAllocations

[![Build Status](https://github.com/bloodworkxgaming/TestNoAllocations.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/bloodworkxgaming/TestNoAllocations.jl/actions/workflows/CI.yml?query=branch%3Amaster)

This Package adds simple Macro `@testnoallocations` which makes sure, that a tested implementation of a function is allocation free.
All credit goes to Daniel Pinyol for the post at [https://forem.julialang.org/dpinol/detecting-test-allocated-gotchas-34op](https://forem.julialang.org/dpinol/detecting-test-allocated-gotchas-34op). Read the post for background information.


## Usage
To use the macro, include it and add it in front of a function call.
